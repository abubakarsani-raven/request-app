import 'package:flutter/material.dart';

/// Standardized icon constants and sizes for the app
class AppIcons {
  // Icon sizes
  static const double sizeDefault = 24.0;
  static const double sizeSmall = 20.0;
  static const double sizeTiny = 16.0;
  static const double sizeLarge = 28.0;
  
  // Navigation & Menu
  static const IconData menu = Icons.menu_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData moreVert = Icons.more_vert_rounded;
  static const IconData moreHoriz = Icons.more_horiz_rounded;
  
  // Dashboard & Home
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData home = Icons.home_rounded;
  
  // Requests
  static const IconData requests = Icons.list_alt_rounded;
  static const IconData requestList = Icons.view_list_rounded;
  static const IconData createRequest = Icons.add_circle_rounded;
  static const IconData pendingRequests = Icons.pending_actions_rounded;
  static const IconData myRequests = Icons.assignment_rounded;
  
  // Request Types
  static const IconData vehicle = Icons.directions_car_rounded;
  static const IconData vehicleFilled = Icons.directions_car_filled_rounded;
  static const IconData ict = Icons.computer_rounded;
  static const IconData store = Icons.inventory_2_rounded;
  static const IconData inventory = Icons.inventory_rounded;
  
  // Status & Actions
  static const IconData check = Icons.check_circle_rounded;
  static const IconData checkOutline = Icons.check_circle_outline_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData cancel = Icons.cancel_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  
  // Status Indicators
  static const IconData pending = Icons.pending_rounded;
  static const IconData approved = Icons.check_circle_rounded;
  static const IconData rejected = Icons.cancel_rounded;
  static const IconData assigned = Icons.assignment_rounded;
  static const IconData completed = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData priority = Icons.priority_high_rounded;
  
  // User & Profile
  static const IconData user = Icons.person_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData logout = Icons.logout_rounded;
  
  // Notifications
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData notificationsOutlined = Icons.notifications_outlined;
  static const IconData notificationsOff = Icons.notifications_off_rounded;
  
  // Location & Maps
  static const IconData location = Icons.location_on_rounded;
  static const IconData locationOff = Icons.location_off_rounded;
  static const IconData map = Icons.map_rounded;
  static const IconData directions = Icons.directions_rounded;
  static const IconData navigation = Icons.navigation_rounded;
  
  // Search & Filter
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  
  // Time & Date
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData time = Icons.access_time_rounded;
  static const IconData schedule = Icons.schedule_rounded;
  
  // Communication
  static const IconData email = Icons.email_rounded;
  static const IconData phone = Icons.phone_rounded;
  static const IconData message = Icons.message_rounded;
  
  // Files & Documents
  static const IconData file = Icons.description_rounded;
  static const IconData folder = Icons.folder_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData attach = Icons.attach_file_rounded;
  
  // Media
  static const IconData image = Icons.image_rounded;
  static const IconData camera = Icons.camera_rounded;
  static const IconData video = Icons.videocam_rounded;
  
  // Other
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData unlock = Icons.lock_open_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_border_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData print = Icons.print_rounded;
  static const IconData qrCode = Icons.qr_code_rounded;
  static const IconData scan = Icons.qr_code_scanner_rounded;
  
  // Theme
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  
  // Helper method to get icon with consistent size
  static Widget icon(
    IconData iconData, {
    double? size,
    Color? color,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeDefault,
      color: color,
    );
  }
  
  // Helper method for small icons
  static Widget smallIcon(
    IconData iconData, {
    Color? color,
  }) {
    return Icon(
      iconData,
      size: sizeSmall,
      color: color,
    );
  }
  
  // Helper method for tiny icons
  static Widget tinyIcon(
    IconData iconData, {
    Color? color,
  }) {
    return Icon(
      iconData,
      size: sizeTiny,
      color: color,
    );
  }
  
  // Helper method for large icons
  static Widget largeIcon(
    IconData iconData, {
    Color? color,
  }) {
    return Icon(
      iconData,
      size: sizeLarge,
      color: color,
    );
  }
}
