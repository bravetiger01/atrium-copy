// functions/index.js
// SwipeHire Cloud Functions
//
// Triggers:
//   sendChatNotification  — fires on every new message in chats/{chatId}/messages/{messageId}
//   sendMatchNotification — fires when a new match document is created in matches/{matchId}

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const {
  createSendOtpEmailHandler,
  createEmailSender,
} = require("./otpEmail");

initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: send FCM to all tokens of a user, remove stale tokens automatically
// ─────────────────────────────────────────────────────────────────────────────
async function sendToUser(recipientId, payload) {
  const recipientDoc = await getFirestore()
    .collection("users")
    .doc(recipientId)
    .get();

  if (!recipientDoc.exists) {
    console.log(`User not found: ${recipientId}`);
    return;
  }

  const tokens = recipientDoc.data().fcmTokens;
  if (!tokens || tokens.length === 0) {
    console.log(`No FCM tokens for user: ${recipientId}`);
    return;
  }

  const sendPromises = tokens.map(async (token) => {
    try {
      await getMessaging().send({ ...payload, token });
      console.log(`Sent to token: ${token.slice(-8)}`);
    } catch (error) {
      console.error(`Failed to send to token: ${error.message}`);
      if (error.code === "messaging/registration-token-not-registered") {
        // Stale token — remove it so we don't try again
        await getFirestore()
          .collection("users")
          .doc(recipientId)
          .update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
          });
        console.log(`Removed stale token for ${recipientId}`);
      }
    }
  });

  await Promise.all(sendPromises);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: persist a notification to Firestore so the in-app bell can show it
//  Path: notifications/{userId}/items/{auto-id}
// ─────────────────────────────────────────────────────────────────────────────
async function saveNotification(userId, { title, body, type, data = {} }) {
  try {
    await getFirestore()
      .collection("notifications")
      .doc(userId)
      .collection("items")
      .add({
        title,
        body,
        type,      // "chat" | "match" | "interview"
        data,      // same data payload sent via FCM
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (e) {
    console.error(`saveNotification error for ${userId}: ${e.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  1. Chat Message Notification
//     Fires on every new message → notifies the other participant
// ─────────────────────────────────────────────────────────────────────────────
exports.sendChatNotification = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
  },
  async (event) => {
    const messageData = event.data.data();
    const chatId = event.params.chatId;
    const senderId = messageData.senderId;
    const messageText = messageData.text || "📎 Attachment";

    try {
      // Get chat doc to find the recipient
      const chatDoc = await getFirestore()
        .collection("chats")
        .doc(chatId)
        .get();
      if (!chatDoc.exists) {
        console.error(`Chat not found: ${chatId}`);
        return null;
      }
      const chatData = chatDoc.data();
      const members = chatData.members || [];
      const recipientId = members.find((id) => id !== senderId);
      if (!recipientId) {
        console.error(`No recipient in chat: ${chatId}`);
        return null;
      }

      // Get sender's display name
      const senderDoc = await getFirestore()
        .collection("users")
        .doc(senderId)
        .get();
      const senderName =
        senderDoc.data()?.displayName ||
        senderDoc.data()?.name ||
        senderDoc.data()?.email ||
        "Someone";

      const jobTitle = chatData.jobTitle || "";
      const isInterview = messageData.type === "interview";

      let notifTitle, notifBody;
      if (isInterview) {
        notifTitle = `📅 Interview Proposal · ${jobTitle || "Job"}`;
        notifBody = `${senderName} proposed an interview time slot`;
      } else {
        notifTitle = jobTitle
          ? `${senderName} · ${jobTitle}`
          : `New message from ${senderName}`;
        notifBody = messageText;
      }

      const payload = {
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        data: {
          type: "chat",
          chatId: chatId,
          otherUserId: senderId,
          otherUserName: senderName,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_channel",
            priority: "max",
            sound: "default",
          },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      };

      await sendToUser(recipientId, payload);
      await saveNotification(recipientId, {
        title: notifTitle,
        body: notifBody,
        type: isInterview ? "interview" : "chat",
        data: { chatId, otherUserId: senderId, otherUserName: senderName },
      });
      console.log(`Chat notification sent: ${chatId}`);
    } catch (error) {
      console.error(`sendChatNotification error: ${error.message}`);
    }
    return null;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
//  2. New Match Notification
//     Fires when employer accepts a candidate → notifies the candidate
// ─────────────────────────────────────────────────────────────────────────────
exports.sendMatchNotification = onDocumentCreated(
  {
    document: "matches/{matchId}",
  },
  async (event) => {
    const matchData = event.data.data();
    const candidateId = matchData.candidateId;
    const employerId = matchData.employerId;
    const jobTitle = matchData.jobTitle || "a job";

    if (!candidateId || !employerId) {
      console.error("Missing candidateId or employerId in match document");
      return null;
    }

    try {
      // Get employer name to personalise the notification
      const employerDoc = await getFirestore()
        .collection("users")
        .doc(employerId)
        .get();
      const employerName =
        employerDoc.data()?.displayName ||
        employerDoc.data()?.name ||
        employerDoc.data()?.email ||
        "An employer";

      const payload = {
        notification: {
          title: "🎉 It's a Match!",
          body: `${employerName} accepted your application for "${jobTitle}". Start chatting now!`,
        },
        data: {
          type: "match",
          matchId: event.params.matchId,
          jobTitle: jobTitle,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_channel",
            priority: "max",
            sound: "default",
          },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      };

      await sendToUser(candidateId, payload);
      await saveNotification(candidateId, {
        title: "🎉 It's a Match!",
        body: `${employerName} accepted your application for "${jobTitle}". Start chatting now!`,
        type: "match",
        data: { matchId: event.params.matchId, jobTitle },
      });
      console.log(
        `Match notification sent to candidate ${candidateId} for job "${jobTitle}"`,
      );
    } catch (error) {
      console.error(`sendMatchNotification error: ${error.message}`);
    }
    return null;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
//  3. Interview Response Notification
//     Fires when candidate accepts/declines an interview proposal
// ─────────────────────────────────────────────────────────────────────────────
exports.sendInterviewResponseNotification = onDocumentUpdated(
  {
    document: "chats/{chatId}/messages/{messageId}",
  },
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Only proceed if interviewData.status changed
    const beforeStatus = beforeData?.interviewData?.status;
    const afterStatus = afterData?.interviewData?.status;
    if (beforeData?.type !== "interview" || beforeStatus === afterStatus) {
      return null;
    }

    const chatId = event.params.chatId;
    const recipientId = afterData.senderId;

    try {
      const chatDoc = await getFirestore()
        .collection("chats")
        .doc(chatId)
        .get();
      if (!chatDoc.exists) return null;
      const chatData = chatDoc.data();
      const jobTitle = chatData?.jobTitle || "a job";

      const isAccepted = afterStatus === "accepted";
      const notifTitle = isAccepted
        ? "✅ Interview Accepted"
        : "❌ Interview Declined";
      const notifBody = isAccepted
        ? `The candidate accepted your interview proposal for "${jobTitle}".`
        : `The candidate declined the interview for "${jobTitle}".`;

      // Auto-advance match status to interview_scheduled when accepted
      if (isAccepted) {
        try {
          await getFirestore()
            .collection("matches")
            .doc(chatId) // chatId === matchId
            .update({ status: "interview_scheduled" });
        } catch (e) {
          console.error(`Failed to auto-advance match status: ${e.message}`);
        }
      }

      const payload = {
        notification: { title: notifTitle, body: notifBody },
        data: {
          type: "chat",
          chatId: chatId,
          otherUserId: "",
          otherUserName: "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_channel",
            priority: "max",
            sound: "default",
          },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      };

      await sendToUser(recipientId, payload);
      await saveNotification(recipientId, {
        title: notifTitle,
        body: notifBody,
        type: "interview",
        data: { chatId },
      });
      console.log(`Interview response notification sent: ${chatId}`);
    } catch (error) {
      console.error(
        `sendInterviewResponseNotification error: ${error.message}`,
      );
    }
    return null;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
//  4. Hiring Status Change Notification
//     Fires when employer updates match status to offer_sent or hired
// ─────────────────────────────────────────────────────────────────────────────
exports.sendStatusChangeNotification = onDocumentUpdated(
  { document: "matches/{matchId}" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const oldStatus = before?.status;
    const newStatus = after?.status;

    if (!newStatus || oldStatus === newStatus) return null;
    if (newStatus !== "offer_sent" && newStatus !== "hired") return null;

    const candidateId = after.candidateId;
    const jobTitle = after.jobTitle || "a job";
    if (!candidateId) return null;

    const msgs = {
      offer_sent: {
        title: "🎁 Offer Received!",
        body: `You've received a job offer for "${jobTitle}". Check your matches!`,
      },
      hired: {
        title: "🎉 Congratulations! You're Hired!",
        body: `The employer has confirmed you for "${jobTitle}". Best of luck!`,
      },
    };

    const { title, body } = msgs[newStatus];

    try {
      const payload = {
        notification: { title, body },
        data: {
          type: "match",
          matchId: event.params.matchId,
          jobTitle,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: { channelId: "chat_channel", priority: "max", sound: "default" },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      };

      await sendToUser(candidateId, payload);
      await saveNotification(candidateId, {
        title, body, type: "match",
        data: { matchId: event.params.matchId, jobTitle, status: newStatus },
      });
      console.log(`Status change (${newStatus}) notified to ${candidateId}`);
    } catch (error) {
      console.error(`sendStatusChangeNotification error: ${error.message}`);
    }
    return null;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
//  5. OTP Email (callable)
//     Emails the login verification code stored in otp_codes/{uid}
// ─────────────────────────────────────────────────────────────────────────────
exports.sendOtpEmail = onCall(
  { region: "asia-south1" },
  createSendOtpEmailHandler({
    db: getFirestore(),
    sendMail: createEmailSender(),
  }),
);
