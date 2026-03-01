import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import '../../../core/config/request_module_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'request_card.dart';
import 'status_badge.dart';
import '../pages/request_detail_page.dart';

/// Single card for any request type. Uses [RequestModuleConfig] for label, icon,
/// and navigation so new modules only need a config entry.
class UnifiedRequestCard extends StatelessWidget {
  final RequestType type;
  final dynamic request;
  final RequestDetailSource? source;
  final VoidCallback? onReturn;
  /// When set (e.g. from My Requests), shows a "Repeat Request" button for ICT/Store.
  final VoidCallback? onRepeat;

  const UnifiedRequestCard({
    Key? key,
    required this.type,
    required this.request,
    this.source,
    this.onReturn,
    this.onRepeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Vehicle keeps the richer RequestCard (expand, destination, repeat)
    if (type == RequestType.vehicle && request is VehicleRequestModel) {
      return RequestCard(
        request: request as VehicleRequestModel,
        source: source,
        onTap: () => RequestModuleConfig.navigateToDetail(
          type,
          (request as VehicleRequestModel).id,
          source: source,
          onReturn: onReturn,
        ),
      );
    }

    return _GenericRequestCard(
      type: type,
      request: request,
      source: source,
      onReturn: onReturn,
      onRepeat: onRepeat,
    );
  }
}

class _GenericRequestCard extends StatelessWidget {
  final RequestType type;
  final dynamic request;
  final RequestDetailSource? source;
  final VoidCallback? onReturn;
  final VoidCallback? onRepeat;

  const _GenericRequestCard({
    Key? key,
    required this.type,
    required this.request,
    this.source,
    this.onReturn,
    this.onRepeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = RequestModuleConfig.getTitle(type, request);
    final subtitle = RequestModuleConfig.getSubtitle(type, request);
    final status = RequestModuleConfig.getStatus(type, request);
    final workflowStage = RequestModuleConfig.getWorkflowStage(type, request);
    final createdAt = RequestModuleConfig.getCreatedAt(type, request);
    final partiallyFulfilled = RequestModuleConfig.isPartiallyFulfilled(type, request);
    final requestId = (request as dynamic).id as String;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => RequestModuleConfig.navigateToDetail(
          type,
          requestId,
          source: source,
          onReturn: onReturn,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primaryLight : AppColors.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      RequestModuleConfig.icon(type),
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      size: AppIcons.sizeSmall,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          status: status,
                          workflowStage: workflowStage,
                          isPartiallyFulfilled: partiallyFulfilled,
                        ),
                      ],
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              if (onRepeat != null) ...[
                const SizedBox(height: AppConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRepeat,
                    icon: Icon(
                      Icons.repeat,
                      size: 18,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    label: Text(
                      'Repeat Request',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
