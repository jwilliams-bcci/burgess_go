import {sendPushToUser} from "../utils/pushHelper";

export async function handleStatusChange(inspectionId: string, before: any, after: any) {
  // We only send these specific alerts to the Superintendent
  const superId = after.superintendentSecurityUserId;
  if (!superId) return;

  // Extract the variables from the document to inject into the messages
  const type = after.inspectionType || "Inspection";
  const inspector = after.inspector || "An inspector";
  const resolution = after.resolution || "View app for details";

  // 1. SCHEDULED (inspectionStatusId changes to 1)
  if (before.inspectionStatusId !== 1 && after.inspectionStatusId === 1) {
    await sendPushToUser(
      superId,
      "Inspection Confirmed 📅",
      `Your ${type} inspection is confirmed!`,
      {type: "status_update", inspectionId}
    );
  }

  // 2. ASSIGNED (inspectionStatusId changes to 2)
  if (before.inspectionStatusId !== 2 && after.inspectionStatusId === 2) {
    await sendPushToUser(
      superId,
      "Inspector Assigned 👷‍♂️",
      `${inspector} will be performing your ${type} inspection.`,
      {type: "status_update", inspectionId}
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
      {type: "status_update", inspectionId}
    );
  }

  // 4. COMPLETED (isUploaded flag is created/switched to true)
  if (before.isUploaded !== true && after.isUploaded === true) {
    await sendPushToUser(
      superId,
      "Inspection Completed ✅",
      `Your ${type} inspection has been updated. Resolution: ${resolution}`,
      {type: "status_update", inspectionId}
    );
  }
}
