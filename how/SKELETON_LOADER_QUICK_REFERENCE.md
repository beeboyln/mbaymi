# 🦴 Skeleton Loader - Quick Reference Guide

## Quick Start

### Import
```dart
import 'package:mbaymi/widgets/skeleton_loader.dart';
```

---

## Components & Usage

### 1. Basic Skeleton (Single Placeholder)
```dart
SkeletonLoader(
  width: 200,
  height: 16,
  borderRadius: BorderRadius.circular(4),
)
```

### 2. Card Skeleton
```dart
SkeletonCardLoader(
  isDarkMode: isDarkMode,
  lineCount: 3,
  padding: AppSpacing.md,
)
```

### 3. List Skeleton (Most Common)
```dart
SkeletonListLoader(
  itemCount: 5,
  isDarkMode: isDarkMode,
  itemHeight: 120,
  itemPadding: const EdgeInsets.only(bottom: AppSpacing.md),
)
```

### 4. Full Page Skeleton
```dart
SkeletonPageLoader(
  isDarkMode: isDarkMode,
  includeAppBar: true,
  cardCount: 4,
)
```

### 5. Grid Skeleton
```dart
SkeletonGridLoader(
  crossAxisCount: 2,
  itemCount: 6,
  isDarkMode: isDarkMode,
  padding: const EdgeInsets.all(AppSpacing.md),
)
```

### 6. Avatar/Circle Skeleton
```dart
SkeletonAvatarLoader(
  size: 64,
  isDarkMode: isDarkMode,
)
```

### 7. Image Skeleton
```dart
SkeletonImageLoader(
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(12),
  isDarkMode: isDarkMode,
)
```

### 8. Table Skeleton
```dart
SkeletonTableLoader(
  rowCount: 5,
  columnCount: 3,
  isDarkMode: isDarkMode,
)
```

---

## Real-World Examples

### Example 1: Replace Loading in FutureBuilder
```dart
FutureBuilder<List<dynamic>>(
  future: _livestockFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // ✨ Replace this:
      // return const Center(
      //   child: CircularProgressIndicator(),
      // );
      
      // With this:
      return SkeletonListLoader(
        itemCount: 5,
        isDarkMode: isDarkMode,
        itemHeight: 120,
      );
    }
    
    // ... rest of builder
  },
)
```

### Example 2: Full Page Loading
```dart
@override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Scaffold(
    body: FutureBuilder<VeterinarianProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonPageLoader(
            isDarkMode: isDarkMode,
            includeAppBar: true,
            cardCount: 4,
          );
        }
        
        // ... build actual content
      },
    ),
  );
}
```

### Example 3: Nested Skeleton (List with Items)
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return SkeletonListLoader(
    itemCount: 3,
    isDarkMode: isDarkMode,
    itemHeight: 150,
    padding: const EdgeInsets.all(16),
  );
}
```

---

## Customization

### Adjust Item Count
```dart
SkeletonListLoader(
  itemCount: 10,  // Show 10 skeleton cards
  isDarkMode: isDarkMode,
)
```

### Adjust Height
```dart
SkeletonListLoader(
  itemHeight: 200,  // Taller items
  isDarkMode: isDarkMode,
)
```

### Adjust Spacing
```dart
SkeletonListLoader(
  itemPadding: const EdgeInsets.only(bottom: 24),  // More space
  isDarkMode: isDarkMode,
)
```

### Grid with Custom Columns
```dart
SkeletonGridLoader(
  crossAxisCount: 3,  // 3 columns instead of 2
  itemCount: 9,
  isDarkMode: isDarkMode,
)
```

---

## Dark/Light Mode

All skeletons automatically detect theme:

```dart
// Auto-detects from Theme.of(context)
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

SkeletonListLoader(
  isDarkMode: isDarkMode,
  // ... other params
)
```

---

## Animation Details

- **Duration:** 1500ms (smooth, not too fast)
- **Curve:** EaseInOut
- **Effect:** Shimmer (gradient moving left-to-right)
- **Auto-starts:** Yes, loops continuously
- **Performance:** Optimized, single ticker per widget

---

## Common Patterns

### Pattern A: List of Items
```dart
SkeletonListLoader(
  itemCount: 5,
  isDarkMode: isDarkMode,
)
```

### Pattern B: Single Page
```dart
SkeletonPageLoader(
  isDarkMode: isDarkMode,
  cardCount: 3,
)
```

### Pattern C: Grid Display
```dart
SkeletonGridLoader(
  crossAxisCount: 2,
  itemCount: 6,
  isDarkMode: isDarkMode,
)
```

---

## Tips & Tricks

### 1. Match Content Structure
```dart
// If final list has 10 items, show 5-6 skeletons
SkeletonListLoader(
  itemCount: 6,  // ✅ Good preview
  isDarkMode: isDarkMode,
)
```

### 2. Use Realistic Heights
```dart
// Make skeleton height match actual card height
SkeletonListLoader(
  itemHeight: 120,  // Matches your card height
  isDarkMode: isDarkMode,
)
```

### 3. Include AppBar in Skeleton
```dart
// If your page has AppBar, show it in skeleton
SkeletonPageLoader(
  isDarkMode: isDarkMode,
  includeAppBar: true,  // ✅ Shows top structure
  cardCount: 4,
)
```

### 4. Proper Padding
```dart
// Maintain consistency with actual layout
SkeletonListLoader(
  padding: const EdgeInsets.all(16),
  itemPadding: const EdgeInsets.only(bottom: 16),
  isDarkMode: isDarkMode,
)
```

---

## Troubleshooting

### Issue: Skeleton not showing
**Solution:** Make sure `isDarkMode` parameter is passed correctly
```dart
// ✅ Correct
SkeletonListLoader(
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

### Issue: Wrong height
**Solution:** Adjust `itemHeight` parameter
```dart
// ✅ Match your actual card height
SkeletonListLoader(
  itemHeight: 150,  // Increase if cards are bigger
  isDarkMode: isDarkMode,
)
```

### Issue: Layout shift when loading completes
**Solution:** Skeleton height should match actual content height
```dart
// Before: Card is 100px
// Skeleton: itemHeight: 100
// Result: ✅ No shift
```

---

## Migration Checklist

When updating a screen:

- [ ] Add import: `import 'package:mbaymi/widgets/skeleton_loader.dart';`
- [ ] Find `if (snapshot.connectionState == ConnectionState.waiting)`
- [ ] Replace `CircularProgressIndicator` with appropriate skeleton
- [ ] Set `isDarkMode` parameter correctly
- [ ] Match item count to realistic preview
- [ ] Match height to actual content
- [ ] Test on both light and dark themes
- [ ] Verify no layout shift on load completion

---

## Performance Notes

✅ **Optimized For:**
- Low memory footprint
- Smooth 60fps animation
- Single ticker (efficient)
- Proper disposal

❌ **Avoid:**
- Multiple skeletons with separate animations
- Using in lists with 100+ items (may be slow)
- Very rapid state changes

---

## Summary

Replace spinners with skeletons for:
- ✨ Better UX
- 🚀 Professional feel
- ⚡ Perceived faster loading
- 🎨 Consistent design

**One import. Multiple components. Better experience.**

---

## Need Help?

See the examples in these screens:
- `livestock_management_screen.dart`
- `social_feed_screen.dart`
- `veterinarian_profile_screen.dart`
- `farm_profile_screen.dart`

Or check the full implementation in:
- `lib/widgets/skeleton_loader.dart`
