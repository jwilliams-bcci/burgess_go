import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { handleNewMessage } from "./handlers/chatHandler";
import { handleStatusChange } from "./handlers/statusHandler";

admin.initializeApp();

// 🚨 Changed to onDocumentWritten to catch brand new Scheduled inspections
export const onInspectionUpdated = onDocumentWritten(
  "inspections/{inspectionId}",
  async (event) => {
    if (!event.data) return;

    // Safely handle creates (before is null) and deletes (after is null)
    const before = event.data.before?.data() || {};
    const after = event.data.after?.data();

    // If the document was deleted, abort
    if (!after) return; 

    // --- SCENARIO 1: NEW CHAT MESSAGE ---
    const beforeMsgs = before.inspectionMessages || [];
    const afterMsgs = after.inspectionMessages || [];
    if (afterMsgs.length > beforeMsgs.length) {
      await handleNewMessage(event.params.inspectionId, before, after);
    }

    // --- SCENARIO 2: STATUS UPDATES ---
    const statusChanged = before.inspectionStatusId !== after.inspectionStatusId;
    
    // Safely check nested submission objects
    const beforeStartTime = before.submission?.startTime;
    const afterStartTime = after.submission?.startTime;
    const justStarted = !beforeStartTime && afterStartTime;
    const justCompleted = before.isComplete !== true && after.isComplete === true;

    if (statusChanged || justStarted || justCompleted) {
      await handleStatusChange(event.params.inspectionId, before, after);
    }
  }
);