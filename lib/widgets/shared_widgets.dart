import 'package:flutter/material.dart';

/// A shared preloader widget that provides a consistent loading experience across the app
class SharedPreloader extends StatelessWidget {
  final String? message;
  final double size;
  final bool useScaffold;
  final Color? color;

  const SharedPreloader({
    super.key,
    this.message,
    this.size = 40.0,
    this.useScaffold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColor = color ?? theme.colorScheme.primary;
    
    Widget loadingWidget = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(customColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(179),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (useScaffold) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(child: loadingWidget),
      );
    }
    
    return loadingWidget;
  }
}

/// A widget to enable pull-to-refresh on any screen
class ResponsiveRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? refreshIndicatorColor;
  
  const ResponsiveRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshIndicatorColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = refreshIndicatorColor ?? theme.colorScheme.primary;
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      child: child,
    );
  }
} 