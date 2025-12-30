# Vehicle Request Trip Flow - User Stories & Endpoints

## Complete Trip Lifecycle

This document outlines the complete flow of a vehicle request from creation to trip completion, including all API endpoints and WebSocket events.

---

## User Story 1: Staff Member Creates Vehicle Request

**As a** staff member  
**I want to** create a vehicle request with destination selection on map  
**So that** I can request transportation for official duties

### Flow:
1. User opens request creation screen
2. User selects destination on map (tap to pick location)
3. User fills in trip details (date, time, purpose)
4. User submits request

### Endpoint:
```
POST /vehicles/requests
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "tripDate": "2024-01-15",
  "tripTime": "09:00",
  "destination": "123 Main Street, City",  // Address from reverse geocoding
  "purpose": "Official meeting with stakeholders",
  "destinationLatitude": 40.7580,         // From map picker
  "destinationLongitude": -73.9855,        // From map picker
  "officeLatitude": 40.7128,               // Optional: office location
  "officeLongitude": -74.0060              // Optional: office location
}
```

### Response:
```json
{
  "_id": "request123",
  "requesterId": "user456",
  "tripDate": "2024-01-15T00:00:00.000Z",
  "tripTime": "09:00",
  "destination": "123 Main Street, City",
  "purpose": "Official meeting with stakeholders",
  "requestedDestinationLocation": {
    "latitude": 40.7580,
    "longitude": -73.9855
  },
  "status": "PENDING",
  "workflowStage": "SUBMITTED",
  "tripStarted": false,
  "destinationReached": false,
  "tripCompleted": false
}
```

### State After:
- Request status: `PENDING`
- Workflow stage: `SUBMITTED`
- Request enters approval workflow

---

## User Story 2: Approval Workflow (Multiple Approvers)

**As an** approver (Supervisor, DGS, DDGS, ADGS)  
**I want to** review, approve, reject, or request corrections for vehicle requests  
**So that** requests are properly authorized and accurate before assignment

### Flow:
1. Approver views pending requests
2. Approver reviews request details
3. Approver can:
   - **Approve** the request as-is
   - **Reject** the request
   - **Request Corrections** and edit request details

### Endpoints:

#### Get Pending Approvals:
```
GET /vehicles/requests?pending=true
Authorization: Bearer {JWT_TOKEN}
```

#### Approve Request:
```
PUT /vehicles/requests/:id/approve
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "comment": "Approved for official duty"  // Optional
}
```

#### Reject Request:
```
PUT /vehicles/requests/:id/reject
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "comment": "Insufficient justification"  // Required
}
```

#### Request Corrections (Edit Request):
```
PUT /vehicles/requests/:id/correct
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "comment": "Please update the trip date and destination",  // Required - reason for correction
  "tripDate": "2024-01-16",        // Optional - new trip date
  "tripTime": "10:00",              // Optional - new trip time
  "destination": "Updated address", // Optional - new destination
  "purpose": "Updated purpose"      // Optional - new purpose
}
```

**Note**: Any approver can request corrections and edit any of the trip details. The approver can edit:
- Trip date
- Trip time
- Destination address
- Purpose

All fields are optional - only include the fields that need to be changed.

### Response (Correction):
```json
{
  "_id": "request123",
  "status": "CORRECTED",
  "tripDate": "2024-01-16T00:00:00.000Z",  // Updated if provided
  "tripTime": "10:00",                      // Updated if provided
  "destination": "Updated address",          // Updated if provided
  "purpose": "Updated purpose",              // Updated if provided
  "corrections": [
    {
      "requestedBy": "approver456",
      "role": "DGS",
      "comment": "Please update the trip date and destination",
      "timestamp": "2024-01-14T10:30:00.000Z",
      "resolved": false
    }
  ]
}
```

### State After Correction:
- Request status: `CORRECTED`
- Workflow stage: Remains at current stage
- Requester is notified and can resubmit
- Corrections array updated with correction request

### State After Approval:
- Request status: `APPROVED` (after all approvals)
- Workflow stage: `TO_REVIEW`
- Ready for vehicle assignment

### Approval Chain:
- **Lower-Level Staff (Level < 14)**: Supervisor → DGS → DDGS → ADGS → TO
- **Senior Staff (Level ≥ 14)**: DGS → DDGS → ADGS → TO

### WebSocket Events:
- `request:status:changed` - When request is corrected, approved, or rejected
- `request:corrected` - Specifically when corrections are requested (notifies requester)

---

## User Story 2.5: Requester Updates Corrected Request

**As a** requester  
**I want to** update my request after corrections are requested  
**So that** the request can proceed through approval

### Flow:
1. Requester receives notification that corrections are needed
2. Requester views the correction comments
3. Requester updates the request details
4. Request status changes back to `PENDING` and continues workflow

### Note:
When a request is corrected, the approver has already updated the fields. The requester can:
- View the updated details
- Accept the corrections
- Or create a new request if major changes are needed

The system automatically updates the request fields when corrections are made, so the requester sees the updated values immediately.

### State After Correction:
- Request status: `CORRECTED` → Can be resubmitted or continues workflow
- Updated fields are visible to requester
- Corrections array shows who requested changes and why

---

## User Story 3: Transport Officer Assigns Vehicle & Driver

**As a** Transport Officer (TO) or DGS  
**I want to** assign a vehicle and driver to approved requests  
**So that** the trip can proceed

### Flow:
1. TO/DGS views approved requests
2. TO/DGS selects available vehicle and driver
3. TO/DGS assigns them to the request
4. **Note**: TO/DGS can also edit trip details (date/time/vehicle) during assignment if needed

### Endpoint:
```
PUT /vehicles/requests/:id/assign
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "vehicleId": "vehicle789",
  "driverId": "driver101"  // Optional
}
```

### Response:
```json
{
  "_id": "request123",
  "status": "ASSIGNED",
  "vehicleId": "vehicle789",
  "driverId": "driver101",
  "tripStarted": false,
  "destinationReached": false,
  "tripCompleted": false
}
```

### Editing During Assignment:
If TO/DGS needs to adjust trip details during assignment, they can use the correction endpoint:

```
PUT /vehicles/requests/:id/correct
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "comment": "Adjusting trip time to accommodate vehicle availability",
  "tripTime": "09:30",  // Update time
  "tripDate": "2024-01-16"  // Update date if needed
}
```

Then proceed with assignment after corrections are applied.

### State After:
- Request status: `ASSIGNED`
- Vehicle and driver marked as unavailable
- Ready for trip to start

### WebSocket Event:
- `request:status:changed` - Broadcasted to requester and relevant staff

---

## User Story 4: Driver Starts Trip from Office

**As a** driver  
**I want to** start the trip from the office location  
**So that** the system tracks the actual departure time and location

### Flow:
1. Driver arrives at office
2. Driver opens assigned request in app
3. Driver taps "Start Trip"
4. App captures current location (office coordinates)
5. Trip tracking begins

### Endpoint:
```
POST /vehicles/requests/:id/trip/start
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "latitude": 40.7128,   // Office location
  "longitude": -74.0060  // Office location
}
```

### Response:
```json
{
  "_id": "request123",
  "tripStarted": true,
  "startLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "officeLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "actualDepartureTime": "2024-01-15T09:15:00.000Z",
  "status": "ASSIGNED"
}
```

### State After:
- `tripStarted`: `true`
- `startLocation`: Office coordinates saved
- `actualDepartureTime`: Recorded
- Status remains: `ASSIGNED` (during trip)

### WebSocket Events:
- `trip:started` - Broadcasted to:
  - Requester
  - All users in request room
  - Relevant staff (TO, DGS)

### Real-time Location Updates:
During the trip, driver's app should periodically send location updates:

```
POST /vehicles/requests/:id/trip/location
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "latitude": 40.7300,   // Current vehicle location
  "longitude": -73.9900
}
```

**Frequency**: Every 10-30 seconds during active trip

### WebSocket Event (Real-time):
- `trip:location:updated` - Broadcasted to:
  - Requester (to see vehicle position on map)
  - TO and DGS (for monitoring)

---

## User Story 5: Driver Reaches Destination

**As a** driver  
**I want to** mark when I reach the destination  
**So that** the system calculates outbound distance and fuel consumption

### Flow:
1. Driver arrives at destination
2. Driver taps "Reach Destination" (or auto-detected via geofencing)
3. App captures current location (destination coordinates)
4. System calculates outbound distance and fuel

### Endpoint:
```
POST /vehicles/requests/:id/trip/destination
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "latitude": 40.7580,   // Destination location
  "longitude": -73.9855,
  "notes": "Arrived at meeting venue"  // Optional
}
```

### Response:
```json
{
  "_id": "request123",
  "destinationReached": true,
  "destinationLocation": {
    "latitude": 40.7580,
    "longitude": -73.9855
  },
  "destinationReachedTime": "2024-01-15T10:30:00.000Z",
  "outboundDistanceKm": 12.5,
  "outboundFuelLiters": 2.8,
  "status": "ASSIGNED"
}
```

### State After:
- `destinationReached`: `true`
- `destinationLocation`: Destination coordinates saved
- `outboundDistanceKm`: Calculated (office → destination)
- `outboundFuelLiters`: Calculated for outbound leg
- Status remains: `ASSIGNED` (return journey pending)

### WebSocket Events:
- `trip:destination:reached` - Broadcasted to:
  - Requester
  - All users in request room
  - Relevant staff

---

## User Story 6: Driver Returns to Office

**As a** driver  
**I want to** mark when I return to the office  
**So that** the system calculates total distance, fuel, and completes the trip

### Flow:
1. Driver completes business at destination
2. Driver returns to office
3. Driver taps "Return to Office" (or auto-detected via geofencing)
4. App captures current location (office coordinates)
5. System calculates return distance, total distance, and total fuel

### Endpoint:
```
POST /vehicles/requests/:id/trip/return
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Request Body:
{
  "latitude": 40.7128,   // Office location
  "longitude": -74.0060,
  "notes": "Returned to office"  // Optional
}
```

### Response:
```json
{
  "_id": "request123",
  "tripCompleted": true,
  "returnLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "actualReturnTime": "2024-01-15T14:45:00.000Z",
  "outboundDistanceKm": 12.5,
  "returnDistanceKm": 12.5,
  "totalDistanceKm": 25.0,
  "outboundFuelLiters": 2.8,
  "returnFuelLiters": 2.8,
  "totalFuelLiters": 5.6,
  "status": "COMPLETED"
}
```

### State After:
- `tripCompleted`: `true`
- `returnLocation`: Office coordinates saved
- `actualReturnTime`: Recorded
- `totalDistanceKm`: Sum of outbound + return
- `totalFuelLiters`: Sum of outbound + return fuel
- Status: `COMPLETED`
- Vehicle and driver marked as available again

### WebSocket Events:
- `trip:completed` - Broadcasted to:
  - Requester
  - All users in request room
  - Relevant staff

---

## User Story 7: View Trip Details

**As a** requester, driver, or staff member  
**I want to** view complete trip details  
**So that** I can see trip statistics and tracking information

### Endpoint:
```
GET /vehicles/requests/:id/trip
Authorization: Bearer {JWT_TOKEN}
```

### Response:
```json
{
  "_id": "request123",
  "tripStarted": true,
  "destinationReached": true,
  "tripCompleted": true,
  "startLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "destinationLocation": {
    "latitude": 40.7580,
    "longitude": -73.9855
  },
  "returnLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "officeLocation": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "actualDepartureTime": "2024-01-15T09:15:00.000Z",
  "destinationReachedTime": "2024-01-15T10:30:00.000Z",
  "actualReturnTime": "2024-01-15T14:45:00.000Z",
  "tripDate": "2024-01-15T00:00:00.000Z",
  "tripTime": "09:00",
  "outboundDistanceKm": 12.5,
  "returnDistanceKm": 12.5,
  "totalDistanceKm": 25.0,
  "outboundFuelLiters": 2.8,
  "returnFuelLiters": 2.8,
  "totalFuelLiters": 5.6,
  "status": "COMPLETED"
}
```

---

## WebSocket Connection & Events

### Connection:
```
WebSocket: ws://localhost:3000/updates
Authentication: JWT token in handshake
{
  "auth": {
    "token": "your-jwt-token"
  }
}
```

### Subscribe to Request Updates:
```javascript
// Join request room for real-time updates
socket.emit('request:join', { requestId: 'request123' });
```

### Events Received:

1. **trip:started**
```json
{
  "requestId": "request123",
  "location": { "latitude": 40.7128, "longitude": -74.0060 },
  "actualDepartureTime": "2024-01-15T09:15:00.000Z",
  "scheduledTime": "09:00"
}
```

2. **trip:location:updated** (Real-time during trip)
```json
{
  "requestId": "request123",
  "location": { "latitude": 40.7300, "longitude": -73.9900 },
  "timestamp": "2024-01-15T09:45:00.000Z"
}
```

3. **trip:destination:reached**
```json
{
  "requestId": "request123",
  "location": { "latitude": 40.7580, "longitude": -73.9855 },
  "outboundDistance": 12.5,
  "outboundFuel": 2.8,
  "destinationReachedTime": "2024-01-15T10:30:00.000Z"
}
```

4. **trip:completed**
```json
{
  "requestId": "request123",
  "location": { "latitude": 40.7128, "longitude": -74.0060 },
  "outboundDistance": 12.5,
  "returnDistance": 12.5,
  "totalDistance": 25.0,
  "outboundFuel": 2.8,
  "returnFuel": 2.8,
  "totalFuel": 5.6,
  "actualReturnTime": "2024-01-15T14:45:00.000Z"
}
```

5. **request:status:changed**
```json
{
  "requestId": "request123",
  "status": "ASSIGNED",
  "type": "VEHICLE"
}
```

6. **request:corrected** (When corrections are requested)
```json
{
  "requestId": "request123",
  "status": "CORRECTED",
  "correction": {
    "requestedBy": "approver456",
    "role": "DGS",
    "comment": "Please update the trip date and destination",
    "timestamp": "2024-01-14T10:30:00.000Z"
  },
  "updatedFields": {
    "tripDate": "2024-01-16",
    "destination": "Updated address"
  }
}
```

---

## Complete Flow Diagram

```
1. CREATE REQUEST
   POST /vehicles/requests
   ↓
   Status: PENDING, Workflow: SUBMITTED

2. APPROVAL WORKFLOW
   ├─ PUT /vehicles/requests/:id/approve → Continue workflow
   ├─ PUT /vehicles/requests/:id/reject → Status: REJECTED (END)
   └─ PUT /vehicles/requests/:id/correct → Status: CORRECTED
       ↓ (After correction, can approve or request more corrections)
   ↓
   Status: APPROVED, Workflow: TO_REVIEW

3. ASSIGN VEHICLE & DRIVER
   PUT /vehicles/requests/:id/assign
   ↓
   Status: ASSIGNED
   [Note: TO/DGS can also use /correct endpoint to edit details before/after assignment]

4. START TRIP
   POST /vehicles/requests/:id/trip/start
   ↓
   tripStarted: true
   [Real-time location updates via POST /trip/location]

5. REACH DESTINATION
   POST /vehicles/requests/:id/trip/destination
   ↓
   destinationReached: true
   [Outbound distance & fuel calculated]

6. RETURN TO OFFICE
   POST /vehicles/requests/:id/trip/return
   ↓
   tripCompleted: true, Status: COMPLETED
   [Total distance & fuel calculated]
   [Vehicle & driver made available]
```

---

## Trip States Summary

| State | tripStarted | destinationReached | tripCompleted | Status | Can Edit? |
|-------|-------------|-------------------|---------------|--------|-----------|
| Request Created | false | false | false | PENDING | ✅ Any Approver |
| Correction Requested | false | false | false | CORRECTED | ✅ Any Approver |
| Assigned | false | false | false | ASSIGNED | ✅ TO, DGS |
| Trip Started | **true** | false | false | ASSIGNED | ❌ No (trip in progress) |
| At Destination | true | **true** | false | ASSIGNED | ❌ No (trip in progress) |
| Trip Completed | true | true | **true** | **COMPLETED** | ❌ No (trip finished) |

**Note**: Request details (date, time, destination, purpose) can be edited by approvers at any stage BEFORE the trip starts. Once `tripStarted = true`, editing is disabled.

---

## Permissions Summary

| Action | Allowed Roles |
|--------|--------------|
| Create Request | Any authenticated user |
| Approve/Reject | Supervisor, DGS, DDGS, ADGS (based on workflow) |
| **Request Corrections (Edit)** | **Any Approver (Supervisor, DGS, DDGS, ADGS, TO)** |
| Assign Vehicle | TO, DGS |
| **Edit During Assignment** | **TO, DGS** |
| Start Trip | Assigned Driver, TO, DGS |
| Reach Destination | Assigned Driver, TO, DGS |
| Return to Office | Assigned Driver, TO, DGS |
| Update Location | Assigned Driver, TO, DGS |
| View Trip Details | Any authenticated user with request access |

**Key Points:**
- **Any approver** can request corrections and edit request details at any approval stage
- **TO and DGS** can edit request details during assignment
- Editing is **disabled** once trip has started (`tripStarted = true`)
- DGS has override permissions and can edit/approve at any stage

---

## Error Scenarios

1. **Start Trip Without Assignment**
   - Error: "Request must be assigned before starting trip"
   - Status: Request must be `ASSIGNED`

2. **Reach Destination Without Starting**
   - Error: "Trip has not been started yet"
   - Must call `/trip/start` first

3. **Return Without Reaching Destination**
   - Error: "Destination must be reached before returning to office"
   - Must call `/trip/destination` first

4. **Duplicate Actions**
   - Error: "Trip has already been started/completed"
   - Prevents duplicate state changes

5. **Edit After Trip Started**
   - Error: Cannot edit request details once trip has started
   - Editing is only allowed before `tripStarted = true`

6. **Unauthorized Correction Request**
   - Error: "You do not have permission to request corrections"
   - Only approvers in the workflow can request corrections

