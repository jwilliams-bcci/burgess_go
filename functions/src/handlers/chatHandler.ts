import {sendPushToUser} from "../utils/pushHelper";

export async function handleNewMessage(inspectionId: string, before: any, after: any) {
  const afterMsgs = after?.inspectionMessages || [];

  // Grab the very last message in the array (the one that was just added)
  const newMessage = afterMsgs[afterMsgs.length - 1];
  if (!newMessage) return;

  const senderId = newMessage.senderId;
  const messageText = newMessage.message || "Sent an image or attachment";

  // 🚨 Grab the SECURITY IDs that C# piped in
  const inspectorSecurityId = after.inspectorSecurityUserId;
  const superSecurityId = after.superintendentSecurityUserId;

  let targetUserId: number | null = null;
  let senderName = "New Message";

  // Figure out who sent it, and route to the OTHER person
  if (senderId === inspectorSecurityId) {
    // The inspector sent it, notify the superintendent!
    targetUserId = superSecurityId;
    senderName = after.inspector || "Inspector";
  } else if (senderId === superSecurityId) {
    // The superintendent sent it, notify the inspector!
    targetUserId = inspectorSecurityId;
    senderName = after.superName || "Superintendent";
  }

  // If the senderId doesn't match either of our security IDs, abort
  if (!targetUserId) {
    console.log(
      `Sender ${senderId} didn't match Inspector ` +
      `(${inspectorSecurityId}) or Super (${superSecurityId}).`
    );
    return;
  }

  // Fire off the push notification using your reusable helper!
  await sendPushToUser(
    targetUserId,
    senderName,
    messageText,
    {
      type: "chat_message",
      inspectionId: inspectionId,
    }
  );
}
