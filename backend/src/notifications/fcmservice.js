import { admin } from "../firebaseAdmin.js";

class FCMService {
  async sendToTopic(topic, title, body, data = {}, options = {}) {
    try {
      const message = {
        topic,
        notification: { title, body },
        data: {
          ...Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, v == null ? "" : String(v)])
          ),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: options.androidPriority ?? "high",
          notification: {
            channelId: options.channelId ?? "high_importance_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              sound: "default",
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`[FCM] Sent to topic=${topic} messageId=${response}`);
      return { success: true, messageId: response };
    } catch (error) {
      console.error(`[FCM] Failed topic=${topic}`, error.message);
      return { success: false, error: error.message };
    }
  }

  //  send one notice to many topics
  async sendToTopics(topics, title, body, data = {}, options = {}) {
    const results = {};
    for (const t of topics) {
      results[t] = await this.sendToTopic(t, title, body, data, options);
    }
    return results;
  }

  // Standard topic format for ward-based notifications (used by schedules)
  wardToTopic(ward) {
    return `ward_${String(ward).toLowerCase().trim().replaceAll(" ", "_")}`;
  }

  // Global topics (for notices)
  residentsTopic() {
    return "all_residents";
  }

  vendorsTopic() {
    return "all_vendors";
  }
}

export default new FCMService();