import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import '../../../core/theme/app_colors.dart';

class SidebarLayout extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const SidebarLayout({
    Key? key,
    required this.child,
    this.title,
    this.actions,
  }) : super(key: key);

  @override
  State<SidebarLayout> createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends State<SidebarLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Persistent Sidebar
          AppSidebar(
            isCollapsed: _isSidebarCollapsed,
            onCollapseChanged: (collapsed) {
              setState(() {
                _isSidebarCollapsed = collapsed;
              });
            },
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header Bar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.surfaceLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.title != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.title!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
                // Page Content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.backgroundGradient,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

