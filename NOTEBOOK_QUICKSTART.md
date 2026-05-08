# 🚀 Démarrage rapide : Cahier complet

**Temps estimé : 15 minutes**

## ✅ Checklist pré-requise

- [ ] Backend FastAPI en cours d'exécution (`python main.py`)
- [ ] PostgreSQL connectée (Neon ou local)
- [ ] Migrations exécutées (`alembic upgrade head`)
- [ ] Flutter prêt à compiler

## 1️⃣ Préparer la base de données

### 1.1 Générer et exécuter les migrations

```bash
cd backend

# Générer la migration
alembic revision --autogenerate -m "Add notebook tables"

# Appliquer les migrations
alembic upgrade head
```

**Vérifier en PostgreSQL :**
```sql
\dt  -- Lister toutes les tables
SELECT * FROM alembic_version;  -- Vérifier les migrations
```

### 1.2 Insérer les données de test (optionnel)

```sql
-- Insérer un utilisateur test
INSERT INTO users (username, email, password_hash, role) 
VALUES ('farmer1', 'farmer@example.com', 'hashed_password', 'farmer');

-- Insérer une ferme test
INSERT INTO farms (name, location, owner_id, size_hectares) 
VALUES ('Ferme Test', 'Bordeaux', 1, 50);
```

## 2️⃣ Démarrer le backend

### 2.1 Activation de l'environnement virtuel

**Windows:**
```bash
.\venv\Scripts\activate
```

**Mac/Linux:**
```bash
source venv/bin/activate
```

### 2.2 Installer les dépendances (si nécessaire)

```bash
cd backend
pip install -r requirements.txt
```

### 2.3 Démarrer le serveur

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

✅ **Vérifier :** Allez à `http://localhost:8000/docs` → Vous devez voir les endpoints Swagger

## 3️⃣ Vérifier les endpoints du backend

Testez avec curl ou Postman :

```bash
# Obtenir tous les cahiers (authentification requise)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/notebooks

# Créer un cahier
curl -X POST http://localhost:8000/api/notebooks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Mon cahier",
    "description": "Description",
    "farm_id": 1,
    "category": "general",
    "tags": []
  }'
```

## 4️⃣ Préparer le frontend

### 4.1 Configuration de l'URL backend

**Fichier:** `lib/main.dart`

Trouvez : `NotebookApiService(baseUrl: ...)`

```dart
// LOCAL DEVELOPMENT
const baseUrl = 'http://localhost:8000';

// ANDROID EMULATOR
const baseUrl = 'http://10.0.2.2:8000';

// iOS SIMULATOR
const baseUrl = 'http://localhost:8000';

// FLUTTER WEB
const baseUrl = 'http://localhost:8000';

// PRODUCTION
const baseUrl = 'https://your-api.com';
```

### 4.2 Actualiser les dépendances

```bash
cd frontend
flutter pub get
```

### 4.3 Analyser les erreurs

```bash
flutter analyze
```

**Résoudre les erreurs liées à `http` package :**

Si `http` n'est pas dans `pubspec.yaml`, ajoutez-le :

```yaml
dependencies:
  http: ^1.1.0
```

Puis : `flutter pub get`

## 5️⃣ Exécuter l'application

### 5.1 Mode développement

```bash
flutter run
```

### 5.2 Mode web

```bash
flutter run -d chrome
```

### 5.3 Mode Android (émulateur)

```bash
flutter run -d emulator
```

## 6️⃣ Tester la synchronisation

### 6.1 Login utilisateur

L'écran de login établit le token JWT :

```dart
// Le token est sauvegardé automatiquement
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', jwtToken);
```

### 6.2 Ouvrir l'écran des cahiers

```
App → Cahiers → Écran de liste
```

**Attendu :**
- Liste chargée depuis le serveur ✅
- Mode hors ligne si le serveur est indisponible ✅
- Bouton "Synchroniser" disponible ✅

### 6.3 Tester la création

```
Appuyer sur "+" → Créer nouveau cahier
```

**Attendu :**
- Cahier créé sur le serveur ✅
- Cahier mis à jour dans la liste ✅
- Sauvegardé localement aussi ✅

### 6.4 Tester les commentaires

```
Ouvrir cahier → Onglet "Commentaires" → Ajouter un commentaire
```

**Attendu :**
- Commentaire envoyé au serveur ✅
- Commentaire visible immédiatement ✅

## 🐛 Résolution des problèmes

### "Unable to reach API"

**Cause:** Backend non accessible

**Vérification :**
1. Backend en cours d'exécution ? → `ps aux | grep uvicorn`
2. Port correct ? → `http://localhost:8000/docs`
3. Firewall bloque ? → Ouvrir le port 8000

### "Invalid token"

**Cause:** Token JWT expiré ou invalide

**Solution:**
1. Reconnecter l'utilisateur (revalider le login)
2. Régénérer le JWT dans le backend

### "CORS error"

**Cause:** Backend n'autorise pas les requêtes du frontend

**Solution (dans `backend/app/main.py`):**

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### "Mode hors ligne" persistant

**Cause:** Backend inaccessible mais données locales affichées

**Solution:**
1. Vérifier que le backend est en ligne
2. Appuyer sur "Synchroniser"
3. Vérifier les logs du backend : `alembic upgrade head`

## 📊 Architecture de synchronisation

```
┌─────────────┐                ┌─────────────┐
│   Flutter   │                │   FastAPI   │
│   (Mobile)  │ ◄──────HTTP────► │ (Backend) │
│             │                │  PostgreSQL │
└─────┬───────┘                └─────────────┘
      │
      ▼
┌─────────────────────┐
│ SharedPreferences   │
│  (Local Storage)    │
└─────────────────────┘
```

**Flow:**
1. User action in Flutter → HTTP request → Backend
2. Backend persist in PostgreSQL
3. Backend returns updated data
4. Flutter updates local storage + UI

## 🔐 Authentification JWT

Le service API utilise le JWT stocké :

```dart
// Après login
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', response.jwtToken);

// NotebookApiService le récupère automatiquement
await notebookApiService.initialize();

// Tous les appels API incluent : 
// Authorization: Bearer {jwtToken}
```

## 📈 Performance

### Recommandations

1. **Charger les données au démarrage** (une fois)
   ```dart
   void initState() {
     provider.loadNotebooks();  // Une fois seulement
   }
   ```

2. **Filtrer localement** (pas d'appels API)
   ```dart
   provider.setCategory('plants');  // Filtre local
   ```

3. **Synchroniser régulièrement** (optionnel)
   ```dart
   syncWithServer();  // Quand nécessaire
   ```

4. **Gérer les erreurs réseau**
   ```dart
   if (provider.errorMessage != null) {
     showSnackBar(provider.errorMessage);
   }
   ```

## ✨ Fonctionnalités complètes

- ✅ CRUD Cahiers (Créer, Lire, Mettre à jour, Supprimer)
- ✅ Commentaires collaboratifs
- ✅ Partage avec autres utilisateurs
- ✅ Versioning et historique
- ✅ Recherche full-text
- ✅ Synchronisation offline-first
- ✅ Sauvegarde locale automatique

## 🎯 Prochaines actions

1. **Immédiate** → Exécuter les migrations DB
2. **Court terme** → Tester les endpoints
3. **Moyen terme** → Intégrer les authentifications
4. **Long terme** → Ajouter les tests automatisés

## 📞 Support

**Logs du backend :**
```bash
tail -f logs/app.log
```

**Logs Flutter :**
```bash
flutter logs
```

**Déboguer les requêtes HTTP :**
```dart
// Ajouter dans main.dart
import 'package:logging/logging.dart';

hierarchicalLoggingEnabled = true;
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});
```

---

**Status:** ✅ Intégration complète prête  
**Dernière mise à jour:** 2024  
**Version:** 1.0
