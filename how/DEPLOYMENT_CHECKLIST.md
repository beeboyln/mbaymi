## 📋 CHECKLIST COMPLÈTE DE DÉPLOIEMENT

### Phase 1: Architecture (✓ Complétée)

- [x] AppBootstrap créé
- [x] AppInitializer créé
- [x] AuthService refactorisé (sans boucles)
- [x] NotificationService refactorisé (guards strictes)
- [x] main.dart optimisé (async bootstrap)
- [x] MbaymiApp refactorisé (bootstrap sur initState)

### Phase 2: Vérification des Services Existants

**À faire**: Pour CHAQUE service, vérifier:

#### NotificationService
- [ ] `getNotifications()`: Guard sans restoreSession()
- [ ] `getUnreadCount()`: Retour 0 au lieu d'exception
- [ ] `markAsRead()`: Guard strict
- [ ] `deleteNotification()`: Guard strict
- [ ] Aucun appel dans build()

#### WeatherService
- [ ] `getWeather()`: Guard si utilisateur non-auth (retour valeurs par défaut)
- [ ] Pré-chargement via AppInitializer
- [ ] Maximal timeout: 15s
- [ ] Lazy-init dans DashboardScreen/HomeScreen

#### Autres Services API
- [ ] Tous ont des guards d'authentification
- [ ] Aucun clearCache() systématique
- [ ] Timeouts raisonnables (15-30s max)
- [ ] Pas d'appels dans build()

### Phase 3: Tests sur Android

- [ ] Test #1: Démarrage sans réseau
  ```
  adb shell svc wifi disable
  adb shell svc data disable
  flutter run
  → App visible immédiatement
  → Pas de crash
  → UI responsive
  ```

- [ ] Test #2: Backend timeout (cold start simulé)
  ```
  adb shell svc wifi disable
  flutter run
  → App visible en < 1s
  → Pas d'écran blanc
  → UI ne freeze pas
  ```

- [ ] Test #3: Pas de "skipped frames"
  ```
  flutter run --profile
  DevTools → Performance → Check slow frames
  → Tous les frames < 33ms (30fps)
  → Pas de "Skipped XXX frames" dans logs
  ```

- [ ] Test #4: Appels réseau
  ```
  Ouvrir logcat: adb logcat | grep -i "http\|auth\|notification"
  Vérifier l'ordre:
  → AuthService.restoreSession() × 1 ✓
  → _wakeupBackendAsync() × 1 (optional timeout)
  → Weather × 1 (lazy)
  → Notifications × 1 (lazy)
  → Pas d'appels redondants
  ```

- [ ] Test #5: Logout et reconnexion
  ```
  1. Logout
  2. Vérifier: AuthService.isAuthenticated == false
  3. Vérifier: cache cleared
  4. Login à nouveau
  5. Vérifier: cache cleared (user switch)
  6. App ne crash pas
  ```

- [ ] Test #6: Auth token invalide
  ```
  1. Supprimer token via StorageService
  2. Relancer l'app
  3. Vérifier: User sees login screen (pas d'erreur)
  4. Services retournent gracieusement des valeurs par défaut
  ```

### Phase 4: Performance Metrics

- [ ] Time to first frame: **< 100ms**
- [ ] Auth restoration: **< 500ms**
- [ ] App fully interactive: **< 2s**
- [ ] Skipped frames: **0** (ou < 5)
- [ ] Memory usage at startup: **< 60MB**
- [ ] Cold startup: **< 5s** (même si backend timeout)

### Phase 5: Logging Verificatino

Vérifier les logs à démarrage:
```
✅ .env loaded successfully
✅ Locale initialized: fr_FR
✅ ThemeProvider initialized
🎨 Building MbaymiApp with AppBootstrap...
═══════════════════════════════════════════
🚀 AppBootstrap.initialize() STARTING
📍 Step 1/2: AuthService.restoreSession()...
✅ Auth restored: true (userId=123)    ← Ou false si pas authentifié
📍 Step 2/2: _wakeupBackendAsync()...
✅ AppBootstrap COMPLETE (450ms)       ← Moins de 1 seconde
🎬 AppInitializer scheduling post-bootstrap tasks...
🔄 Pre-loading weather data...
✅ Weather pre-loaded
```

**À ÉVITER dans les logs**:
- ❌ `AuthService.restoreSession() called multiple times`
- ❌ `Cleared all cache` (plus d'une fois)
- ❌ `Skipped XXX frames`
- ❌ `Exception: User not authenticated` (sauf attendu)
- ❌ `Health check timeout` (peut être OK, mais pas LONG)

### Phase 6: Code Review Checklist

```
Nouveau code ajouté par votre équipe:

□ Aucun appel API dans build()
  grep -r "http\.\|ApiService\." lib/screens/ | grep -v "FutureBuilder\|future:"

□ Aucun clearCache() systématique
  grep -r "ApiService.clearCache()" lib/services/

□ Aucun restoreSession() depuis les services
  grep -r "AuthService.restoreSession()" lib/services/

□ Tous les services auth-dépendants ont des guards
  grep -r "currentSession\?.userId" lib/services/ | grep -v "== null\|!= null"

□ Pas d'imports de main.dart sauf app.dart
  grep -r "import.*main.dart" lib/src

□ Tous les FutureBuilders gèrent les 3 états
  grep -r "FutureBuilder" lib/ | grep -c "ConnectionState.waiting\|hasError"
```

### Phase 7: Déploiement Production

- [ ] Tester sur device réel (pas émulateur)
- [ ] Tester sur réseau 4G/3G (pas WiFi)
- [ ] Tester 5 fois de suite (pas de memory leak)
- [ ] Vérifier les crash logs (Firebase Crashlytics)
- [ ] Vérifier la performance (Firebase Performance)
- [ ] Code review par pair
- [ ] Release notes: "Fixed startup performance issues"

---

## 📊 Avant / Après Comparaison

### AVANT (Votre code actuel)

```
Démarrage:
├─ main() → restoreSession() [500ms] ⚠️ BLOQUANT
├─ main() → _wakeupBackend() [10s timeout] ❌ BLOQUANT!
├─ main() → ThemeProvider [100ms]
└─ runApp() → MbaymiApp builds
    ├─ getAllNotifications() ← AppInitializer lance ✓
    ├─ getWeather() ← AppInitializer lance ✓
    ├─ getUnreadCount() ← Widget badge lance... ✗ BOUCLE POTENTIELLE
    └─ FutureBuilder imbriqués [5 appels parallèles] ❌ CHAOS

Problèmes:
❌ restoreSession() x2-3 fois
❌ clearCache() x2-3 fois
❌ Backend timeout bloque UI
❌ Appels réseau chaotiques
❌ Skipped frames
```

### APRÈS (Votre nouvelle architecture)

```
Démarrage:
├─ main() → .env load [local]
├─ main() → Locale init [local]
├─ main() → ThemeProvider [local]
└─ runApp() → MbaymiApp builds IMMÉDIATEMENT ✅
    └─ AppBootstrap().initialize() EN ARRIÈRE-PLAN
        ├─ restoreSession() [500ms, LOCAL] ✓
        ├─ _wakeupBackendAsync() [3s timeout, fire-and-forget] ✓
        └─ AppInitializer.schedulePostBootstrapTasks()
            ├─ weather [+1s delay]
            └─ notifications [+2s delay]

Résultats:
✅ restoreSession() × 1
✅ clearCache() × 1 (logout seulement)
✅ UI visible en < 100ms
✅ Appels réseau ordonnancés
✅ Zéro skipped frames
✅ Fonctionne en cold start
```

---

## 🎯 Checklist Finale

### Avant de merger le code

- [ ] Tous les fichiers created/modified lisés
- [ ] Tests unitaires passent
- [ ] Tests d'intégration passent
- [ ] Pas d'erreurs de compilation
- [ ] Code formatting OK (`dart format lib/`)
- [ ] Code analysis OK (`dart analyze`)
- [ ] Logs nettoyés (pas de debugPrint non-essentiels)

### Avant de déployer

- [ ] Tests manuels sur Android device
- [ ] Tests manuels sans réseau
- [ ] Tests manuels avec backend timeout
- [ ] Performance metrics vérifiées
- [ ] Logs finaux vérifiés
- [ ] Backup du code production

### Post-Déploiement (monitoring)

- [ ] Crash rate < 0.1%
- [ ] Average startup time < 3s
- [ ] Memory usage stable
- [ ] Network errors handled gracefully
- [ ] User feedback positif

---

## 📞 Support & Troubleshooting

### Si vous avez encore des "skipped frames"

1. **Profiler**:
   ```bash
   flutter run --profile
   # DevTools → Performance → Check timeline
   ```

2. **Chercher l'appel coûteux**:
   - Appels réseau? → Move to lazy-init
   - Image grosse? → Compress PNG
   - Animation? → Use vsync
   - Liste 1000+ items? → ListView.builder

3. **Isoler le problème**:
   - Supprimer AppInitializer.preload
   - Vérifier les FutureBuilders
   - Vérifier les initState() des widgets

### Si AuthService.restoreSession() appelé plusieurs fois

1. **Vérifier les logs**:
   ```
   grep -i "restoreSession" logcat
   ```

2. **Chercher les appels**:
   ```bash
   grep -r "restoreSession" lib/
   # Doit retourner UNE seule ligne (dans main.dart)
   ```

3. **Vérifier les services**:
   - Aucun service ne doit appeler restoreSession()
   - Guards strictes au lieu de restauration

### Si clearCache() exécuté trop

1. **Vérifier les logs**:
   ```
   grep -i "cleared all cache" logcat
   ```

2. **Chercher les appels**:
   ```bash
   grep -r "clearCache()" lib/
   # Doit retourner DEUX maxmimum (logout + login si user-switch)
   ```

---

## ✅ Fin de Checklist

Quand TOUT est coché:
- Votre app est **production-ready**
- Performance optimisée
- Architecture propre
- Zéro problèmes au démarrage
- Scalable pour la croissance future

Bon déploiement! 🚀
