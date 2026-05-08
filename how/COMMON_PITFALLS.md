## 🎯 Erreurs Courantes et Solutions

### Erreur #1: "restoreSession() appelé en boucle"

**Symptômes**:
```
AuthService.restoreSession called multiple times
Skipped 100 frames
UI freeze on startup
```

**Cause racine**:
```dart
// ❌ MAUVAIS - dans NotificationService
if (AuthService.currentSession == null) {
  await AuthService.restoreSession(); // Boucle potentielle!
}
```

**Solution**:
```dart
// ✅ BON - vérification stricte sans restauration
final userId = AuthService.currentSession?.userId;
if (userId == null) {
  return 0; // Ou throw Exception plutôt que restaurer
}
```

---

### Erreur #2: "clearCache() exécuté plusieurs fois"

**Symptômes**:
```
Cleared all cache (5 fois!)
Cache performance drops
Data not consistent
```

**Cause racine**:
```dart
// ❌ MAUVAIS:
// login() → ApiService.clearCache() ✓
// restoreSession() → ApiService.clearCache() ✓ (redondant!)
// logout() → ApiService.clearCache() ✓
// Chaque changement d'état → clearCache() ✗ (trop!)
```

**Solution**:
```dart
// ✅ BON:
// 1. logout() → ApiService.clearCache() (utilisateur change, données obsolètes)
// 2. login(userId != previousUserId) → ApiService.clearCache() (user switch)
// 3. restoreSession() → SKIP clearCache() (données locales, pas de changement)
// 4. Invalidation ciblée: ApiService.invalidateCache(key) (pour des clés spécifiques)
```

**Implémentation**:
```dart
static Future<void> login({
  required int userId,
  // ...
}) async {
  // Guard: ne clear que si changement d'utilisateur
  final isUserSwitch = _currentSession?.userId != userId;
  if (isUserSwitch) {
    ApiService.clearCache(); // ✅ Une seule fois
  }
  // ...
}

static Future<void> logout() async {
  ApiService.clearCache(); // ✅ Une seule fois
  _currentSession = null;
  await TokenStorage.clear();
}

static Future<void> restoreSession() async {
  // ❌ SKIP clearCache() - données locales restaurées
  // ...
}
```

---

### Erreur #3: "Appels réseau répétés au démarrage"

**Symptômes**:
```
Health check × 2
Fetch météo × 3
Fetch notifications × 4
Network tab saturée
```

**Cause racine**:
```dart
// ❌ MAUVAIS:
// main() appelle _wakeupBackend()
// _wakeupBackend() times out et attend 10s
// Pendant ce temps, initState() des écrans lance d'autres appels
// Result: 5+ appels qui saturent le réseau
```

**Solution**:
```dart
// ✅ BON:
// 1. AppBootstrap lance wakeup EN PARALLÈLE (timeout court 3s)
// 2. Autres appels EN LAZY (on-demand, après bootstrap)
// 3. Ordonnancement: auth → météo (1s) → notifications (2s)

Future<bool> _wakeupBackendAsync() async {
  try {
    return await ApiService.healthCheck()
        .timeout(const Duration(seconds: 3)); // Court!
  } catch (e) {
    return false; // On s'en fiche, UI continue
  }
}

// Dans app_initializer:
Future.delayed(const Duration(seconds: 1), () {
  WeatherService.getWeather(); // 2ème appel
});
Future.delayed(const Duration(seconds: 2), () {
  NotificationService.getUnreadCount(); // 3ème appel
});
```

---

### Erreur #4: "NotificationService.getUnreadCount appelé sans auth"

**Symptômes**:
```
Exception: No access token available
Badge widget crashes
UI hole visible
```

**Cause racine**:
```dart
// ❌ MAUVAIS:
class HomeScreen {
  @override
  void initState() {
    NotificationService.getUnreadCount(); // Appelé immédiatement!
    // Mais AuthService.restoreSession() n'est pas terminé
  }
}
```

**Solution**:
```dart
// ✅ BON: Pattern avec FutureBuilder
class HomeScreen {
  @override
  Widget build(BuildContext context) {
    return NotificationIcon(); // Délégué
  }
}

class NotificationIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // FutureBuilder va essayer l'appel quand le widget monte
    return FutureBuilder<int>(
      future: NotificationService.getUnreadCount(),
      builder: (context, snapshot) {
        // Si user n'est pas auth, getUnreadCount retourne 0 silencieusement
        final count = snapshot.data ?? 0;
        return Badge(label: Text('$count'));
      },
    );
  }
}

// Dans NotificationService:
static Future<int> getUnreadCount() async {
  final userId = AuthService.currentSession?.userId;
  if (userId == null) {
    return 0; // ✅ Silencieux, pas d'exception
  }
  // ...
}
```

---

### Erreur #5: "Backend timeout (cold start) bloque l'UI"

**Symptômes**:
```
🏥 Attempting to wake up backend...
[waiting 10 seconds...]
UI freeze, can't interact
```

**Cause racine**:
```dart
// ❌ MAUVAIS:
Future<void> _wakeupBackend() async {
  try {
    final response = await http.get(healthUrl)
        .timeout(const Duration(seconds: 10)); // TROP LONG!
    // Pendant ce temps, la main thread attend
  }
}
```

**Solution**:
```dart
// ✅ BON: Wakeup non-bloquant
Future<bool> _wakeupBackendAsync() async {
  try {
    return await ApiService.healthCheck()
        .timeout(const Duration(seconds: 3)); // Court
    // Résultat ignoré si timeout
  } catch (e) {
    return false; // OK
  }
}

// Dans AppBootstrap.initialize():
// Ne PAS await _wakeupBackendAsync()
// À la place:
_wakeupBackendAsync(); // Fire-and-forget!

// Pendant ce temps, l'app continue
```

---

### Erreur #6: "FutureBuilders imbriqués"

**Symptômes**:
```
Widget rebuilds 100 times
Each rebuild launches HTTP call
Network saturated
Performance degrades
```

**Cause racine**:
```dart
// ❌ MAUVAIS - imbrication
FutureBuilder(
  future: fetchData1(), // Appel 1
  builder: (context, snapshot1) {
    return FutureBuilder(
      future: fetchData2(), // Appel 2 (lance à CHAQUE rebuild!)
      builder: (context, snapshot2) {
        return FutureBuilder(
          future: fetchData3(), // Appel 3 (lance à CHAQUE rebuild!)
          builder: (context, snapshot3) {
            // 3 appels × rebuild = 1000 ms
          },
        );
      },
    );
  },
)
```

**Solution #1: Paralléliser avec Future.wait()**
```dart
// ✅ BON - appels parallèles
Future<Map<String, dynamic>> _fetchAllData() async {
  final results = await Future.wait([
    fetchData1(),
    fetchData2(),
    fetchData3(),
  ]);
  return {
    'data1': results[0],
    'data2': results[1],
    'data3': results[2],
  };
}

@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: _fetchAllData(),
    builder: (context, snapshot) {
      final data = snapshot.data;
      // ✅ Un seul FutureBuilder, 3 appels parallèles
    },
  );
}
```

**Solution #2: Provider (meilleur)**
```dart
// ✅ MEILLEUR - avec Provider
class DashboardProvider extends ChangeNotifier {
  late Future<Dashboard> dashboard;
  
  DashboardProvider() {
    dashboard = _loadAllData(); // Cache the future!
  }
  
  Future<Dashboard> _loadAllData() async {
    // Appels parallèles
    final results = await Future.wait([...]);
    return Dashboard(...);
  }
}

// Usage:
@override
Widget build(BuildContext context) {
  return Consumer<DashboardProvider>(
    builder: (context, provider, child) {
      return FutureBuilder(
        future: provider.dashboard, // Future CACHED
        builder: (context, snapshot) {
          // Un seul appel!
        },
      );
    },
  );
}
```

---

### Erreur #7: "Skipped frames au démarrage"

**Symptômes**:
```
Skipped 50 frames! The application may be doing too much work on its main thread
UI lag visible
```

**Causes possibles & Solutions**:

| Cause | Vérifier | Solution |
|-------|----------|----------|
| Appel réseau dans `build()` | Logs réseau | Mettre en FutureBuilder |
| Image PNG grande (non-compressed) | Asset size | Compresser avec `flutter pub get` |
| Boucle `forEach` sur 1000+ items | Profiler | Utiliser `ListView.builder` |
| Animation sans `vsync` | Code | Utiliser `TickerProviderStateMixin` |
| Locale initialization bloquant | Logs | Moved to main() ✓ |

**Debuggin Skipped Frames**:
```bash
# 1. Voir les frames perdus
flutter run --profile

# 2. Ouvrir DevTools
# Devtools → Performance → Slow Frames

# 3. Voir la timeline
# Chercher les frames > 16ms (60fps) ou 33ms (30fps)

# 4. Identifier l'appel coûteux
# 99% du temps: appel réseau bloquant ou image trop grosse
```

---

## 🎯 Résumé des 7 Erreurs

| Erreur | Symptôme | Cause | Fix |
|--------|---------|-------|-----|
| #1: Boucle restoreSession | Multipl calls, freeze | Service appelle restore | ❌ Appel, ✅ Guard |
| #2: clearCache répété | Cache miss | Trop d'appels | One at logout + user-switch |
| #3: Appels réseau saturation | Slow startup | Sequential + blocking | Lazy + async |
| #4: No auth guard | Exception, crash | FutureBuilder eager | Guard + silent return |
| #5: Timeout UI-bloquant | Freeze 10s | await health check | Fire-and-forget + short timeout |
| #6: FutureBuilder imbriqué | 1000 rebuilds | Nested futures | Future.wait() ou Provider |
| #7: Skipped frames | Lag | Heavy work on UI | Profile + isolate |

Toutes ces erreurs sont **évitées** avec la nouvelle architecture!
