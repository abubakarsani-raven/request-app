---
name: Flutter Frontend Implementation
overview: Build a complete Flutter mobile app with custom UI design system, GetX state management, reusable components, Google Maps integration, WebSocket real-time updates, and full request management functionality for Vehicle, ICT, Store, and future request types.
todos: []
---

# Flutter Frontend Implementation Plan

## Architecture Overview

The Flutter app will use:

- **GetX** for state management, routing, and dependency injection
- **Custom Design System** with reusable components
- **Google Maps** for destination picker and trip tracking (Vehicle requests)
- **WebSocket** for real-time updates
- **Modular structure** for scalability
- **Generic request system** supporting Vehicle, ICT, Store, and extensible for future types

## Project Structure

```
mobile/lib/
├── app/
│   ├── data/              # Data sources (API, local storage)
│   ├── domain/            # Business logic, models
│   └── presentation/       # UI layer
│       ├── bindings/      # GetX bindings
│       ├── controllers/   # GetX controllers
│       ├── pages/         # Screen pages
│       └── widgets/       # Reusable widgets
├── core/
│   ├── theme/             # Custom theme, colors, typography
│   ├── constants/         # App constants
│   ├── utils/             # Utilities, helpers
│   └── services/          # Core services (API, WebSocket, etc.)
└── main.dart
```

## Technology Stack

- **State Management**: GetX
- **Navigation**: GetX routing
- **HTTP Client**: Dio (already in project)
- **Maps**: google_maps_flutter
- **Location**: geolocator
- **Polyline**: google_polyline_algorithm
- **WebSocket**: socket_io_client
- **Storage**: GetStorage (lightweight, GetX-compatible)
- **Notifications**: flutter_local_notifications

## Implementation Phases

### Phase 1: Foundation & Setup

- GetX setup and dependency injection
- Custom theme and design system
- Core services (API, storage, WebSocket)
- Authentication flow
- Navigation structure

### Phase 2: Core Features

- **Vehicle Request** creation with map picker
- **ICT Request** creation with catalog selection
- **Store Request** creation with item selection
- Request list and details (all types)
- Approval workflow UI (generic for all types)
- Dashboard with statistics (all request types)
- Request type filtering and navigation

### Phase 3: Request-Specific Features

- **Vehicle Requests**: Trip tracking, start/end screens, real-time location tracking, Google Maps integration, polyline rendering, trip statistics
- **ICT Requests**: Catalog browsing, item selection, fulfillment tracking
- **Store Requests**: Inventory browsing, item selection, fulfillment tracking
- Request status tracking for all types

### Phase 4: Advanced Features

- WebSocket real-time updates (all request types)
- Push notifications (all request types)
- QR code scanning (for SO role - Store requests)
- Profile management
- Settings
- Request history and analytics
- Multi-request type dashboard widgets

### Phase 5: Role-Based Access Control

- Permission service implementation
- Role-based UI components and guards
- Role-specific dashboards (Driver, TO, DGS, SO, etc.)
- Vehicle assignment interface (TO/DGS)
- Driver trip management view
- Role-based navigation and routing
- Permission checks in all controllers
- Role-based feature flags

## Key Components to Build

### Reusable Widgets

1. **CustomButton** - Primary, secondary, outlined variants
2. **CustomTextField** - With validation, icons, error states
3. **CustomCard** - Consistent card styling
4. **LoadingIndicator** - Custom loading states
5. **EmptyState** - No data states
6. **ErrorWidget** - Error display
7. **StatusBadge** - Request status indicators
8. **MapPicker** - Destination selection on map (Vehicle requests)
9. **TripTracker** - Real-time trip tracking widget (Vehicle requests)
10. **RequestCard** - Generic request list item (all types)
11. **CatalogBrowser** - ICT catalog item selection widget
12. **InventoryBrowser** - Store inventory item selection widget
13. **RequestTypeSelector** - Request type selection widget
14. **FulfillmentTracker** - ICT/Store fulfillment status widget
15. **RoleGuard** - Widget that shows/hides based on role
16. **PermissionButton** - Button with permission checking
17. **RoleBasedDashboard** - Dynamic dashboard widget
18. **AssignmentCard** - Vehicle/driver assignment card
19. **DriverTripCard** - Driver trip card with actions
20. **ApprovalCard** - Approval queue card
21. **QRScannerWidget** - QR code scanner widget (SO)

### Pages/Screens

1. **SplashScreen** - Initial loading
2. **LoginPage** - Authentication
3. **DashboardPage** - Role-based dashboard (all request types)
4. **CreateRequestPage** - Generic request creation (supports all types)

   - Vehicle: Map picker integration
   - ICT: Catalog selection
   - Store: Inventory selection

5. **RequestListPage** - All requests with type filtering
6. **RequestDetailPage** - Request details and actions (all types)
7. **TripTrackingPage** - Active trip tracking (Vehicle only)
8. **ICTFulfillmentPage** - ICT request fulfillment tracking
9. **StoreFulfillmentPage** - Store request fulfillment tracking
10. **NotificationsPage** - Notification list (all types)
11. **ProfilePage** - User profile
12. **ApprovalPage** - Approval/rejection interface (all types)
13. **CatalogPage** - ICT catalog browsing
14. **InventoryPage** - Store inventory browsing

**Role-Specific Pages:**

15. **DriverDashboardPage** - Driver-specific dashboard with assigned trips
16. **TODashboardPage** - Transport Officer dashboard with assignments
17. **DGSDashboardPage** - DGS dashboard with full access
18. **AssignmentPage** - Vehicle/driver assignment interface (TO/DGS)
19. **DriverTripPage** - Driver trip management and tracking
20. **VehicleManagementPage** - Vehicle list and availability (TO/DGS)
21. **DriverManagementPage** - Driver list and availability (TO/DGS)
22. **QRScanPage** - QR code scanning for fulfillment (SO)
23. **ApprovalQueuePage** - Pending approvals by role
24. **FulfillmentQueuePage** - Pending fulfillments (SO)

## Design System

### Colors

- Primary, secondary, accent colors
- Success, error, warning colors
- Background, surface, text colors
- Dark mode support

### Typography

- Heading styles (H1-H6)
- Body text styles
- Caption, label styles

### Spacing

- Consistent spacing scale (4, 8, 12, 16, 24, 32)

### Components

- Buttons (primary, secondary, outlined, text)
- Input fields (text, date, time, dropdown)
- Cards (elevated, outlined)
- Dialogs (alert, confirmation, info)
- Bottom sheets
- App bars (standard, custom)

## State Management with GetX

### Controllers

- **AuthController** - Authentication state
- **RequestController** - Generic request CRUD operations (all types)
- **VehicleRequestController** - Vehicle-specific operations (trip tracking)
- **ICTRequestController** - ICT-specific operations (catalog, fulfillment)
- **StoreRequestController** - Store-specific operations (inventory, fulfillment)
- **TripController** - Trip tracking state (Vehicle requests)
- **NotificationController** - Notifications (all types)
- **MapController** - Map interactions (Vehicle requests)
- **DashboardController** - Dashboard data (all request types)
- **CatalogController** - ICT catalog management
- **InventoryController** - Store inventory management
- **PermissionController** - Role-based permission checking
- **RoleController** - Role-specific data and actions
- **AssignmentController** - Vehicle/driver assignment (TO/DGS)
- **DriverController** - Driver-specific operations

### Bindings

- Each page has corresponding binding
- Dependency injection setup
- Lifecycle management

## API Integration

### Services

- **ApiService** - Base HTTP client with Dio
- **AuthService** - Login, logout, token management
- **RequestService** - Generic request CRUD operations (all types)
- **VehicleRequestService** - Vehicle request endpoints
- **ICTRequestService** - ICT request endpoints (catalog, fulfillment)
- **StoreRequestService** - Store request endpoints (inventory, fulfillment)
- **TripService** - Trip tracking endpoints (Vehicle requests)
- **NotificationService** - Notification endpoints (all types)
- **WebSocketService** - Real-time updates (all request types)
- **CatalogService** - ICT catalog endpoints
- **InventoryService** - Store inventory endpoints
- **PermissionService** - Role-based permission checking
- **AssignmentService** - Vehicle/driver assignment endpoints
- **DriverService** - Driver management endpoints

### Models

- **UserModel** - User data
- **BaseRequestModel** - Base request model (abstract)
- **VehicleRequestModel** - Vehicle request with trip tracking
- **ICTRequestModel** - ICT request with catalog items
- **StoreRequestModel** - Store request with inventory items
- **TripTrackingModel** - Trip tracking data (Vehicle)
- **CatalogItemModel** - ICT catalog item
- **InventoryItemModel** - Store inventory item
- **NotificationModel** - Notification data (all types)
- **ApprovalModel** - Approval workflow data

## Google Maps Integration (Vehicle Requests)

### Features

- **Map Picker**: Tap to select destination
- **Current Location**: Auto-center on user location
- **Route Display**: Show route polyline
- **Real-time Tracking**: Update vehicle position
- **Markers**: Start, destination, current position
- **Search**: Location search functionality

**Note**: Maps integration is specific to Vehicle requests only

## WebSocket Integration

### Events

- Connect with JWT authentication
- Join request rooms
- Listen for trip updates
- Real-time location updates
- Status change notifications

## Implementation Details

### Request Creation Flow (Generic)

**Vehicle Requests:**

1. User selects request type (Vehicle)
2. User selects destination on map
3. Reverse geocoding for address
4. Fill trip details form (date, time, purpose)
5. Submit with coordinates
6. Show success and navigate

**ICT Requests:**

1. User selects request type (ICT)
2. Browse ICT catalog
3. Select catalog items and quantities
4. Fill request details (purpose, priority)
5. Submit request
6. Show success and navigate

**Store Requests:**

1. User selects request type (Store)
2. Browse store inventory
3. Select inventory items and quantities
4. Fill request details (purpose, priority)
5. Submit request
6. Show success and navigate

### Trip Tracking Flow (Vehicle Only)

1. Driver starts trip (capture office location)
2. Real-time location updates (every 10-30s)
3. Map shows vehicle position and route
4. Reach destination (auto or manual)
5. Return to office
6. Show trip summary (distance, fuel)

### Fulfillment Flow (ICT/Store)

1. SO/Store Manager views pending fulfillments
2. Review request details and items
3. Scan QR code or manually fulfill
4. Update fulfillment status
5. Mark as completed
6. Notify requester

### Approval Flow (All Request Types)

1. View pending approvals (filtered by type and role)
2. Review request details
3. Approve/reject/correct (role-based permissions)
4. Edit details if correcting (type-specific fields)
5. Submit action
6. Request moves to next stage or completion

### Vehicle Assignment Flow (TO/DGS)

1. TO/DGS views approved vehicle requests
2. Select available vehicle from list
3. Optionally select available driver
4. Assign vehicle and driver to request
5. Request status changes to ASSIGNED
6. Driver receives notification
7. Driver can start trip

### Driver Trip Flow

1. Driver views assigned trips in dashboard
2. Driver navigates to trip details
3. Driver starts trip (captures office location)
4. Real-time location tracking begins
5. Driver reaches destination (manual or auto)
6. Driver returns to office
7. Trip completed, vehicle/driver available again

## Testing Strategy

- Unit tests for controllers
- Widget tests for reusable components
- Integration tests for critical flows

## Performance Considerations

- Lazy loading for lists
- Image caching
- Map tile optimization
- WebSocket reconnection handling
- Background location updates

## Role-Based Access Control (RBAC)

### Roles and Permissions

**Roles in the System:**

- **SUPERVISOR** - Approve/reject requests from subordinates
- **DGS** - Approve requests, assign vehicles, set priority, override workflows
- **DDGS** - Approve requests in workflow chain
- **ADGS** - Approve requests in workflow chain
- **TO (Transport Officer)** - Assign vehicles and drivers, manage vehicle requests
- **DDICT** - Approve ICT requests
- **SO (Store Officer)** - Fulfill ICT/Store requests, scan QR codes
- **DRIVER** - Start/end trips, track location, view assigned trips
- **Regular Staff** - Create requests, view own requests

### Role-Specific Views and Features

**1. Driver View:**

- Dashboard showing only assigned trips
- Trip start/end functionality
- Real-time location tracking
- Trip history
- Navigation to trip destinations
- No access to request creation or approval

**2. TO (Transport Officer) View:**

- Dashboard with pending vehicle assignments
- Vehicle assignment interface
- Driver management
- Vehicle availability view
- All vehicle requests list
- Can assign vehicles and drivers
- Can edit request details during assignment

**3. DGS View:**

- Full dashboard with all request types
- Can approve/reject requests
- Can assign vehicles (override TO)
- Can set priority on requests
- Can request corrections
- Can view all requests across departments
- Override permissions for urgent cases

**4. DDGS/ADGS View:**

- Dashboard with pending approvals
- Approve/reject requests in workflow
- Request corrections
- View request statistics
- Cannot assign vehicles (TO/DGS only)

**5. DDICT View:**

- ICT request approvals
- ICT catalog management
- ICT request statistics
- Cannot manage vehicles

**6. SO (Store Officer) View:**

- Pending fulfillment requests (ICT/Store)
- QR code scanning interface
- Fulfillment tracking
- Inventory management
- Cannot approve requests

**7. Supervisor View:**

- Dashboard with subordinate requests
- Approve/reject subordinate requests
- Request corrections
- View team statistics

**8. Regular Staff View:**

- Create requests (all types)
- View own requests
- Track request status
- Cannot approve or assign

### Role-Based UI Components

**Permission Service:**

- `PermissionService` - Centralized permission checking
- Methods: `canApprove()`, `canAssign()`, `canFulfill()`, `canCreate()`, etc.
- Role-based feature flags

**Role-Based Navigation:**

- Different bottom navigation based on role
- Role-specific menu items
- Conditional route access

**Role-Based Widgets:**

- `RoleGuard` - Widget that shows/hides based on role
- `PermissionButton` - Button that checks permissions before showing
- `RoleBasedDashboard` - Dynamic dashboard based on user role

### Implementation Details

**Permission Checking:**

```dart
class PermissionService {
  bool canApprove(UserModel user, RequestType type, WorkflowStage stage);
  bool canAssignVehicle(UserModel user);
  bool canFulfillRequest(UserModel user, RequestType type);
  bool canSetPriority(UserModel user);
  bool canViewAllRequests(UserModel user);
  bool canStartTrip(UserModel user, String requestId);
}
```

**Role-Specific Pages:**

- `DriverDashboardPage` - Driver-specific dashboard
- `TODashboardPage` - Transport Officer dashboard
- `DGSDashboardPage` - DGS dashboard with full access
- `AssignmentPage` - Vehicle/driver assignment (TO/DGS only)
- `FulfillmentPage` - Fulfillment interface (SO only)
- `ApprovalPage` - Approval interface (role-based)

**Role-Based Controllers:**

- `PermissionController` - Manages permission checks
- `RoleController` - Manages role-specific data and actions
- Update existing controllers to check permissions

## Security

- Secure token storage
- API request encryption
- Input validation (all request types)
- Error handling without exposing sensitive data
- Role-based access control (all request types)
- Type-specific permission checks
- Frontend permission validation (UI level)
- Backend permission enforcement (API level)
- Role-based route guards

## Extensibility

The architecture is designed to easily add new request types:

1. Create new request model extending base model
2. Create type-specific service
3. Create type-specific controller
4. Add type-specific UI components
5. Update request type selector
6. Add type-specific pages if needed

All core functionality (approval, notifications, dashboard) works generically across all request types.

## Role-Based Implementation Strategy

### Permission Checking Pattern

1. **Service Layer**: `PermissionService` checks user roles and permissions
2. **Controller Layer**: Controllers use permission service before actions
3. **UI Layer**: Widgets conditionally render based on permissions
4. **Route Layer**: Route guards prevent unauthorized access

### Role Detection

- User roles stored in `UserModel`
- Roles checked on app initialization
- Roles cached in `AuthController`
- Permission checks performed before UI rendering

### Dynamic UI Rendering

- Dashboard adapts to user role
- Navigation menu shows only relevant items
- Action buttons appear based on permissions
- Feature flags control role-specific features

### Security Best Practices

- Never trust frontend permissions alone
- Always validate on backend
- Hide UI elements user can't access
- Show clear error messages for unauthorized actions
- Log permission violations for auditing