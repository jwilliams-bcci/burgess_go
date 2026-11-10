import * as admin from "firebase-admin";

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
    console.log(`No push tokens found for SecurityUserId: ${targetUserId}`);
    return;
  }

  console.log(
    `Sending push notification to SecurityUserId ${targetUserId} (${tokens.length} token(s)): "${title}"`
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

  console.log(
    `Push result for SecurityUserId ${targetUserId}: ` +
    `${response.successCount} succeeded, ${response.failureCount} failed.`
  );

  response.responses.forEach((resp, idx) => {
    const tokenPreview = tokens[idx] ? `${tokens[idx].substring(0, 16)}...` : "unknown";
    if (resp.success) {
      console.log(`  ✅ Token [${idx}] (${tokenPreview}) succeeded: messageId=${resp.messageId}`);
    } else {
      console.error(
        `  ❌ Token [${idx}] (${tokenPreview}) failed: ` +
        `code=${resp.error?.code}, message=${resp.error?.message}`,
        resp.error
      );
    }
  });
}
