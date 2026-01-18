# 🛠️ FLUTTER WEB - READY-TO-USE FIXES

## Fix #1: Dialog Width Constraint

### BEFORE (❌ Bad)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Edit'),
    content: Form(...),
  ),
)
```

### AFTER (✅ Good)
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: AlertDialog(
        title: Text('Edit'),
        content: Form(...),
      ),
    ),
  ),
)
```

---

## Fix #2: ModalBottomSheet with Proper Constraints

### BEFORE (❌ Bad)
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => SingleChildScrollView(
    child: Form(
      // Form fields
    ),
  ),
)
```

### AFTER (✅ Good)
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // ✅ CRITICAL
  builder: (context) => ConstrainedBox(  // ✅ Add max height
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,  // ✅ Keyboard padding
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        // Form fields
      ),
    ),
  ),
)
```

---

## Fix #3: Responsive Image Height

### BEFORE (❌ Bad)
```dart
Container(
  width: double.infinity,
  height: 350,  // Fixed
  child: Image.network(url, fit: BoxFit.cover),
)
```

### AFTER (✅ Good)
```dart
Container(
  width: double.infinity,
  height: MediaQuery.of(context).size.width * 0.5,  // Responsive ratio
  constraints: const BoxConstraints(
    minHeight: 200,
    maxHeight: 400,
  ),
  child: Image.network(url, fit: BoxFit.cover),
)
```

### Or Using AspectRatio (Simplest)
```dart
AspectRatio(
  aspectRatio: 16 / 9,  // 16:9 is common
  child: Image.network(url, fit: BoxFit.cover),
)
```

---

## Fix #4: FAB Bottom Padding

### BEFORE (❌ Bad)
```dart
Scaffold(
  floatingActionButton: FloatingActionButton.extended(
    onPressed: _add,
    label: Text('Ajouter'),
  ),
  body: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => ItemCard(),
  ),
)
```

### AFTER (✅ Good)
```dart
Scaffold(
  floatingActionButton: FloatingActionButton.extended(
    onPressed: _add,
    label: Text('Ajouter'),
  ),
  body: ListView.builder(
    padding: const EdgeInsets.only(bottom: 80),  // ✅ FAB height + margin
    itemCount: items.length,
    itemBuilder: (context, i) => ItemCard(),
  ),
)
```

---

## Fix #5: Edit Dialog (Full Example)

### BEFORE (❌ Bad)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Éditer'),
    content: Column(
      children: [
        TextField(controller: nameCtrl),
        TextField(controller: descCtrl),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
      ElevatedButton(onPressed: _save, child: Text('Sauvegarder')),
    ],
  ),
)
```

### AFTER (✅ Good - Full responsive)
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(16),  // Space around dialog
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: AlertDialog(
        title: Text('Éditer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _save,
            child: Text('Sauvegarder'),
          ),
        ],
      ),
    ),
  ),
)
```

---

## Fix #6: Nested ListView (Already Correct Pattern)

### CORRECT (✅ Already used in codebase)
```dart
ListView(  // Outer scrollable
  children: [
    ListTile(...),
    ListTile(...),
    
    // Nested list (non-scrollable)
    ListView.builder(
      shrinkWrap: true,  // ✅ REQUIRED
      physics: const NeverScrollableScrollPhysics(),  // ✅ REQUIRED
      itemCount: subItems.length,
      itemBuilder: (context, i) => SubItem(),
    ),
    
    ListTile(...),
  ],
)
```

**Note**: This pattern is already correctly used in your codebase. ✅

---

## Fix #7: Form Screen Template (Complete)

### CORRECT Template for all form screens
```dart
class MyFormScreen extends StatefulWidget {
  const MyFormScreen({Key? key}) : super(key: key);

  @override
  State<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,  // ✅ REQUIRED
      appBar: AppBar(title: const Text('Mon Formulaire')),
      body: SafeArea(
        bottom: false,  // ✅ Allow scroll behind keyboard
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomInset + 16,  // ✅ Dynamic keyboard padding
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  decoration: InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Save
                    }
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 Quick Checklist

When implementing fixes:

- [ ] Dialog: Wrapped with `Dialog(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 400)))`
- [ ] ModalBottomSheet: Has `isScrollControlled: true`
- [ ] ModalBottomSheet: Has `maxHeight` constraint
- [ ] ModalBottomSheet: Has keyboard padding
- [ ] Image: Has responsive height (not fixed pixel value)
- [ ] ListView with FAB: Has bottom padding
- [ ] Form screens: Has `resizeToAvoidBottomInset: true`
- [ ] Form screens: Has `SafeArea(bottom: false)`
- [ ] Nested ListView: Has `NeverScrollableScrollPhysics()`

---

## 📊 Files to Update

Priority order (by impact):

1. **parcel_inputs_screen.dart** - Multiple Dialogs + ModalBottomSheets
2. **parcel_finance_screen.dart** - Multiple Dialogs + ModalBottomSheets
3. **parcel_reminders_screen.dart** - Multiple Dialogs + ModalBottomSheets
4. **activity_screen.dart** - Multiple Dialogs
5. **market_screen.dart** - Dialog + Images
6. **crop_problems_screen.dart** - ModalBottomSheet + FAB
7. **post_detail_screen.dart** - Images + BottomSheet
8. **farm_screen.dart** - Images + Lists
9. **edit_farm_screen.dart** - Form (verify implementation)

---
