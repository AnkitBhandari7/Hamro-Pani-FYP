import { admin } from "../firebaseAdmin.js";

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

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
          payload: { aps: { alert: { title, body }, sound: "default" } },
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

  async sendToTokens(tokens, title, body, data = {}, options = {}) {
    const uniq = [...new Set((tokens || []).filter(Boolean))];
    if (uniq.length === 0) {
      return { success: true, successCount: 0, failureCount: 0, note: "No tokens" };
    }

    const batches = chunk(uniq, 500); // FCM limit
    let successCount = 0;
    let failureCount = 0;
    const errors = [];

    for (const batch of batches) {
      const message = {
        tokens: batch,
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(data).map(([k, v]) => [String(k), v == null ? "" : String(v)])
        ),
        android: {
          priority: options.androidPriority ?? "high",
          notification: {
            channelId: options.channelId ?? "high_importance_channel",
            sound: "default",
          },
        },
      };

      const resp = await admin.messaging().sendEachForMulticast(message);
      successCount += resp.successCount;
      failureCount += resp.failureCount;

      resp.responses.forEach((r, idx) => {
        if (!r.success) errors.push({ token: batch[idx], error: r.error?.message });
      });
    }

    return { success: failureCount === 0, successCount, failureCount, errors };
  }

  // ward topic must match Flutter subscription exactly.
  // "Kathmandu Ward 4" => "ward_kathmandu_ward_4"

  wardToTopic(ward) {
    return `ward_${String(ward).toLowerCase().trim().replaceAll(" ", "_")}`;
  }

  residentsTopic() {
    return "all_residents";
  }

  vendorsTopic() {
    return "all_vendors";
  }
}

export default new FCMService();