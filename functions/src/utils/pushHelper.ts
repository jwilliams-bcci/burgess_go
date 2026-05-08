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

  await admin.messaging().sendEachForMulticast({
    tokens: tokens,
    notification: {title, body},
    data: dataPayload,
  });
}
