/**
 * Firebase Cloud Functions for Agora Real-time STT Translation
 * Using Agora STT v7 API and Firebase Functions v2
 */

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ============================================
// AGORA CONFIGURATION
// ============================================
const AGORA_CONFIG = {
  appId: process.env.AGORA_APP_ID || "",
  customerId: process.env.AGORA_CUSTOMER_ID || "",
  customerSecret: process.env.AGORA_CUSTOMER_SECRET || "",
};

// Base64 encode credentials for Basic Auth
const getAuthHeader = () => {
  const credentials = Buffer.from(
    `${AGORA_CONFIG.customerId}:${AGORA_CONFIG.customerSecret}`,
  ).toString("base64");
  return `Basic ${credentials}`;
};

// ============================================
// START TRANSCRIPTION (Agora STT v7 API)
// ============================================
exports.startTranscription = onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;

  logger.info("v2 startTranscription called", { structuredData: true });
  logger.info("Data received:", data);
  logger.info("Auth context:", auth);

  if (!AGORA_CONFIG.appId || !AGORA_CONFIG.customerId || !AGORA_CONFIG.customerSecret) {
    throw new HttpsError(
      "failed-precondition",
      "Agora server credentials are not configured.",
    );
  }

  const { channelName, userId, sourceLanguage, targetLanguage } = data || {};

  if (!channelName || !userId) {
    const receivedKeys = data ? Object.keys(data).join(", ") : "null";
    throw new HttpsError(
      "invalid-argument",
      `channelName and userId required. Received keys: ${receivedKeys}`
    );
  }

  const agentName = `agent_${Date.now()}_${userId.substring(0, 8)}`;

  try {
    // Agora STT v7 API request body
    const requestBody = {
      name: agentName,
      languages: [sourceLanguage || "en-US"],
      maxIdleTime: 120,
      rtcConfig: {
        channelName: channelName,
        pubBotUid: "88888",
        subBotUid: "99999",
      },
      subscribeAudioUids: ["#allstream"],
    };

    // Add translation config if target language specified
    if (targetLanguage && targetLanguage !== sourceLanguage) {
      requestBody.translateConfig = {
        languages: [
          {
            source: sourceLanguage || "en-US",
            target: [targetLanguage],
          },
        ],
      };
    }

    console.log("Starting Agora STT with config:", JSON.stringify(requestBody));

    // Call Agora STT v7 API
    const response = await axios.post(
      `https://api.agora.io/api/speech-to-text/v1/projects/${AGORA_CONFIG.appId}/join`,
      requestBody,
      {
        headers: {
          "Authorization": getAuthHeader(),
          "Content-Type": "application/json",
        },
      },
    );

    console.log("Agora STT response:", JSON.stringify(response.data));

    // Store task info in Firestore
    await db.collection("transcriptionTasks").doc(agentName).set({
      channelName,
      userId,
      agentName,
      status: "running",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sourceLanguage: sourceLanguage || "en-US",
      targetLanguage: targetLanguage || "es",
    });

    return {
      success: true,
      agentName: agentName,
      response: response.data,
    };
  } catch (error) {
    console.error("Agora STT Error:", error.response?.data || error.message);
    throw new HttpsError(
      "internal",
      `Failed to start transcription: ${JSON.stringify(error.response?.data || error.message)}`,
    );
  }
});

// ============================================
// STOP TRANSCRIPTION (Agora STT v7 API)
// ============================================
exports.stopTranscription = onCall(async (request) => {
  const data = request.data;
  const agentName = data.agentName || data.taskId;
  const { channelName } = data;

  if (!agentName && !channelName) {
    throw new HttpsError("invalid-argument", "agentName (or taskId) or channelName required");
  }

  try {
    let taskName = agentName;

    // If no agentName, find it from Firestore
    if (!taskName && channelName) {
      const taskQuery = await db.collection("transcriptionTasks")
        .where("channelName", "==", channelName)
        .where("status", "==", "running")
        .limit(1)
        .get();

      if (!taskQuery.empty) {
        taskName = taskQuery.docs[0].id;
      }
    }

    if (!taskName) {
      return { success: true, message: "No active transcription found" };
    }

    // Call Agora STT v7 API to stop
    await axios.post(
      `https://api.agora.io/api/speech-to-text/v1/projects/${AGORA_CONFIG.appId}/leave`,
      { name: taskName },
      {
        headers: {
          "Authorization": getAuthHeader(),
          "Content-Type": "application/json",
        },
      },
    );

    // Update Firestore
    await db.collection("transcriptionTasks").doc(taskName).update({
      status: "stopped",
      stoppedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error("Stop error:", error.response?.data || error.message);
    return { success: false, error: error.message };
  }
});

// ============================================
// WEBHOOK HANDLER (for caption data)
// ============================================
exports.transcriptionWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  try {
    const payload = req.body;
    console.log("Webhook received:", JSON.stringify(payload));

    // Store in Firestore for Flutter to listen
    if (payload.channelName && (payload.text || payload.translatedText)) {
      await db.collection("transcriptions").add({
        channelName: payload.channelName,
        originalText: payload.text || "",
        translatedText: payload.translatedText || "",
        isFinal: payload.isFinal || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.status(200).send({ success: true });
  } catch (error) {
    console.error("Webhook error:", error);
    res.status(500).send({ error: error.message });
  }
});

// ============================================
// NOTIFICATION FUNCTIONS (v2 syntax)
// ============================================

/**
 * Send notification when a new session request is created
 */
exports.onSessionRequestCreated = onDocumentCreated(
  "scheduled_sessions/{sessionId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;
    
    const session = snapshot.data();
    
    if (session.status !== "pending") {
      return null;
    }

    const participantId = session.participantId;
    if (!participantId) {
      console.log("No participantId found");
      return null;
    }

    try {
      const userDoc = await db.collection("users").doc(participantId).get();
      if (!userDoc.exists) {
        console.log("User not found:", participantId);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log("No FCM token for user:", participantId);
        return null;
      }

      const scheduledTime = session.scheduledTime.toDate();
      const formattedDate = scheduledTime.toLocaleDateString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
      });
      const formattedTime = scheduledTime.toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
      });

      const message = {
        token: fcmToken,
        notification: {
          title: "New Session Request 📅",
          body: `${session.hostName} wants to practice ${session.language} with you on ${formattedDate} at ${formattedTime}`,
        },
        data: {
          type: "session_request",
          sessionId: event.params.sessionId,
          hostName: session.hostName || "",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "session_reminders",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      await messaging.send(message);
      console.log("Session request notification sent to:", participantId);
      return null;
    } catch (error) {
      console.error("Error sending session request notification:", error);
      return null;
    }
  }
);

/**
 * Send notification when a session request is accepted
 */
exports.onSessionAccepted = onDocumentUpdated(
  "scheduled_sessions/{sessionId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status !== "pending" || after.status !== "scheduled") {
      return null;
    }

    const hostId = after.hostId;
    if (!hostId) {
      return null;
    }

    try {
      const userDoc = await db.collection("users").doc(hostId).get();
      if (!userDoc.exists) {
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        return null;
      }

      const scheduledTime = after.scheduledTime.toDate();
      const formattedDate = scheduledTime.toLocaleDateString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
      });
      const formattedTime = scheduledTime.toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
      });

      const message = {
        token: fcmToken,
        notification: {
          title: "Session Confirmed! ✅",
          body: `Your session on ${formattedDate} at ${formattedTime} has been confirmed`,
        },
        data: {
          type: "session_accepted",
          sessionId: event.params.sessionId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "session_reminders",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      await messaging.send(message);
      console.log("Session accepted notification sent to:", hostId);
      return null;
    } catch (error) {
      console.error("Error sending session accepted notification:", error);
      return null;
    }
  }
);

/**
 * Process notification queue
 */
exports.processNotificationQueue = onDocumentCreated(
  "notification_queue/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;
    
    const notification = snapshot.data();

    if (notification.status !== "pending") {
      return null;
    }

    try {
      const userDoc = await db.collection("users").doc(notification.userId).get();
      if (!userDoc.exists) {
        await snapshot.ref.update({ status: "failed", error: "User not found" });
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        await snapshot.ref.update({ status: "failed", error: "No FCM token" });
        return null;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        android: {
          priority: "high",
          notification: {
            channelId: "session_reminders",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      await messaging.send(message);

      await snapshot.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Queued notification sent to:", notification.userId);
      return null;
    } catch (error) {
      console.error("Error processing notification:", error);
      await snapshot.ref.update({ status: "failed", error: error.message });
      return null;
    }
  }
);
