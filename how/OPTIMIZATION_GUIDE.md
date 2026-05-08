## 🏗️ Architecture de Démarrage Optimisée - Guide Production

### 📊 Vue d'Ensemble du Flow

```
main() 
  ├─ Charge .env (rapide, local)
  ├─ Initialise Intl (rapide, local)
  ├─ Initialise ThemeProvider (rapide, local)
  ├─ Lance MbaymiApp (UI affichée IMMÉDIATEMENT)
  └─ AppBootstrap().initialize() EN ARRIÈRE-PLAN 🚀
      ├─ await AuthService.restoreSession() (LOCAL, bloquant)
      ├─ _wakeupBackendAsync() (PARALLÈLE, timeout 3s)
      ├─ AppInitializer.schedulePostBootstrapTasks()
      │   ├─ Météo (+ 1s)
      │   └─ Notifications (+ 2s)
      └─ UI se rafraîchit automatiquement
```

### 🎯 Principes Essentiels

| Principe | ✅ À FAIRE | ❌ À ÉVITER |
|----------|-----------|----------|
| **restoreSession()** | Appelé UNE fois au démarrage | Appelé depuis les services |
| **clearCache()** | Explicite au logout / user switch | Appelé systématiquement |
| **Appels réseau** | Async, détachés du build() | Bloquants dans initState() |
| **Dépendances auth** | Vérifiées avec guard strict | Restauration automatique |
| **Main thread** | Services dépendants en lazy | Tout précalculé au boot |

---

## 🔧 Patterns d'Utilisation

### 1️⃣ Vérifier l'authentification (dans un service)

```dart
// ❌ MAUVAIS - crée des boucles
static Future<void> badCheck() async {
  if (AuthService.currentSession == null) {
    await AuthService.restoreSession(); // ÉVITER!
  }
}

// ✅ BON - guard strict
static Future<void> goodCheck() async {
  final userId = AuthService.currentSession?.userId;
  if (userId == null) {
    throw Exception('User not authenticated');
  }
}
```

### 2️⃣ Services dépendants de l'authentification

```dart
// ✅ PATTERN: Appel avec garde
class NotificationService {
  static Future<int> getUnreadCount() async {
    // Guard strict: ne pas restaurer la session
    final userId = AuthService.currentSession?.userId;
    if (userId == null) {
      return 0; // Silencieux (acceptable pour badge)
    }
    
    // Appel réseau sûr
    final response = await http.get(url);
    // ...
  }
}
```

### 3️⃣ Initialisation lazy (dans un écran)

```dart
// ✅ Pattern: Appeler dans initState() pour les ressources
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ces appels ne bloquent pas - ils "pré-chargent"
    AppInitializer.initWeatherOnDemand();
  }
  
  @override
  Widget build(BuildContext context) {
    // ❌ N'APPELLE PAS apiCall() ici!
    return SingleChildScrollView(
      child: FutureBuilder(
        future: _fetchDashboardData(
        // ✅ FutureBuilder gère le chargement
```

### 4️⃣ Logout approprié

```dart
// ✅ Logout complet avec nettoyage
static Future<void> logout() async {
  // 1. Invalider le cache car on change d'utilisateur
  ApiService.clearCache();
  
  // 2. Réinitialiser les flags de lazy init
  AppInitializer.reset();
  
  // 3. Effacer la session en mémoire et storage
  _currentSession = null;
  await TokenStorage.clear();
  
  debugPrint('✅ AuthService.logout complete');
}
```

---

## 📋 Configuration sur HomeScreen (exemple complet)

```dart
class HomeScreen extends StatefulWidget {
  final int? userId;
  
  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    
    // ✅ NE PAS APPELER D'API LOURDS ICI
    // Les services dépendants sont chargés en arrière-plan par AppInitializer
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.isAuthenticated;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mbaymi'),
        actions: [
          // ✅ Badge qui utilise getUnreadCount() (ne bloque pas)
          if (isLoggedIn) ...[
            _buildNotificationIcon(),
          ]
        ],
      ),
      body: isLoggedIn 
          ? _buildAuthenticatedUI()  // UI complète
          : _buildGuestUI(),         // Mode lecture
    );
  }

  Widget _buildNotificationIcon() {
    return FutureBuilder<int>(
      future: NotificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Navigate to notifications
              },
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Badge(
                  label: Text('$count'),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

---

## 🚨 Checklist d'Erreurs à Éviter

- [ ] ❌ **Jamais** d'appel réseau dans `build()`
- [ ] ❌ **Jamais** d'appel `restoreSession()` depuis les services
- [ ] ❌ **Jamais** d'appel réseau bloquant avant `runApp()`
- [ ] ❌ **Jamais** de `clearCache()` systématique
- [ ] ❌ **Pas** d'appel de service auth-dépendant sans vérification d'auth
- [ ] ❌ **Pas** de `FutureBuilder` imbriqués (lance 10+ appels)
- [ ] ❌ **Pas** d'appel à la météo si utilisateur non authentifié
- [ ] ❌ **Pas** de polling (actualisation répétée via timer) sans limite

### Checklist de Production

- [ ] ✅ `AuthService.restoreSession()` appelé UNE seule fois
- [ ] ✅ `ApiService.clearCache()` appelé UNIQUEMENT au logout
- [ ] ✅ Backend wakeup timeout `≤ 3s` (non-bloquant)
- [ ] ✅ Services lazy-initialisés après bootstrap
- [ ] ✅ Tous les services ont des **guards d'authentification**
- [ ] ✅ Tests: aucun crash au démarrage sans réseau
- [ ] ✅ Tests: UI responsive même si backend timeout
- [ ] ✅ Tests: pas de "skipped frames" au démarrage

---

## 📝 Points de Personnalisation

### Ajouter un nouveau service dépendant de l'auth

```dart
// Dans app_initializer.dart, ajoutez:

static bool _myServiceInitialized = false;

static void _scheduleMyServicePreload() {
  Future.delayed(const Duration(seconds: 3), () async {
    if (_myServiceInitialized) return;
    
    try {
      debugPrint('🔄 Pre-loading my service...');
      // await MyService.initializeData();
      _myServiceInitialized = true;
      debugPrint('✅ My service pre-loaded');
    } catch (e) {
      debugPrint('⚠️ My service pre-load failed: $e');
    }
  });
}
```

### Modifier les délais de pré-chargement

```dart
// app_initializer.dart → schedulePostBootstrapTasks()

// Exemple: pré-charger plus tôt (immédiat)
Future.delayed(Duration.zero, () async {
  // Très important
});

// Exemple: pré-charger plus tard (5s)
Future.delayed(const Duration(seconds: 5), () async {
  // Moins important
});
```

---

## 🔍 Débugage

### Logs à surveiller

```
🚀 AppBootstrap.initialize() STARTING
📍 Step 1/2: AuthService.restoreSession()...
✅ Auth restored: true (userId=123)
📍 Step 2/2: _wakeupBackendAsync()...
✅ AppBootstrap COMPLETE (450ms)
🎬 AppInitializer scheduling post-bootstrap tasks...
🔄 Pre-loading weather data...
✅ Weather pre-loaded
```

### Si vous avez encore des "skipped frames"

1. **Vérifier les appels réseau**: `grep -r "http.get\|http.post" lib/screens/`
   - Chercher les appels dans `build()` ou `initState()`

2. **Vérifier les FutureBuilders imbriqués**: 
   - Remplacer par Provider (meilleure gestion)

3. **Vérifier les animations/transitions**:
   - Utiliser `SingleChildScrollView` avec `clipBehavior`

4. **Profiler**: 
   ```dart
   flutter run --profile
   // Devtools → Performance → Slow Frames
   ```

---

## ✅ Résumé

Votre app aura maintenant:

- ✅ UI visible en **< 100ms**
- ✅ Auth restaurée en **< 500ms**
- ✅ Services chargés en **arrière-plan**
- ✅ Zéro appel réseau bloquant
- ✅ Zéro crash au démarrage
- ✅ UX fluide même en froid
