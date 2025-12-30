---
name: Government Request Management System
overview: Build a complete government request management system with Flutter mobile app, Next.js admin panel, and NestJS backend. The system will handle vehicle, ICT, and store requests with complex approval workflows, role-based access control, notifications, and QR code generation.
todos: []
---

# Government Request Management System - Implementation Plan

## Architecture Overview

The system will be structured as a monorepo with three main applications:

- **Backend**: NestJS API server with MongoDB
- **Mobile App**: Flutter application for staff
- **Admin Web**: Next.js admin panel

## Technology Stack

- **Backend**: NestJS, MongoDB, JWT, SendGrid, Custom Push Notifications
- **Mobile**: Flutter, Provider/Riverpod (state management), Local notifications
- **Admin Web**: Next.js 14+, TypeScript, Tailwind CSS
- **Database**: MongoDB with Mongoose ODM
- **File Storage**: Local filesystem (development)

## Project Structure

```
request-app/
├── backend/                 # NestJS backend
│   ├── src/
│   │   ├── auth/           # Authentication module
│   │   ├── users/          # Staff/user management
│   │   ├── departments/    # Department management
│   │   ├── vehicles/       # Vehicle request workflow
│   │   ├── ict/            # ICT request workflow
│   │   ├── store/          # Store request workflow
│   │   ├── notifications/  # Push notification service
│   │   ├── email/          # Email service (SendGrid)
│   │   ├── workflow/       # Workflow engine
│   │   ├── qr/             # QR code generation
│   │   └── common/         # Shared utilities, guards, decorators
│   └── package.json
├── mobile/                 # Flutter app
│   ├── lib/
│   │   ├── core/           # Core utilities, constants
│   │   ├── models/         # Data models
│   │   ├── services/       # API services, notification service
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable widgets
│   │   └── main.dart
│   └── pubspec.yaml
├── admin-web/              # Next.js admin panel
│   ├── app/                # Next.js app directory
│   ├── components/         # React components
│   ├── lib/                # Utilities, API clients
│   └── package.json
└── shared/                 # Shared types/interfaces
    └── types/              # TypeScript interfaces
```

## Database Schema (MongoDB Collections)

### Core Collections

**users** (Staff)

- `_id`, `email`, `password` (hashed), `name`, `departmentId`, `level`, `roles[]`, `supervisorId`, `fcmToken`, `createdAt`, `updatedAt`

**departments**

- `_id`, `name`, `code`, `createdAt`, `updatedAt`

**vehicles**

- `_id`, `plateNumber`, `model`, `type`, `isPermanent`, `assignedToUserId`, `isAvailable`, `createdAt`, `updatedAt`

**drivers**

- `_id`, `name`, `phone`, `licenseNumber`, `isAvailable`, `createdAt`, `updatedAt`

**vehicleRequests**

- `_id`, `requesterId`, `tripDate`, `tripTime`, `destination`, `purpose`, `vehicleId`, `driverId`, `status`, `priority`, `workflowStage`, `approvals[]`, `corrections[]`, `createdAt`, `updatedAt`

**ictItems** (Catalog)

- `_id`, `name`, `description`, `category`, `quantity`, `isAvailable`, `createdAt`, `updatedAt`

**ictRequests**

- `_id`, `requesterId`, `items[]` (with quantities), `status`, `workflowStage`, `approvals[]`, `priority`, `qrCode`, `fulfillmentStatus[]`, `createdAt`, `updatedAt`

**storeItems** (Catalog)

- `_id`, `name`, `description`, `category`, `quantity`, `isAvailable`, `createdAt`, `updatedAt`

**storeRequests**

- `_id`, `requesterId`, `items[]`, `status`, `workflowStage`, `approvals[]`, `priority`, `qrCode`, `fulfillmentStatus[]`, `createdAt`, `updatedAt`

**notifications**

- `_id`, `userId`, `type`, `title`, `message`, `requestId`, `requestType`, `isRead`, `createdAt`

## Backend Implementation (NestJS)

### Key Modules

**1. Auth Module** (`backend/src/auth/`)

- JWT strategy and guards
- Login/refresh token endpoints
- Password hashing (bcrypt)
- Role-based access control decorators

**2. Workflow Engine** (`backend/src/workflow/`)

- Workflow router service that determines approval chain based on:
  - Staff level (< 14 vs >= 14)
  - Request type (vehicle/ICT/store)
  - Department boundaries
- Approval state machine
- Stage progression logic

**3. Vehicle Request Module** (`backend/src/vehicles/`)

- CRUD for vehicle requests
- Approval/rejection endpoints per role
- Vehicle assignment logic (TO, DGS override)
- Availability checking
- Priority setting (DGS only)
- Correction/return functionality

**4. ICT Request Module** (`backend/src/ict/`)

- CRUD for ICT requests
- Catalog management
- Approval workflow (Supervisor → DDICT → DGS → SO)
- Partial fulfillment handling
- Restock notification system
- QR code generation

**5. Store Request Module** (`backend/src/store/`)

- Similar to ICT module
- Dual approval path (DGS → SO or DGS → DDGS → ADGS → SO)
- Priority setting (DGS only)

**6. Notification Module** (`backend/src/notifications/`)

- Custom push notification service
- WebSocket support for real-time updates
- Notification queue system
- FCM token management

**7. Email Module** (`backend/src/email/`)

- SendGrid integration
- Email templates for:
  - Request submitted
  - Approval/rejection
  - Correction required
  - Assignment notifications
  - Status updates

**8. QR Module** (`backend/src/qr/`)

- QR code generation (qrcode library)
- Unique code per request
- Verification endpoints

### API Endpoints Structure

```
POST   /auth/login
POST   /auth/refresh

GET    /users/profile
GET    /users/dashboard

GET    /vehicles/requests
POST   /vehicles/requests
GET    /vehicles/requests/:id
PUT    /vehicles/requests/:id/approve
PUT    /vehicles/requests/:id/reject
PUT    /vehicles/requests/:id/assign
PUT    /vehicles/requests/:id/correct
PUT    /vehicles/requests/:id/priority

GET    /ict/requests
POST   /ict/requests
GET    /ict/requests/:id
PUT    /ict/requests/:id/approve
PUT    /ict/requests/:id/fulfill
PUT    /ict/items/:id/availability

GET    /store/requests
POST   /store/requests
GET    /store/requests/:id
PUT    /store/requests/:id/approve
PUT    /store/requests/:id/fulfill

GET    /notifications
PUT    /notifications/:id/read
POST   /notifications/register-token

GET    /qr/:code/verify
```

## Flutter Mobile App

### Key Features

**1. Authentication**

- Login screen
- JWT token storage (secure storage)
- Auto-refresh token logic
- Logout functionality

**2. Dashboard**

- Role-based dashboard views
- Pending approvals count
- My requests list
- Quick actions

**3. Request Creation**

- Vehicle request form
- ICT request form (with catalog selection)
- Store request form
- Form validation

**4. Request Management**

- Request list (with filters)
- Request detail view
- Approval/rejection actions
- Correction handling
- Status tracking with visual indicators

**5. Notifications**

- Local notification handling
- Push notification integration
- Notification list screen
- In-app notification badges

**6. QR Code**

- QR code display for requests
- QR scanner (for SO role)

### State Management

- Provider or Riverpod for state management
- API service layer with Dio
- Local caching with Hive or SharedPreferences

### Key Packages

- `dio` - HTTP client
- `flutter_secure_storage` - Token storage
- `flutter_local_notifications` - Local notifications
- `qr_flutter` - QR code display
- `qr_code_scanner` - QR scanning
- `provider` or `riverpod` - State management

## Next.js Admin Panel

### Key Features

**1. Admin Dashboard**

- Overview statistics
- Recent requests
- System health

**2. User Management**

- Staff CRUD
- Department management
- Role assignment
- Supervisor assignment

**3. Catalog Management**

- Vehicle management
- Driver management
- ICT items catalog
- Store items catalog

**4. Request Monitoring**

- All requests view (with filters)
- Request detail view
- Manual overrides
- System logs

**5. System Settings**

- Email configuration
- Notification settings
- Workflow configuration

### Tech Stack

- Next.js 14+ (App Router)
- TypeScript
- Tailwind CSS
- Shadcn/ui components
- React Query for data fetching

## Notification System Design

### Push Notification Flow

1. **Backend Event**: Request status change triggers notification
2. **Notification Service**: Creates notification record, sends push via custom service
3. **Mobile App**: Receives notification, updates local state, shows badge
4. **Email Service**: Sends email notification via SendGrid

### Custom Push Notification Implementation

- WebSocket server for real-time updates
- Background job queue (Bull/BullMQ) for reliable delivery
- Retry logic for failed notifications
- Device token management

## Workflow Implementation Details

### Workflow Engine Logic

The workflow engine will:

1. Determine staff level and request type
2. Build approval chain dynamically
3. Track current stage
4. Enforce role permissions
5. Handle corrections and overrides
6. Update status and notify next approver

### Approval Chain Examples

**Vehicle Request (Level < 14)**:

```
Requester → Supervisor → DGS → DDGS → ADGS → TO
```

**ICT Request (Level >= 14)**:

```
Requester → DDICT → DGS → SO
```

## Security Considerations

- JWT token expiration and refresh
- Role-based route guards
- Department boundary enforcement
- Input validation and sanitization
- Rate limiting on API endpoints
- Secure password hashing

## Development Phases

1. **Phase 1**: Backend foundation (Auth, Users, Departments)
2. **Phase 2**: Workflow engine and vehicle requests
3. **Phase 3**: ICT and Store requests
4. **Phase 4**: Notification system
5. **Phase 5**: Flutter mobile app (core features)
6. **Phase 6**: Next.js admin panel
7. **Phase 7**: QR codes and advanced features
8. **Phase 8**: Testing and optimization

## Environment Variables

**Backend**:

- `MONGODB_URI`
- `JWT_SECRET`
- `JWT_EXPIRATION`
- `SENDGRID_API_KEY`
- `PORT`
- `NODE_ENV`

**Mobile**:

- `API_BASE_URL`
- `FCM_SERVER_KEY` (if using FCM)

**Admin Web**:

- `NEXT_PUBLIC_API_URL`