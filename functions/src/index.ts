import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {handleNewMessage} from "./handlers/chatHandler";
import {handleStatusChange} from "./handlers/statusHandler";

admin.initializeApp();

export const onInspectionUpdated = onDocumentUpdated(
  "inspections/{inspectionId}",
  async (event) => {
    if (!event.data) return;

    const before = event.data.before.data();
    const after = event.data.after.data();

    // --- SCENARIO 1: NEW CHAT MESSAGE ---
    const beforeMsgs = before?.inspectionMessages || [];
    const afterMsgs = after?.inspectionMessages || [];
    if (afterMsgs.length > beforeMsgs.length) {
      await handleNewMessage(event.params.inspectionId, before, after);
    }

    // --- SCENARIO 2: STATUS UPDATES ---
    // Check if the Status ID changed,
    // if startTime appeared, or if isUploaded flipped
    const statusChanged = before?.inspectionStatusId !==
    after?.inspectionStatusId;
    const justStarted = !before?.submission?.startTime &&
    after?.submission?.startTime;
    const justCompleted = before?.isUploaded !== true &&
    after?.isUploaded === true;

    if (statusChanged || justStarted || justCompleted) {
      await handleStatusChange(event.params.inspectionId, before, after);
    }
  }
);
