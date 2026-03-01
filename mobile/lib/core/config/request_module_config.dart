import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/data/models/request_model.dart';
import '../../app/data/models/ict_request_model.dart';
import '../../app/data/models/store_request_model.dart';
import '../../app/presentation/pages/request_detail_page.dart';
import '../../app/presentation/pages/ict_request_detail_page.dart';
import '../constants/app_routes.dart';
import '../constants/app_icons.dart';

/// Central config for all request modules.
///
/// **Adding a new request module (e.g. "Maintenance"):**
/// 1. Add the new value to [RequestType] in `request_model.dart` (e.g. `maintenance`).
/// 2. Implement model, service, and controller (reuse patterns from vehicle/ict/store).
/// 3. Register service and controller in [InitialBinding].
/// 4. Add routes in [main.dart] (detail, history, fulfillment if needed).
/// 5. Implement the detail page and, if needed, create/fulfill pages.
/// 6. In this file: add cases for the new type in [label], [icon], [detailPath],
///    [historyRoute], [getTitle], [getSubtitle], [navigateToDetail], and any
///    [hasFulfillment]/[getStatus]/[getWorkflowStage]/[getCreatedAt]/[isPartiallyFulfilled].
/// 7. In [PermissionService]: add rules for the new type (stages, roles).
/// 8. List and approval queue will work via [UnifiedRequestCard] and [navigateToDetail].
class RequestModuleConfig {
  RequestModuleConfig._();

  static const List<RequestType> allTypes = [
    RequestType.vehicle,
    RequestType.ict,
    RequestType.store,
  ];

  static String label(RequestType type) {
    switch (type) {
      case RequestType.vehicle:
        return 'Vehicle';
      case RequestType.ict:
        return 'ICT';
      case RequestType.store:
        return 'Store';
    }
  }

  static IconData icon(RequestType type) {
    switch (type) {
      case RequestType.vehicle:
        return AppIcons.vehicle;
      case RequestType.ict:
        return AppIcons.ict;
      case RequestType.store:
        return AppIcons.store;
    }
  }

  /// Route path for detail: e.g. /requests/vehicle/123
  static String detailPath(RequestType type, String id) {
    return '/requests/${type.name}/$id';
  }

  /// History route for this type
  static String historyRoute(RequestType type) {
    switch (type) {
      case RequestType.vehicle:
        return AppRoutes.transportRequestHistory;
      case RequestType.ict:
        return AppRoutes.ictRequestHistory;
      case RequestType.store:
        return AppRoutes.storeRequestHistory;
    }
  }

  static bool hasFulfillment(RequestType type) {
    return type == RequestType.ict || type == RequestType.store;
  }

  static bool hasCreate(RequestType type) {
    return true; // all current types support create
  }

  /// Display title for list/history cards
  static String getTitle(RequestType type, dynamic request) {
    if (request == null) return '';
    switch (type) {
      case RequestType.vehicle:
        return (request as VehicleRequestModel).destination;
      case RequestType.ict:
        return 'ICT Request';
      case RequestType.store:
        return 'Store Request';
    }
  }

  /// Optional subtitle (e.g. item count)
  static String getSubtitle(RequestType type, dynamic request) {
    if (request == null) return '';
    switch (type) {
      case RequestType.vehicle:
        return '';
      case RequestType.ict:
        final r = request as ICTRequestModel;
        return '${r.items.length} ${r.items.length == 1 ? 'item' : 'items'}';
      case RequestType.store:
        final r = request as StoreRequestModel;
        return '${r.items.length} ${r.items.length == 1 ? 'item' : 'items'}';
    }
  }

  static RequestStatus getStatus(RequestType type, dynamic request) {
    if (request == null) return RequestStatus.pending;
    return (request as dynamic).status as RequestStatus;
  }

  static String getWorkflowStage(RequestType type, dynamic request) {
    if (request == null) return '';
    return (request as dynamic).workflowStage as String? ?? '';
  }

  static DateTime getCreatedAt(RequestType type, dynamic request) {
    if (request == null) return DateTime.now();
    return (request as dynamic).createdAt as DateTime;
  }

  static bool isPartiallyFulfilled(RequestType type, dynamic request) {
    if (request == null) return false;
    if (type == RequestType.ict) return (request as ICTRequestModel).isPartiallyFulfilled();
    return false;
  }

  /// Navigate to the correct detail page for this type. Use this everywhere
  /// instead of type-specific Get.to/Get.toNamed so new modules only need
  /// to update this and the route registration.
  static void navigateToDetail(
    RequestType type,
    String requestId, {
    RequestDetailSource? source,
    VoidCallback? onReturn,
  }) {
    switch (type) {
      case RequestType.vehicle:
        Get.to(
          () => RequestDetailPage(requestId: requestId, source: source),
        )?.then((_) => onReturn?.call());
        break;
      case RequestType.ict:
        Get.to(
          () => ICTRequestDetailPage(requestId: requestId, source: source),
        )?.then((_) => onReturn?.call());
        break;
      case RequestType.store:
        Get.toNamed(AppRoutes.storeRequestDetail(requestId))
            ?.then((_) => onReturn?.call());
        break;
    }
  }
}
