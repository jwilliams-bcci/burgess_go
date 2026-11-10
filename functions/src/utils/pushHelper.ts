import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export async function sendPushToUser(
  targetUserId: number,
  title: string,
  body: string,
  dataPayload: any
) {
  const tokenDoc = await admin.firestore()
    .collection("user_tokens")
    .doc(targetUserId.toString())
    .get();

  const tokens: string[] = tokenDoc.data()?.tokens || [];

  if (tokens.length === 0) {
    logger.warn(`No push tokens found in user_tokens/${targetUserId}`);
    return;
  }

  logger.info(
    `Sending push to SecurityUserId ${targetUserId} (${tokens.length} token(s)): "${title}"`
  );

  const response = await admin.messaging().sendEachForMulticast({
    tokens: tokens,
    notification: {title, body},
    data: dataPayload,
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  logger.info(
    `Push result for SecurityUserId ${targetUserId}: ${response.successCount} succeeded, ${response.failureCount} failed.`
  );

  response.responses.forEach((resp, idx) => {
    const tokenPreview = tokens[idx] ? `${tokens[idx].substring(0, 16)}...` : "unknown";
    if (resp.success) {
      logger.info(`Token [${idx}] (${tokenPreview}) succeeded: messageId=${resp.messageId}`);
    } else {
      logger.error(
        `Token [${idx}] (${tokenPreview}) FAILED: code=${resp.error?.code} | message=${resp.error?.message}`
      );
    }
  });
}
