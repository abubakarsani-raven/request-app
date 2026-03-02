import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';

/// A single bottom nav item.
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Role-aware bottom navigation bar. Receives pre-built items from MainShellPage.
/// Active item: primary color + label; inactive: grey. Safe area bottom.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingS,
            vertical: AppConstants.spacingXS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              final icon = isSelected
                  ? (item.activeIcon ?? item.icon)
                  : item.icon;
              final color = isSelected ? primary : onSurfaceVariant;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingS,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: AppIcons.sizeDefault,
                            color: color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
