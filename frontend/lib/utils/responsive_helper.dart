import 'package:flutter/material.dart';

/// Responsive wrapper that constrains max width on tablets/large screens
/// Returns the child directly on phones, wraps in Center/SizedBox on tablets
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({
    Key? key,
    required this.child,
    this.maxWidth = 600,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On small screens (< maxWidth), show child directly
    if (screenWidth < maxWidth) {
      return child;
    }

    // On larger screens, center and constrain width
    return Center(
      child: SizedBox(
        width: maxWidth,
        child: child,
      ),
    );
  }
}

/// Checks if current screen is considered a tablet
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

/// Get responsive padding based on screen size
EdgeInsets getResponsivePadding(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 600) {
    return const EdgeInsets.symmetric(horizontal: 16);
  } else if (screenWidth < 900) {
    return const EdgeInsets.symmetric(horizontal: 32);
  } else {
    return const EdgeInsets.symmetric(horizontal: 48);
  }
}
