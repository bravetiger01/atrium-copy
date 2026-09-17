// functions/otpEmail.js
// OTP email delivery for the login flow.
//
// The callable handler is built through a factory so it can be unit-tested
// with fake Firestore and fake mail transport — no real network or SMTP needed.
// index.js wires it up with the real Firestore and a nodemailer-backed sender.

const { HttpsError } = require("firebase-functions/v2/https");
const nodemailer = require("nodemailer");

const OTP_COLLECTION = "otp_codes";
const OTP_TTL_MINUTES = 15;

// Creates the callable handler for `sendOtpEmail`.
//
// deps.db       — Firestore-like instance exposing collection().doc().get()/delete()
// deps.sendMail — async ({ to, subject, text, html }) => Promise
function createSendOtpEmailHandler({ db, sendMail }) {
  return async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to request a verification code.",
      );
    }

    const requestedEmail = request.data && request.data.email;
    const ref = db.collection(OTP_COLLECTION).doc(uid);
    const snap = await ref.get();

    if (!snap.exists) {
      throw new HttpsError(
        "not-found",
        "No verification code found. Please sign in again.",
      );
    }

    const data = snap.data();
    const code = data && data.code;
    const storedEmail = (data && data.email) || requestedEmail;

    if (!code) {
      throw new HttpsError(
        "failed-precondition",
        "Verification code is missing. Please sign in again.",
      );
    }

    if (
      requestedEmail &&
      storedEmail &&
      String(requestedEmail).toLowerCase() !== String(storedEmail).toLowerCase()
    ) {
      throw new HttpsError(
        "permission-denied",
        "Email does not match the signed-in account.",
      );
    }

    if (data.expiresAt) {
      const expiresAt =
        typeof data.expiresAt.toDate === "function"
          ? data.expiresAt.toDate()
          : new Date(data.expiresAt);
      if (expiresAt.getTime() < Date.now()) {
        await ref.delete();
        throw new HttpsError(
          "failed-precondition",
          "Verification code expired. Please sign in again.",
        );
      }
    }

    try {
      await sendMail({
        to: storedEmail,
        subject: "Your SwipeHire verification code",
        text:
          `Your SwipeHire verification code is ${code}.\n\n` +
          `It expires in ${OTP_TTL_MINUTES} minutes. ` +
          `If you didn't request this, you can ignore this email.`,
        html:
          `<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">` +
          `<h2 style="color:#1F2937;margin-bottom:8px;">SwipeHire verification code</h2>` +
          `<p style="color:#374151;font-size:15px;">Your one-time verification code is:</p>` +
          `<div style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#111827;` +
          `background:#F3F4F6;border-radius:8px;padding:16px;text-align:center;">${code}</div>` +
          `<p style="color:#6B7280;font-size:13px;margin-top:16px;">` +
          `This code expires in ${OTP_TTL_MINUTES} minutes. ` +
          `If you didn't request it, you can safely ignore this email.</p>` +
          `</div>`,
      });
    } catch (error) {
      console.error("sendOtpEmail: failed to send email:", error);
      throw new HttpsError(
        "internal",
        "We couldn't send your code. Please try again.",
      );
    }

    return { success: true };
  };
}

// Module-level transport — created once and reused across warm invocations.
// This avoids a full TCP + TLS + SMTP-AUTH round-trip on every OTP send.
let _sharedTransport = null;

function getTransport() {
  if (_sharedTransport) return _sharedTransport;

  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  if (!user || !pass) {
    throw new Error(
      "SMTP_USER and SMTP_PASS environment variables are not configured.",
    );
  }

  _sharedTransport = nodemailer.createTransport({
    host: process.env.SMTP_HOST || "smtp.gmail.com",
    port: parseInt(process.env.SMTP_PORT || "465", 10),
    secure: process.env.SMTP_SECURE !== "false",
    pool: true,          // keep connections alive between sends
    maxConnections: 3,   // up to 3 parallel SMTP connections
    auth: { user, pass },
  });

  return _sharedTransport;
}

// Creates a nodemailer-backed sender configured from SMTP_* environment
// variables. Pass `transporter` to inject a fake transport in tests.
function createEmailSender({ transporter } = {}) {
  return async ({ to, subject, text, html }) => {
    const transport = transporter || getTransport();

    const fromUser = process.env.SMTP_USER || "noreply@swipehire.app";
    await transport.sendMail({
      from: `"SwipeHire" <${fromUser}>`,
      to,
      subject,
      text,
      html,
    });
  };
}

module.exports = { createSendOtpEmailHandler, createEmailSender };
