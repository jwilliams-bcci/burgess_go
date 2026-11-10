import { sendPushToUser } from "../utils/pushHelper";

export async function handleStatusChange(inspectionId: string, before: any, after: any) {
  const superId = after.superintendentSecurityUserId;
  if (!superId) return;

  const type = after.inspectionType || "Inspection";
  const inspector = after.inspector || "An inspector";
  const resolution = after.resolution || "View app for details";

  // 1. SCHEDULED (inspectionStatusId is 1)
  // Handles both brand new creations (before is empty) and updates
  if (before.inspectionStatusId !== 1 && after.inspectionStatusId === 1) {
    await sendPushToUser(
      superId,
      "Inspection Confirmed 📅",
      `Your ${type} inspection is confirmed!`,
      { type: "status_update", inspectionId }
    );
  }

  // 2. ASSIGNED (inspectionStatusId changes to 2)
  if (before.inspectionStatusId !== 2 && after.inspectionStatusId === 2) {
    await sendPushToUser(
      superId,
      "Inspector Assigned 👷‍♂️",
      `${inspector} will be performing your ${type} inspection.`,
      { type: "status_update", inspectionId }
    );
  }

  // 3. STARTED (submission.startTime is recorded)
  const beforeStartTime = before.submission?.startTime;
  const afterStartTime = after.submission?.startTime;

  if (!beforeStartTime && afterStartTime) {
    await sendPushToUser(
      superId,
      "Inspection Started ▶️",
      `Your ${type} inspection has started.`,
      { type: "status_update", inspectionId }
    );
  }

  // 4. COMPLETED (isComplete flag is flipped to true)
  // 🚨 Updated to isComplete!
  if (before.isComplete !== true && after.isComplete === true) {
    await sendPushToUser(
      superId,
      "Inspection Completed ✅",
      `Your ${type} inspection has been updated. Resolution: ${resolution}`,
      { type: "status_update", inspectionId }
    );
  }
}