import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../app/presentation/controllers/notification_controller.dart';
import '../app/presentation/widgets/app_drawer.dart';
import '../app/presentation/widgets/skeleton_loader.dart';
import '../app/presentation/pages/request_detail_page.dart';
import '../app/data/models/notification_model.dart';
import '../app/data/models/request_model.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> 
    with SingleTickerProviderStateMixin {
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Setup pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Refresh notifications when screen opens - load ALL notifications, not just unread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationController = Get.find<NotificationController>();
      notificationController.loadNotifications(unreadOnly: false);
      notificationController.loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Notifications'),
          actions: [
            Obx(() {
              final unreadCount = notificationController.unreadCount.value;
              if (unreadCount == 0) return const SizedBox();
              return TextButton.icon(
                onPressed: () => notificationController.markAllAsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              );
            }),
          ],
        ),
      body: Obx(
        () {
          if (notificationController.isLoading.value) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonListTile(),
            );
          }

          if (notificationController.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notificationController.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationController.notifications[index];
              final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
              
              IconData getNotificationIcon() {
                switch (notification.type) {
                  case NotificationType.requestSubmitted:
                    return Icons.send;
                  case NotificationType.approvalRequired:
                    return Icons.pending_actions;
                  case NotificationType.requestApproved:
                    return Icons.check_circle;
                  case NotificationType.requestRejected:
                    return Icons.cancel;
                  case NotificationType.requestAssigned:
                    return Icons.assignment;
                  case NotificationType.requestFulfilled:
                    return Icons.check_circle_outline;
                  case NotificationType.requestCorrection:
                    return Icons.edit;
                  case NotificationType.tripStarted:
                    return Icons.play_arrow;
                  case NotificationType.tripCompleted:
                    return Icons.done_all;
                  case NotificationType.vehicleAssigned:
                    return Icons.directions_car;
                  case NotificationType.driverAssigned:
                    return Icons.person;
                  default:
                    return Icons.notifications;
                }
              }

              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              
              Color getNotificationColor() {
                if (notification.isRead) {
                  return isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary;
                }
                switch (notification.type) {
                  case NotificationType.requestSubmitted:
                    return AppColors.info;
                  case NotificationType.approvalRequired:
                    return AppColors.warning;
                  case NotificationType.requestApproved:
                  case NotificationType.requestFulfilled:
                  case NotificationType.tripCompleted:
                    return AppColors.success;
                  case NotificationType.requestRejected:
                    return AppColors.error;
                  case NotificationType.requestCorrection:
                    return AppColors.warning;
                  default:
                    return theme.colorScheme.primary;
                }
              }
              
              return InkWell(
                onTap: () {
                  // Mark as read
                  if (!notification.isRead) {
                    notificationController.markAsRead(notification.id);
                  }
                  
                  // Navigate to request if available
                  if (notification.requestId != null && 
                      notification.requestType == RequestType.vehicle) {
                    Get.to(() => RequestDetailPage(requestId: notification.requestId!));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notification.isRead 
                        ? (isDark 
                            ? AppColors.darkSurface 
                            : theme.colorScheme.surface)
                        : (isDark 
                            ? AppColors.darkSurfaceLight.withOpacity(0.5)
                            : AppColors.primary.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: notification.isRead
                          ? (isDark 
                              ? AppColors.darkBorderDefined.withOpacity(0.5)
                              : AppColors.border.withOpacity(0.3))
                          : (isDark 
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.primary.withOpacity(0.3)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? (isDark 
                                  ? AppColors.darkSurfaceLight.withOpacity(0.3)
                                  : getNotificationColor().withOpacity(0.1))
                              : getNotificationColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getNotificationIcon(),
                          color: getNotificationColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      fontSize: 15,
                                      color: notification.isRead
                                          ? (isDark 
                                              ? AppColors.darkTextPrimary 
                                              : AppColors.textPrimary)
                                          : (isDark 
                                              ? AppColors.darkTextPrimary 
                                              : AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  _buildAnimatedUnreadIndicator(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: notification.isRead
                                    ? (isDark 
                                        ? AppColors.darkTextSecondary 
                                        : AppColors.textSecondary)
                                    : (isDark 
                                        ? AppColors.darkTextPrimary.withOpacity(0.8)
                                        : AppColors.textPrimary),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFormat.format(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark 
                                    ? AppColors.darkTextDisabled 
                                    : AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildAnimatedUnreadIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5 * _pulseAnimation.value),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

