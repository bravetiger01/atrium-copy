// functions/test/otpEmail.test.js
// Unit tests for the OTP email callable handler and SMTP sender.

const { test, beforeEach, afterEach } = require("node:test");
const assert = require("node:assert/strict");

// Mock Firebase config so requiring firebase-functions doesn't warn.
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "swipehire-flutter" });

const {
  createSendOtpEmailHandler,
  createEmailSender,
} = require("../otpEmail");

const FUTURE = () => new Date(Date.now() + 60 * 1000);
const PAST = () => new Date(Date.now() - 60 * 1000);

function makeDb(otpDoc) {
  const snap = { exists: !!otpDoc, data: () => otpDoc };
  return {
    collection: () => ({
      doc: () => ({
        get: async () => snap,
        delete: async () => {},
      }),
    }),
  };
}

function call(handler, { data, uid }) {
  return handler({ data: data || {}, auth: uid ? { uid } : null });
}

const origEnv = {};
beforeEach(() => {
  for (const key of ["SMTP_USER", "SMTP_PASS", "SMTP_HOST", "SMTP_PORT", "SMTP_SECURE"]) {
    origEnv[key] = process.env[key];
    delete process.env[key];
  }
});
afterEach(() => {
  for (const key of Object.keys(origEnv)) {
    if (origEnv[key] === undefined) delete process.env[key];
    else process.env[key] = origEnv[key];
  }
});

test("rejects unauthenticated calls", async () => {
  const handler = createSendOtpEmailHandler({ db: makeDb(null), sendMail: async () => {} });
  await assert.rejects(
    () => call(handler, { data: {}, uid: null }),
    (err) => {
      assert.equal(err.code, "unauthenticated");
      return true;
    },
  );
});

test("throws not-found when no OTP is stored", async () => {
  const handler = createSendOtpEmailHandler({ db: makeDb(null), sendMail: async () => {} });
  await assert.rejects(
    () => call(handler, { data: { email: "a@b.com" }, uid: "u1" }),
    (err) => {
      assert.equal(err.code, "not-found");
      return true;
    },
  );
});

test("throws failed-precondition when code is missing", async () => {
  const handler = createSendOtpEmailHandler({
    db: makeDb({ email: "a@b.com", expiresAt: FUTURE() }),
    sendMail: async () => {},
  });
  await assert.rejects(
    () => call(handler, { data: { email: "a@b.com" }, uid: "u1" }),
    (err) => {
      assert.equal(err.code, "failed-precondition");
      return true;
    },
  );
});

test("sends the stored code to the stored email", async () => {
  const sent = [];
  const handler = createSendOtpEmailHandler({
    db: makeDb({ code: "1234", email: "a@b.com", expiresAt: FUTURE() }),
    sendMail: async (mail) => sent.push(mail),
  });

  const result = await call(handler, { data: { email: "a@b.com" }, uid: "u1" });

  assert.deepEqual(result, { success: true });
  assert.equal(sent.length, 1);
  assert.equal(sent[0].to, "a@b.com");
  assert.equal(sent[0].subject, "Your SwipeHire verification code");
  assert.match(sent[0].text, /1234/);
  assert.match(sent[0].html, /1234/);
});

test("rejects when requested email does not match stored email", async () => {
  const handler = createSendOtpEmailHandler({
    db: makeDb({ code: "1234", email: "a@b.com", expiresAt: FUTURE() }),
    sendMail: async () => {},
  });
  await assert.rejects(
    () => call(handler, { data: { email: "c@d.com" }, uid: "u1" }),
    (err) => {
      assert.equal(err.code, "permission-denied");
      return true;
    },
  );
});

test("deletes expired codes and throws failed-precondition", async () => {
  let deleted = false;
  const db = {
    collection: () => ({
      doc: () => ({
        get: async () => ({
          exists: true,
          data: () => ({ code: "1234", email: "a@b.com", expiresAt: PAST() }),
        }),
        delete: async () => {
          deleted = true;
        },
      }),
    }),
  };
  const handler = createSendOtpEmailHandler({ db, sendMail: async () => {} });

  await assert.rejects(
    () => call(handler, { data: { email: "a@b.com" }, uid: "u1" }),
    (err) => {
      assert.equal(err.code, "failed-precondition");
      return true;
    },
  );
  assert.equal(deleted, true);
});

test("surfaces SMTP failures as internal errors", async () => {
  const handler = createSendOtpEmailHandler({
    db: makeDb({ code: "1234", email: "a@b.com", expiresAt: FUTURE() }),
    sendMail: async () => {
      throw new Error("smtp boom");
    },
  });
  await assert.rejects(
    () => call(handler, { data: { email: "a@b.com" }, uid: "u1" }),
    (err) => {
      assert.equal(err.code, "internal");
      return true;
    },
  );
});

test("createEmailSender builds a proper mail and uses SMTP env", async () => {
  process.env.SMTP_USER = "me@gmail.com";
  process.env.SMTP_PASS = "secret";
  const sent = [];
  const sender = createEmailSender({
    transporter: { sendMail: async (mail) => sent.push(mail) },
  });

  await sender({ to: "a@b.com", subject: "S", text: "T", html: "<b>T</b>" });

  assert.equal(sent.length, 1);
  assert.equal(sent[0].from, "\"SwipeHire\" <me@gmail.com>");
  assert.equal(sent[0].to, "a@b.com");
});

test("createEmailSender fails fast when SMTP creds are missing", async () => {
  const sender = createEmailSender();
  await assert.rejects(() =>
    sender({ to: "a@b.com", subject: "S", text: "T", html: "<b>T</b>" }),
  );
});
