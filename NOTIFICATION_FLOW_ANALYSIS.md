# Notification Flow Analysis

## Complete Flow: Backend → Frontend

### 1. **Request Creation Flow**

#### Backend (when request is created):
```
createRequest() 
  → notifyRequestSubmitted(userId) 
    → createNotification(userId, type, title, message, requestId)
      → [SYNCHRONOUS] Save notification to DB
      → [SYNCHRONOUS] Emit WebSocket 'notification:new' event
      → [ASYNC] Queue job for processor
      → [ASYNC] Queue push notification job
```

#### Processor (runs asynchronously):
```
Processor receives job
  → Check if notification exists (last 5 seconds, same details)
  → If exists: Use existing, skip WebSocket (only send email)
  → If not exists: Create new, emit WebSocket, send email
```

#### Frontend (receives WebSocket):
```
WebSocketService receives 'notification:new'
  → Calls NotificationController.handleWebSocketNotification()
    → Checks for duplicates by ID
    → Checks for duplicates by content (title, message, requestId, time)
    → Adds to notifications list
    → Shows native notification
    → Updates unread count
```

---

## Issues Identified

### Issue #1: Duplicate Notification Creation (PARTIALLY FIXED)
**Location:** `backend/src/notifications/notifications.service.ts` + `notification.processor.ts`

**Problem:**
- `createNotification()` creates notification synchronously AND queues a job
- Processor also creates notification (even though we added duplicate check)
- Both emit WebSocket events

**Status:** ✅ FIXED - Processor now checks for existing notifications (10 second window) before creating
- Improved duplicate detection with better query (handles null requestId correctly)
- Increased time window from 5 to 10 seconds to handle database write delays
- Added explicit logging to track when duplicates are detected

---

### Issue #2: Potential Duplicate WebSocket Events
**Location:** `backend/src/notifications/notifications.service.ts` line 79-93

**Problem:**
- `createNotification()` emits WebSocket immediately (line 81)
- Processor might also emit WebSocket if it creates a new notification (line 80)
- Frontend receives duplicate WebSocket events

**Status:** ✅ FIXED - Processor explicitly skips WebSocket emission if notification already exists
- WebSocket emission is only in the `else` block (when creating new notification)
- Added clear logging to track when WebSocket is skipped vs emitted
- Processor only emits WebSocket if sync creation failed (rare edge case)

---

### Issue #3: Frontend Duplicate Detection May Fail
**Location:** `mobile/lib/app/presentation/controllers/notification_controller.dart` line 100-117

**Problem:**
- Checks for duplicates by ID first
- Then checks by content (title, message, requestId, time within 5 seconds)
- If notificationId is different but content is same, might not catch duplicate

**Status:** ✅ FIXED - Implemented robust hash-based duplicate detection
- Added content hash generation using SHA-256 (title + message + requestId + type)
- Tracks processed notification hashes to prevent re-processing
- Checks duplicates by hash before processing
- Increased time window from 5 to 10 seconds for content-based matching
- Hash tracking is maintained when loading notifications from server

---

### Issue #4: Workflow Progress Creates Additional Notifications
**Location:** `backend/src/vehicles/vehicles.service.ts` line 567-582

**Problem:**
- `notifyWorkflowProgress()` creates notifications for ALL participants
- Also emits `request:progress` WebSocket event
- Frontend handles `request:progress` and creates another notification
- This could cause duplicates if both `notification:new` and `request:progress` are received

**Status:** ⚠️ Potential Issue - Need to check if workflow progress is called on request creation

---

## Recommended Fixes

### Fix #1: Remove Synchronous Notification Creation
**Better Approach:** Only create notification in processor, emit WebSocket from processor

**OR**

### Fix #2: Improve Duplicate Detection
- Use unique constraint in database (userId + type + title + message + requestId + createdAt within 1 second)
- Or use a unique notification ID that's consistent

### Fix #3: Prevent Processor WebSocket Emission
- Processor should NEVER emit WebSocket if notification already exists
- Only the synchronous creation should emit WebSocket for immediate feedback

### Fix #4: Frontend Better Deduplication ✅ APPLIED
- ✅ Implemented hash-based duplicate detection using SHA-256
- ✅ Hash generated from: title + message + requestId + type
- ✅ Tracks processed notification hashes in `_processedNotificationHashes` Set
- ✅ Checks hash before processing any notification
- ✅ Hash tracking maintained when loading notifications from server
- ✅ Increased time window for content-based matching from 5 to 10 seconds

---

## Current Flow Diagram

```
Request Created
    │
    ├─→ notifyRequestSubmitted()
    │       │
    │       └─→ createNotification()
    │               │
    │               ├─→ [SYNC] Save to DB
    │               ├─→ [SYNC] Emit WebSocket 'notification:new' ──┐
    │               ├─→ [ASYNC] Queue job ──────────────────────────┼─→ Processor
    │               └─→ [ASYNC] Queue push notification              │
    │                                                               │
    └─→ Processor (async)                                           │
            │                                                       │
            ├─→ Check if notification exists (10 sec window)       │
            │                                                       │
            ├─→ If EXISTS: Use existing, send email only           │
            │                                                       │
            └─→ If NOT EXISTS: Create new, emit WebSocket ──────────┘
                                                                    │
                                                                    ▼
                                            Frontend receives WebSocket
                                                                    │
                                                                    ├─→ handleWebSocketNotification()
                                                                    │       │
                                                                    │       ├─→ Check duplicate by ID
                                                                    │       ├─→ Check duplicate by content
                                                                    │       └─→ Add to list
                                                                    │
                                                                    └─→ Show notification
```

---

## Testing Checklist

- [ ] Create request → Check if only 1 notification appears
- [ ] Check backend logs for duplicate notification creation
- [ ] Check frontend logs for duplicate WebSocket events
- [ ] Verify processor doesn't create duplicate if notification exists
- [ ] Verify processor doesn't emit WebSocket if notification exists
- [ ] Test with slow network (processor might run before sync save)
- [ ] Test with fast network (sync save completes before processor)
