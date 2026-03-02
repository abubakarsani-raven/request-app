import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_icons.dart';

/// Reusable scaffold for detail and full-screen pages. No drawer.
/// Use for request detail, trip tracking, profile, notifications, history, etc.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  AppIcons.back,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Get.back(),
                tooltip: 'Back',
              )
            : null,
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: actions ?? [],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
