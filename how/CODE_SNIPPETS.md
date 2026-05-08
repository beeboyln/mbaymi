# ⚡ COPY-PASTE READY CODE - Quick Reference

> Tous les codes prêts à utiliser - copier/coller directement dans vos écrans

---

## 1️⃣ IMPORTS RAPIDES

### Ajouter au top de ton écran:
```dart
// Validation & Error UI
import 'package:mbaymi/utils/validators.dart';
import 'package:mbaymi/utils/ui_error_handler.dart';

// Image Optimization
import 'package:mbaymi/utils/image_optimizer.dart';

// Services
import 'package:mbaymi/services/api_service.dart';
```

---

## 2️⃣ VALIDATION - Copy/Paste Validators

### Email
```dart
TextFormField(
  controller: emailController,
  validator: FormValidator.validateEmail,
  keyboardType: TextInputType.emailAddress,
  decoration: InputDecoration(labelText: 'Email'),
)
```

### Password
```dart
TextFormField(
  controller: passwordController,
  validator: FormValidator.validatePassword,
  obscureText: true,
  decoration: InputDecoration(labelText: 'Mot de passe'),
)
```

### Password Confirmation
```dart
TextFormField(
  controller: confirmPasswordController,
  validator: (value) => FormValidator.validatePasswordConfirmation(
    value,
    passwordController.text,
  ),
  obscureText: true,
  decoration: InputDecoration(labelText: 'Confirmer'),
)
```

### Name
```dart
TextFormField(
  controller: nameController,
  validator: FormValidator.validateName,
  decoration: InputDecoration(labelText: 'Nom'),
)
```

### Phone
```dart
TextFormField(
  controller: phoneController,
  validator: FormValidator.validatePhone,
  keyboardType: TextInputType.phone,
  decoration: InputDecoration(labelText: 'Téléphone'),
)
```

### Farm Name
```dart
TextFormField(
  controller: farmNameController,
  validator: FormValidator.validateFarmName,
  decoration: InputDecoration(labelText: 'Nom de la ferme'),
)
```

### Size (Hectares)
```dart
TextFormField(
  controller: sizeController,
  validator: FormValidator.validateSize,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(labelText: 'Superficie (ha)'),
)
```

---

## 3️⃣ ERROR HANDLING - Copy/Paste Error Management

### Basic Try/Catch with UI Feedback
```dart
try {
  await ApiService.login(email, password);
  UiErrorHandler.showSuccess(context, 'Connexion réussie!');
  Navigator.pop(context);
} catch (e) {
  final msg = ErrorMessages.getHumanReadableError(e);
  UiErrorHandler.showError(context, msg);
}
```

### With Loading State
```dart
setState(() => _isLoading = true);
try {
  await ApiService.createFarm(farmData);
  UiErrorHandler.showSuccess(context, 'Ferme créée!');
  Navigator.pop(context);
} catch (e) {
  final msg = ErrorMessages.getHumanReadableError(e);
  UiErrorHandler.showError(context, msg);
} finally {
  setState(() => _isLoading = false);
}
```

### Show Error Dialog (Critical Errors)
```dart
UiErrorHandler.showErrorDialog(
  context,
  title: 'Erreur',
  message: 'Une erreur critique s\'est produite',
  buttonText: 'OK',
);
```

### Show Confirmation Dialog
```dart
final confirmed = await UiErrorHandler.showConfirmDialog(
  context,
  title: 'Supprimer?',
  message: 'Cette action ne peut pas être annulée',
  confirmText: 'Supprimer',
  cancelText: 'Annuler',
  isDangerous: true,
);

if (confirmed == true) {
  // Proceed with deletion
}
```

---

## 4️⃣ LOADING STATES - Copy/Paste Loading UI

### Loading Overlay (Full Screen)
```dart
LoadingOverlay(
  isLoading: _isLoading,
  message: 'Chargement en cours...',
  child: YourWidget(),
)
```

### In Scaffold Body
```dart
Scaffold(
  appBar: AppBar(title: Text('Ma Page')),
  body: LoadingOverlay(
    isLoading: _isLoading,
    message: 'Création de la ferme...',
    child: SingleChildScrollView(
      child: Column(...),
    ),
  ),
)
```

### Connectivity Banner (Offline Detection)
```dart
Column(
  children: [
    ConnectivityBanner(
      isOnline: _isOnline,
    ),
    Expanded(child: YourContent()),
  ],
)
```

### Empty State Widget
```dart
EmptyStateWidget(
  title: 'Aucune ferme',
  message: 'Créez votre première ferme',
  icon: Icons.agriculture,
  onRetry: () => setState(() {
    // Reload data
  }),
)
```

---

## 5️⃣ IMAGES - Copy/Paste Image Optimization

### Simple Network Image
```dart
ImageOptimizer.buildNetworkImage(
  imageUrl: farm.photoUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

### With Placeholder
```dart
ImageOptimizer.buildNetworkImage(
  imageUrl: farm.photoUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  placeholder: 'assets/images/placeholder.png',
)
```

### Avatar Circular
```dart
ImageOptimizer.buildCircleAvatar(
  imageUrl: user.profilePhoto,
  radius: 32,
  initials: user.name[0],
  backgroundColor: Colors.green,
)
```

### OptimizedImage Widget (Reusable)
```dart
OptimizedImage(
  imageUrl: imageUrl,
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)
```

### Precache Important Images
```dart
@override
void initState() {
  super.initState();
  ImageOptimizer.precacheImage(context, farm.photoUrl);
}
```

### Clear Image Cache (After Deletion)
```dart
ImageOptimizer.clearImageCache();
```

---

## 6️⃣ CACHING - Copy/Paste Cache Management

### Use Cache Automatically (in API Service)
```dart
// This is already done, just use:
final farms = await ApiService.getUserFarms(userId);
// → First call: API hit
// → 2nd call within 5 min: Cache hit (logs show 🟢 Cache HIT)
```

### Invalidate Cache After Mutation
```dart
try {
  await ApiService.createFarm(data);
  ApiService.invalidateCache("farms/$userId");  // ← Clear cache
  UiErrorHandler.showSuccess(context, 'Créé!');
} catch (e) {
  // Error handling
}
```

### Clear All Cache
```dart
ApiService.clearCache();  // Full cache clear
```

---

## 7️⃣ CONNECTIVITY - Copy/Paste Offline Handling

### Check if Online
```dart
final isOnline = ConnectivityService().isOnline;

if (!isOnline) {
  UiErrorHandler.showError(context, 'Mode hors ligne');
  return;  // Disable POST/PUT/DELETE
}
```

### Show Offline Banner
```dart
StreamBuilder<bool>(
  stream: ConnectivityService().onConnectivityChanged,
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? true;
    return ConnectivityBanner(isOnline: isOnline);
  },
)
```

### Disable Mutations When Offline
```dart
ElevatedButton(
  onPressed: _isOnline ? _handleCreate : null,  // Disabled if offline
  child: Text('Créer'),
)
```

---

## 8️⃣ COMPLETE LOGIN SCREEN EXAMPLE

```dart
import 'package:flutter/material.dart';
import 'package:mbaymi/utils/validators.dart';
import 'package:mbaymi/utils/ui_error_handler.dart';
import 'package:mbaymi/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      UiErrorHandler.showSuccess(context, 'Bienvenue!');
      await Future.delayed(Duration(milliseconds: 800));
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorMessages.getHumanReadableError(e);
      UiErrorHandler.showError(context, msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Connexion...',
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    validator: FormValidator.validateEmail,
                    autofocus: false,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    validator: FormValidator.validatePassword,
                    autofocus: false,
                    enabled: !_isLoading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          )
                        : Text('Connexion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 NEXT STEPS

1. **Copy one section above** (e.g., Email validation)
2. **Paste into your screen** (e.g., login_screen.dart)
3. **Test that it compiles** → `flutter pub get && flutter run`
4. **Test the feature** (e.g., enter invalid email, should show error)
5. **Move to next screen** and repeat

**Total time to integration**: 30 min - 2 hours depending on how many screens

Good luck! 🚀

