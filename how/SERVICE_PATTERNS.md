## 🔧 Implémentation des Patterns de Service

### Pattern 1: Service dépendant de l'authentification

```dart
/// ✅ Template de base pour tout service dépendant de l'auth
class MyAuthDependentService {
  /// 🔓 GUARD strict - pas de restauration automatique
  /// 
  /// Si l'utilisateur n'est pas authentifié, la méthode doit échouer
  /// proprement (exception ou valeur par défaut).
  static Future<List<MyData>> fetchData() async {
    try {
      // ✅ GUARD 1: Vérifier que l'utilisateur est authentifié
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
        // Ou pour les appels "non-critiques":
        // return []; // Retour vide au lieu d'exception
      }

      // ✅ GUARD 2: Vérifier que le token existe
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // ✅ Faire l'appel API de manière sûre
      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/my-data',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMyData(data);
      } else if (response.statusCode == 401) {
        // Token expiré - ne pas restaurer, laisser le user se reconnecter
        throw Exception('Token expired - please login again');
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ MyAuthDependentService.fetchData error: $e');
      rethrow; // Laisser l'appelant gérer l'erreur
    }
  }

  // Parsing helpers
  static List<MyData> _parseMyData(dynamic data) {
    // ...
  }
}
```

---

### Pattern 2: Service avec fallback gracieux (non-critique)

```dart
/// ✅ Pour les services non-critiques (badge, suggestion, etc.)
class MyOptionalService {
  /// Retourne une valeur par défaut au lieu de crasher
  /// Idéal pour les badges, widgets optionnels
  static Future<int> getCount() async {
    try {
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        debugPrint('ℹ️ getCount: User not authenticated, returning 0');
        return 0; // ✅ Retour gracieux
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        return 0; // ✅ Fallback
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/$userId/count'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int? ?? 0;
      } else {
        return 0; // ✅ Fallback sur n'importe quelle erreur
      }
    } catch (e) {
      debugPrint('⚠️ getCount failed (returning 0): $e');
      return 0; // ✅ Toujours un fallback
    }
  }
}
```

---

### Pattern 3: Appel dans un FutureBuilder

```dart
/// ✅ Comment utiliser un service dans un widget
class MyDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MyData>>(
      future: MyAuthDependentService.fetchData(),
      builder: (context, snapshot) {
        // 3 états à gérer
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Gestion d'erreur gracieuse
          final error = snapshot.error;
          if (error.toString().contains('authenticated')) {
            return const Center(child: Text('Please login first'));
          }
          return Center(child: Text('Error: $error'));
        }

        // Succès
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('No data'));
        }

        return ListView(
          children: data.map((item) => ListTile(
            title: Text(item.name),
          )).toList(),
        );
      },
    );
  }
}
```

---

### Pattern 4: Service avec caching

```dart
/// ✅ Service avec caching automatique
class MyCachedService {
  static const String _cacheKey = 'my_data_cache';
  static const Duration _cacheTtl = Duration(minutes: 5);

  static Future<List<MyData>> fetchData({bool forceRefresh = false}) async {
    // Guard
    final userId = AuthService.currentSession?.userId;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    // Vérifier le cache
    if (!forceRefresh) {
      final cached = ApiService.getCached<List<MyData>>(_cacheKey);
      if (cached != null) {
        debugPrint('✅ Returning cached data for $userId');
        return cached;
      }
    }

    // Appel réseau
    final token = await TokenStorage.getAccessToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/users/$userId/data'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = _parseData(response.body);
      
      // Mettre en cache
      ApiService.cache<List<MyData>>(_cacheKey, data, ttl: _cacheTtl);
      
      return data;
    }
    
    throw Exception('Failed to fetch data');
  }

  static List<MyData> _parseData(String body) {
    // ...
  }
}
```

---

### Pattern 5: Services avec retry automatique

```dart
/// ✅ Service avec retry exponentiel (built-in ApiService._withRetry)
class MyRetriableService {
  static Future<List<MyData>> fetchData() async {
    // Utiliser le helper _withRetry du ApiService
    return ApiService._withRetry(
      () => _fetchDataOnce(),
      maxRetries: 3,
    );
  }

  static Future<List<MyData>> _fetchDataOnce() async {
    final userId = AuthService.currentSession?.userId;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final token = await TokenStorage.getAccessToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/users/$userId/data'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return _parseData(response.body);
    }
    throw Exception('Failed: ${response.statusCode}');
  }

  static List<MyData> _parseData(String body) {
    // ...
  }
}
```

---

### Pattern 6: Service avec initialisation lazy

```dart
// ✅ Dans app_initializer.dart
static bool _myServiceInitialized = false;

static Future<void> initMyServiceOnDemand() async {
  if (_myServiceInitialized) return;

  try {
    debugPrint('🔄 Initializing MyService...');
    // await MyService.initialize();
    _myServiceInitialized = true;
    debugPrint('✅ MyService initialized');
  } catch (e) {
    debugPrint('⚠️ MyService initialization failed: $e');
  }
}

// Appeler dans initState() d'un écran:
// AppInitializer.initMyServiceOnDemand();
```

---

### Pattern 7: Teste après logout

```dart
/// ✅ Template pour reset après logout
static Future<void> logout() async {
  // 1. Invalider tous les caches
  ApiService.clearCache();

  // 2. Reset lazy-init flags
  AppInitializer.reset();

  // 3. Effacer la session
  _currentSession = null;
  await TokenStorage.clear();

  // 4. Notifier les listeners (si vous utilisez Provider)
  // notifyListeners();

  debugPrint('✅ AuthService.logout complete');
}

// Test: Après logout, vérifier que:
// ✅ AuthService.isAuthenticated == false
// ✅ AuthService.currentSession == null
// ✅ TokenStorage.getAccessToken() == null
// ✅ Les services retournent des valeurs par défaut
// ✅ FutureBuilders n'affichent pas d'erreurs)
```

---

### Pattern 8: Gérer l'authentification dans le Provider

```dart
/// ✅ Si vous utilisez Provider (recommandé)
class AuthProvider extends ChangeNotifier {
  Session? _session;
  Session? get session => _session;
  bool get isAuthenticated => _session != null;

  Future<void> restoreSession() async {
    try {
      await AuthService.restoreSession();
      _session = AuthService.currentSession;
      notifyListeners(); // Refresh UI ONCE
    } catch (e) {
      debugPrint('❌ restoreSession failed: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.login(
          userId: data['userId'],
          email: data['email'],
          name: data['name'],
          role: data['role'],
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        _session = AuthService.currentSession;
        notifyListeners(); // Refresh UI ONCE
      }
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _session = null;
    AppInitializer.reset();
    notifyListeners(); // Refresh UI ONCE
  }
}

// Usage dans MbaymiApp:
class MbaymiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
```

---

## ✅ Résumé des 8 Patterns

1. **Service auth-dependent**: Guard strict + exception
2. **Service optional**: Guard + fallback gracieux
3. **FutureBuilder**: Gérer 3 états (loading, error, data)
4. **Caching**: TTL + forceRefresh option
5. **Retry**: Utiliser `_withRetry` du ApiService
6. **Lazy-init**: Flag + scheduling
7. **Logout**: Reset complet + flags
8. **Provider**: Centralized state + notifyListeners()

Appliquez ces patterns partout et vos services seront robustes, performants et testables!
