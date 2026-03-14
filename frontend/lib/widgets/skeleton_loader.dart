import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';

/// Skeleton loading widget for smooth content transitions
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment(-1 + _animation.value, 0),
              end: Alignment(-0.5 + _animation.value, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0, 0.5, 1],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading card with multiple lines
class SkeletonCardLoader extends StatelessWidget {
  final bool isDarkMode;
  final int lineCount;
  final double lineSpacing;
  final Widget? header;
  final double padding;

  const SkeletonCardLoader({
    super.key,
    required this.isDarkMode,
    this.lineCount = 3,
    this.lineSpacing = AppSpacing.sm,
    this.header,
    this.padding = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.getCardBgColor(isDarkMode);
    final borderColor = AppColors.getBorderColor(isDarkMode);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          if (header != null) ...[
            header!,
            SizedBox(height: lineSpacing * 2),
          ] else ...[
            SkeletonLoader(height: 20, width: 150, borderRadius: BorderRadius.circular(4)),
            SizedBox(height: lineSpacing * 2),
          ],
          // Content skeleton lines
          ...List.generate(
            lineCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < lineCount - 1 ? lineSpacing : 0),
              child: SkeletonLoader(
                height: 12,
                borderRadius: BorderRadius.circular(4),
                width: index == lineCount - 1 ? 0.7 : 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading list
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final bool isDarkMode;
  final double itemHeight;
  final EdgeInsets padding;
  final EdgeInsets itemPadding;
  final bool isShimmer;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    required this.isDarkMode,
    this.itemHeight = 100,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.itemPadding = const EdgeInsets.only(bottom: AppSpacing.md),
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: itemPadding,
              child: SkeletonCardLoader(
                isDarkMode: isDarkMode,
                lineCount: 2,
                lineSpacing: AppSpacing.sm,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading for avatar/profile image
class SkeletonAvatarLoader extends StatelessWidget {
  final double size;
  final bool isDarkMode;

  const SkeletonAvatarLoader({
    super.key,
    this.size = 64,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      isCircle: true,
    );
  }
}

/// Skeleton loading for image placeholders
class SkeletonImageLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool isDarkMode;

  const SkeletonImageLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Simple centered loading spinner (replaces complex SkeletonPageLoader)
class SimplePageLoader extends StatelessWidget {
  final bool isDarkMode;
  final Color? backgroundColor;

  const SimplePageLoader({
    super.key,
    required this.isDarkMode,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.getBgColor(isDarkMode);
    
    return Container(
      color: bgColor,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Complex skeleton for full page loading
class SkeletonPageLoader extends StatelessWidget {
  final bool isDarkMode;
  final bool includeAppBar;
  final int cardCount;
  final Color? backgroundColor;

  const SkeletonPageLoader({
    super.key,
    required this.isDarkMode,
    this.includeAppBar = true,
    this.cardCount = 3,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Redirects to SimplePageLoader - SkeletonPageLoader is deprecated
    return SimplePageLoader(isDarkMode: isDarkMode, backgroundColor: backgroundColor);
  }
}

/// Skeleton for table/grid items
class SkeletonGridLoader extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final bool isDarkMode;
  final EdgeInsets padding;

  const SkeletonGridLoader({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    required this.isDarkMode,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => SkeletonCardLoader(
            isDarkMode: isDarkMode,
            lineCount: 2,
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading for table rows
class SkeletonTableLoader extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final bool isDarkMode;

  const SkeletonTableLoader({
    super.key,
    this.rowCount = 5,
    this.columnCount = 3,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: List.generate(
            rowCount,
            (rowIndex) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: List.generate(
                  columnCount,
                  (colIndex) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: colIndex < columnCount - 1 ? AppSpacing.md : 0,
                      ),
                      child: SkeletonLoader(
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
