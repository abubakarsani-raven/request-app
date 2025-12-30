# Government Request Management System

A comprehensive system for managing government requests including vehicle, ICT, and store requests with complex approval workflows.

## Project Structure

```
request-app/
├── backend/          # NestJS backend API
├── mobile/          # Flutter mobile application
├── admin-web/       # Next.js admin panel
└── shared/          # Shared TypeScript types
```

## Technology Stack

- **Backend**: NestJS, MongoDB, JWT, SendGrid
- **Mobile**: Flutter, Provider (state management)
- **Admin Web**: Next.js 14, TypeScript, Tailwind CSS

## Getting Started

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```
MONGODB_URI=mongodb://localhost:27017/request-app
JWT_SECRET=your-secret-key
JWT_EXPIRATION=7d
SENDGRID_API_KEY=your-sendgrid-api-key
PORT=4000
NODE_ENV=development
```

4. Run the server:
```bash
npm run start:dev
```

### Mobile App Setup

1. Navigate to mobile directory:
```bash
cd mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API base URL in `lib/core/constants/api_constants.dart`

4. Run the app:
```bash
flutter run
```

### Admin Web Setup

1. Navigate to admin-web directory:
```bash
cd admin-web
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env.local` file:
```
NEXT_PUBLIC_API_URL=http://localhost:4000
```

4. Run the development server:
```bash
npm run dev
```

## Features

### Backend
- ✅ Authentication with JWT
- ✅ User and Department management
- ✅ Workflow engine for approval chains
- ✅ Vehicle request workflow
- ✅ ICT request workflow
- ✅ Store request workflow
- ✅ Email notifications (SendGrid)
- ✅ Push notification system
- ✅ QR code generation

### Mobile App
- ✅ User authentication
- ✅ Dashboard
- ✅ Request creation and management
- ✅ Notifications
- ✅ Profile management

### Admin Web
- ✅ Admin dashboard
- ✅ User management (placeholder)
- ✅ Department management (placeholder)
- ✅ Request monitoring (placeholder)
- ✅ Catalog management (placeholder)

## API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh token

### Users
- `GET /users/profile` - Get current user profile
- `GET /users/dashboard` - Get user dashboard data

### Vehicle Requests
- `GET /vehicles/requests` - List vehicle requests
- `POST /vehicles/requests` - Create vehicle request
- `PUT /vehicles/requests/:id/approve` - Approve request
- `PUT /vehicles/requests/:id/reject` - Reject request
- `PUT /vehicles/requests/:id/assign` - Assign vehicle/driver

### ICT Requests
- `GET /ict/requests` - List ICT requests
- `POST /ict/requests` - Create ICT request
- `PUT /ict/requests/:id/fulfill` - Fulfill request

### Store Requests
- `GET /store/requests` - List store requests
- `POST /store/requests` - Create store request
- `PUT /store/requests/:id/fulfill` - Fulfill request

### Notifications
- `GET /notifications` - Get user notifications
- `PUT /notifications/:id/read` - Mark as read

## Development Status

- ✅ Phase 1: Backend foundation
- ✅ Phase 2: Workflow engine and vehicle requests
- ✅ Phase 3: ICT and Store requests
- ✅ Phase 4: Notification system
- ✅ Phase 5: Flutter mobile app (core features)
- ✅ Phase 6: Next.js admin panel (basic structure)
- ✅ Phase 7: QR codes
- ⏳ Phase 8: Testing and optimization

## License

MIT

