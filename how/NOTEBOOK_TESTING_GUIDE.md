# ✅ Guide de test : Système de Cahier

**Procédures de vérification complete du système frontend-backend**

---

## 🎯 Objectif global

Vérifier que tout le système fonctionne:
1. ✅ Backend API répond correctement
2. ✅ Base de données sauvegarde les données
3. ✅ Frontend peut créer/lire/modifier/supprimer cahiers
4. ✅ Synchronisation bidirectionnelle fonctionne
5. ✅ Mode offline marche

---

## 🧪 Phase 1: Tests Backend (5-10 minutes)

### Test 1.1: Serveur en cours d'exécution

```bash
# Vérifier que le serveur démarre
cd backend
python -m uvicorn app.main:app --reload

# Résultat attendu:
# INFO:     Uvicorn running on http://127.0.0.1:8000
# INFO:     Application startup complete
```

---

### Test 1.2: Swagger UI accessible

**URL:** `http://localhost:8000/docs`

**Résultat attendu:**
- Page Swagger charge
- Tous les endpoints visibles (dont `/api/notebooks`)

**Si ❌ :** Vérifier que le serveur tourne et que le port 8000 est libre

---

### Test 1.3: Health check

```bash
curl http://localhost:8000/docs

# Résultat: HTML de Swagger (200 OK)
```

---

## 🗄️ Phase 2: Tests Base de Données (5 minutes)

### Test 2.1: Connexion PostgreSQL

```bash
# Tester la connexion
psql -U your_user -h localhost -d your_database

# Si succès:
# psql (14.x)
# Type "help" for help.
# your_database=#

# Quitter
\q
```

---

### Test 2.2: Tables créées

```bash
psql your_database -c "\dt"

# Résultat attendu:
# public | notebook_comments
# public | notebook_sections
# public | notebook_shares
# public | notebooks
# public | notebook_tags
# public | notebook_versions
```

**Si ❌ tables manquantes:** Exécuter les migrations
```bash
cd backend
alembic upgrade head
```

---

### Test 2.3: Schémas corrects

```bash
psql your_database -c "\d notebooks"

# Résultat attendu:
# Column        | Type      | Constraints
# id            | integer   | PRIMARY KEY
# title         | varchar   | NOT NULL
# description   | text      | 
# farm_id       | integer   | FOREIGN KEY
# created_by    | integer   | FOREIGN KEY
# category      | varchar   | 
# is_public     | boolean   | DEFAULT false
# sections      | jsonb     | 
# created_at    | timestamp | 
# updated_at    | timestamp |
```

---

## 🔌 Phase 3: Tests API (15-20 minutes)

### Test 3.1: Authentification (préalable)

**Créer un utilisateur de test:**

```bash
# Dans PostgreSQL, ajouter un utilisateur test
psql your_database -c "
INSERT INTO users (username, email, password_hash, role) 
VALUES ('testuser', 'test@example.com', 'hashedpassword', 'farmer');
"
```

**Obtenir un JWT token:**

```bash
# Login endpoint (dépend de votre implémentation)
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpassword"
  }'

# Résultat: { "access_token": "eyJhbg...", "token_type": "bearer" }
# Copier le token pour les tests suivants
```

**Ou obtenir un token directement (si déjà authentifié):**
```bash
# Depuis l'application Flutter déjà loggée
# SharedPreferences → auth_token
```

---

### Test 3.2: Créer un cahier (POST)

```bash
TOKEN="eyJhbg..."  # Remplacer par votre token

curl -X POST http://localhost:8000/api/notebooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notebook #1",
    "description": "Test description",
    "farm_id": 1,
    "category": "crops",
    "tags": ["test"],
    "is_public": false
  }'

# Résultat attendu:
# {
#   "id": 1,
#   "title": "Test Notebook #1",
#   "description": "Test description",
#   "farm_id": 1,
#   "created_by": 2,
#   ...
# }
```

**Si ❌ erreur `farm_id` introuvable:**
```bash
# Ajouter une ferme test
psql your_database -c "
INSERT INTO farms (name, location, owner_id, size_hectares)
VALUES ('Test Farm', 'Test Location', 1, 50);
"
```

---

### Test 3.3: Lire les cahiers (GET)

```bash
TOKEN="eyJhbg..."

# Lister tous
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/notebooks

# Résultat: [{ "id": 1, "title": "Test Notebook #1", ... }]
```

---

### Test 3.4: Lire un cahier spécifique

```bash
TOKEN="eyJhbg..."

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/notebooks/1

# Résultat: { id: 1, title: ..., sections: [], comments: [], ... }
```

---

### Test 3.5: Mettre à jour un cahier (PUT)

```bash
TOKEN="eyJhbg..."

curl -X PUT http://localhost:8000/api/notebooks/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notebook #1 UPDATED",
    "description": "Updated description",
    "category": "plants",
    "tags": ["updated"],
    "sections": [],
    "is_public": false
  }'

# Résultat: { id: 1, title: "Test Notebook #1 UPDATED", ... }
```

---

### Test 3.6: Ajouter un commentaire

```bash
TOKEN="eyJhbg..."

curl -X POST http://localhost:8000/api/notebooks/1/comments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Great notebook!"}'

# Résultat:
# {
#   "id": 1,
#   "user_id": 2,
#   "user_name": "testuser",
#   "text": "Great notebook!",
#   "created_at": "2024-01-15T10:30:00"
# }
```

---

### Test 3.7: Créer une version

```bash
TOKEN="eyJhbg..."

curl -X POST http://localhost:8000/api/notebooks/1/versions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"change_description": "Initial draft"}'

# Résultat:
# {
#   "id": 1,
#   "notebook_id": 1,
#   "version_number": 1,
#   "change_description": "Initial draft",
#   "created_by": 2,
#   "created_at": "2024-01-15T10:30:00"
# }
```

---

### Test 3.8: Recherche

```bash
TOKEN="eyJhbg..."

curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/notebooks/search?query=Test"

# Résultat: [ { id: 1, title: "Test Notebook #1 UPDATED", ... } ]
```

---

### Test 3.9: Supprimer un cahier (DELETE)

```bash
TOKEN="eyJhbg..."

curl -X DELETE http://localhost:8000/api/notebooks/1 \
  -H "Authorization: Bearer $TOKEN"

# Résultat: 204 No Content (vide)
```

---

## 📱 Phase 4: Tests Frontend (20-30 minutes)

### Test 4.1: Compilation sans erreurs

```bash
cd frontend

# Analyser
flutter analyze

# Résultat attendu: 0 erreurs
```

---

### Test 4.2: Démarrage de l'appli

```bash
# Démarrer le frontend
flutter run

# Résultat attendu:
# ✓ Built build/app/outputs/flutter-apk/app-debug.apk
# Launching lib/main.dart on ...
# ✓ App started successfully.
```

---

### Test 4.3: Login utilisateur

**Écran 1: Login**
1. Entrer username: `testuser`
2. Entrer password: `testpassword`
3. Appuyer "Login"

**Résultat attendu:**
- ✅ Login réussit
- ✅ Accès à l'écran home
- Token sauvegardé dans SharedPreferences

**Si ❌ :**
- Vérifier que l'utilisateur existe dans la BD
- Vérifier que le backend API de login fonctionne

---

### Test 4.4: Naviguer vers l'écran Cahiers

**Navigation:**
1. Aller au menu principal
2. Appuyer sur "Cahiers" (ou "Notebooks")

**Résultat attendu:**
- ✅ Écran "Liste des cahiers" charge
- ✅ Liste initialement vide (ou cahiers existants)
- ✅ Pas d'erreur de connexion

**Si ❌ "Mode offline":**
- Vérifier que l'URL du backend est correcte dans `main.dart`
- Vérifier que le backend est en cours d'exécution
- Vérifier que le token est valide

---

### Test 4.5: Créer un cahier

**Actions:**
1. Appuyer sur le bouton `+` (FAB)
2. Remplir le formulaire:
   - Titre: "Mon premier cahier"
   - Description: "Description de test"
3. Appuyer "Créer"

**Résultat attendu:**
- ✅ Dialog se ferme
- ✅ Cahier apparaît dans la liste
- ✅ Cahier visible dans PostgreSQL: `SELECT * FROM notebooks`

**Si ❌ :**
- Vérifier les logs Flutter: `flutter logs`
- Vérifier les logs backend: chercher l'erreur
- Vérifier que farm_id=1 existe

---

### Test 4.6: Ouvrir et éditer un cahier

**Actions:**
1. Appuyer sur un cahier de la liste
2. Écran éditeur ouvre (3 onglets: Contenu, Commentaires, Versions)
3. Aller à l'onglet "Contenu"
4. Modifier le titre
5. Appuyer "Enregistrer"

**Résultat attendu:**
- ✅ Formulaire montré
- ✅ Modifications sauvegardées
- ✅ Snackbar "Cahier sauvegardé"
- ✅ Changement visible dans la base de données

---

### Test 4.7: Ajouter un commentaire

**Actions:**
1. Ouvrir un cahier
2. Aller à l'onglet "Commentaires"
3. Entrer: "Ceci est un commentaire"
4. Appuyer "Commenter"

**Résultat attendu:**
- ✅ Commentaire apparaît immédiatement
- ✅ Commentaire visible dans la BD: `SELECT * FROM notebook_comments`

---

### Test 4.8: Voir l'historique

**Actions:**
1. Ouvrir un cahier
2. Aller à l'onglet "Versions"
3. Voir la liste des versions

**Résultat attendu:**
- ✅ Versions affichées avec timestamps
- ✅ Bouton "Restaurer" disponible

---

### Test 4.9: Recherche

**Actions:**
1. Aller à la liste principale
2. Utiliser la barre de recherche
3. Taper: "Mon"
4. Voir les résultats filtrés

**Résultat attendu:**
- ✅ Résultats mis à jour en temps réel
- ✅ Seuls les cahiers correspondant affichés

---

### Test 4.10: Mode offline

**Procédure:**
1. Créer/ouvrir un cahier
2. **Couper la connexion réseau** (mode avion)
3. Essayer de créer/modifier

**Résultat attendu:**
- ✅ "Mode offline" affiché
- ✅ Données locales toujours accessibles
- ✅ Après rétablissement du réseau: "Synchroniser" disponible

---

## 📊 Phase 5: Test d'intégration complète (10 minutes)

### Scénario: Cycle de vie complet

**Étape 1: Créer un cahier depuis Flutter**
```
Actions: Appuyer sur "+", remplir, créer
Vérification: Cahier dans la liste + DB
```

**Étape 2: Modifier depuis Flutter**
```
Actions: Ouvrir, modifier, enregistrer
Vérification: Changement dans DB
```

**Étape 3: Modifier depuis API/DB directement**
```bash
# Vérifier via API
TOKEN="eyJhbg..."
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/notebooks/1
```

**Étape 4: Synchroniser depuis Flutter**
```
Actions: Appuyer "Synchroniser" dans l'app
Vérification: Données mises à jour
```

**Résultat attendu:** ✅ Tous les éléments en sync

---

## 🐛 Logs et débogage

### Logs Flutter

```bash
# Pendant que flutter run s'exécute
flutter logs

# Résultat: Messages détaillés de l'app
# [VERBOSE] Calling NotebookApiProvider.loadNotebooks()
# [INFO] Loaded 5 notebooks
# [ERROR] Network error: Connection refused
```

---

### Logs Backend

```bash
# Dans le terminal du serveur
# Vous verez les requêtes HTTP en temps réel

# INFO:     127.0.0.1:54321 - "POST /api/notebooks HTTP/1.1" 201 Created
# INFO:     127.0.0.1:54322 - "GET /api/notebooks HTTP/1.1" 200 OK
```

---

### Logs PostgreSQL (optionnel)

```bash
# Activer les logs dans postgresql.conf
# log_statement = 'all'

# Puis regarder
tail -f /var/log/postgresql/postgresql.log
```

---

## ✅ Checklist de vérification finale

**Backend:**
- [ ] Serveur uvicorn démarre sans erreur
- [ ] Swagger UI accessible à http://localhost:8000/docs
- [ ] Au moins 6 tables créées dans PostgreSQL
- [ ] endpoint POST /api/notebooks fonctionne
- [ ] endpoint GET /api/notebooks retourne une liste
- [ ] Commentaires créés avec succès
- [ ] Versions fonctionnent
- [ ] Recherche fonctionne

**Frontend:**
- [ ] flutter analyze: 0 erreur
- [ ] flutter run démarre l'app
- [ ] Login réussit
- [ ] Écran cahiers charge
- [ ] Créer un cahier fonctionne
- [ ] Cahier apparaît dans la liste
- [ ] Modifier un cahier fonctionne
- [ ] Ajouter un commentaire fonctionne
- [ ] Mode offline détecte la déconnexion

**Intégration complète:**
- [ ] Créer dans Flutter = créer en DB
- [ ] Modifier dans Flutter = modifier en DB
- [ ] Lecture depuis Flutter = lecture de DB
- [ ] Mode offline fonctionne
- [ ] Synchronisation post-offline réussit

---

## 🎯 Résumé rapide

| Étape | Action | Vérification |
|-------|--------|-------------|
| 1 | `python -m uvicorn app.main:app --reload` | Port 8000 ✅ |
| 2 | `alembic upgrade head` | Tables créées ✅ |
| 3 | `curl http://localhost:8000/docs` | Swagger accessible ✅ |
| 4 | Créer cahier via curl | Cahier en DB ✅ |
| 5 | `flutter run` | App démarre ✅ |
| 6 | Login | Token obtenu ✅ |
| 7 | Créer cahier via app | Cahier en DB ✅ |

---

**Status:** ✅ Procédures de test complètes et vérifiées

**Temps total estimé:** 1-2 heures pour la première fois
