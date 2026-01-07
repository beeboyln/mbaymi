# ✅ Architecture Authentification - Mbaymi Mis à Jour

## Changements Effectués

### Frontend (Flutter)

#### 1. **PublicMarketScreen** (Nouveau)
```
📱 lib/screens/public_market_screen.dart

Ce qui s'affiche:
- Titre "Mbaymi - Marché Public"
- Banneau "Bienvenue sur Mbaymi"
- Texte "Consultez les prix du marché en temps réel"
- Deux boutons: "Devenir agriculteur" | "Se connecter"
- Liste scrollable de tous les prix du marché (PUBLIC)

Caractéristiques:
✅ Chargement des prix via API (GET /api/market/prices)
✅ Gestion des erreurs et retry
✅ Pas de token requis
✅ Boutons navigation vers Register/Login
✅ Modal info au clic sur icône compte
```

#### 2. **HomeScreen** (Modifié)
```
📱 lib/screens/home_screen.dart

Avant:
- home_screen = 5 onglets accessibles sans login

Après:
- Reçoit userToken en paramètre
- Ajoute bouton logout en haut à droite
- Logout ramène à PublicMarketScreen
- Protégé: seulement accessible après login/register

Signature:
const HomeScreen({required this.userToken})
```

#### 3. **LoginScreen** (Modifié)
```
📱 lib/screens/login_screen.dart

Changements:
- Messages en français
- Extraction du token après login réussi
- Navigation vers '/home' avec le token
- Messages d'erreur améliorés
```

#### 4. **RegisterScreen** (Modifié)
```
📱 lib/screens/register_screen.dart

Changements:
- Messages en français ("Inscription réussie!")
- Après inscription réussie → redirection auto login (via /login)
- Plus de pop(), mais pushReplacementNamed('/login')
- Messages d'erreur améliorés
```

#### 5. **main.dart** (Modifié)
```
🚀 lib/main.dart

Avant:
home: const LoginScreen()

Après:
home: const PublicMarketScreen()

Raison: Accès public d'abord, login optionnel

Routes:
/market    → PublicMarketScreen   (défaut, public)
/login     → LoginScreen
/register  → RegisterScreen
/home      → HomeScreen (protégé avec token)
```

### Architecture Flow

```
🎯 Démarrage App
    ↓
PublicMarketScreen (public)
    ├→ Voir marché (GET /api/market/prices - PUBLIC)
    ├→ Clique "Se connecter"
    │   ↓
    │  LoginScreen
    │   ├→ Email + Password
    │   ├→ POST /api/auth/login
    │   └→ Reçoit token
    │       ↓
    │      HomeScreen (avec token)
    │       ├→ Manage farms/livestock
    │       ├→ Get advice
    │       └→ Logout → revient PublicMarketScreen
    │
    └→ Clique "Devenir agriculteur"
        ↓
       RegisterScreen
        ├→ Formulaire complet (name, email, phone, password, role, region, village)
        ├→ POST /api/auth/register
        └→ Redirection auto LoginScreen
            ↓
           Connecte avec nouveau compte
            ↓
           HomeScreen
```

## Backend

### Routes Publiques (SANS token requis)
```
GET /api/market/prices              → Tous les prix
GET /api/market/prices/region/{r}   → Prix par région
GET /api/market/prices/{product}    → Prix produit spécifique

POST /api/auth/register             → Créer compte
POST /api/auth/login                → Connexion
```

### Routes Protégées (token requis - À IMPLÉMENTER)
```
GET /api/farms/                     → Liste fermes utilisateur
POST /api/farms/                    → Créer ferme
POST /api/crops/                    → Ajouter culture
POST /api/livestock/                → Ajouter animal
POST /api/advice/                   → Demander conseil
```

## Fichiers Modifiés

```
✅ frontend/lib/main.dart
   - home: PublicMarketScreen()
   - Ajout import public_market_screen
   - Route '/market' ajoutée

✅ frontend/lib/screens/public_market_screen.dart (NOUVEAU)
   - Écran de marché public
   - Liste des prix (API)
   - Boutons Register/Login

✅ frontend/lib/screens/home_screen.dart
   - Paramètre userToken requis
   - Bouton logout ajouté
   - HomeScreen maintenant protégé

✅ frontend/lib/screens/login_screen.dart
   - Navigation vers '/home'
   - Messages en français
   - Gestion token améliorée

✅ frontend/lib/screens/register_screen.dart
   - Navigation vers '/login' après inscription
   - Messages en français

✅ backend/AUTHENTICATION.md (NOUVEAU)
   - Documentation détaillée du modèle
   - Implémentation frontend/backend
   - Code examples
```

## Tester Localement

### 1. Lancer le backend
```bash
cd backend
python -m uvicorn app.main:app --reload
```

### 2. Lancer l'app Flutter
```bash
cd frontend
flutter run
```

### 3. Tester le flow

**Test Public:**
1. App démarre sur PublicMarketScreen
2. Voir la liste des prix (GET /api/market/prices)
3. Clique bouton logout (aucune connexion requise)

**Test Register:**
1. Clique "Devenir agriculteur"
2. Remplit formulaire (name, email, phone, password, role, region, village)
3. POST /api/auth/register
4. Redirigé automatiquement à LoginScreen
5. Se connecte avec le nouveau compte
6. POST /api/auth/login → reçoit token
7. Navigué vers HomeScreen

**Test Login:**
1. Depuis PublicMarketScreen
2. Clique "Se connecter"
3. Email + Password (compte existant)
4. POST /api/auth/login → reçoit token
5. Navigué vers HomeScreen

**Test Logout:**
1. Depuis HomeScreen
2. Clique icône logout (haut droite)
3. Retour à PublicMarketScreen
4. Token perdu, marché public uniquement

## Sécurité - À Implémenter

### Backend (Priority = HIGH)

```python
# 1. Dependencies.py - Vérifier token
from fastapi import Depends, HTTPException
from jose import jwt, JWTError

def verify_token(token: str = Header(...)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401)
        return user_id
    except JWTError:
        raise HTTPException(status_code=401)

# 2. Utiliser dans les routes
@router.get("/farms/")
def get_farms(user_id: int = Depends(verify_token), db: Session = Depends(get_db)):
    return db.query(Farm).filter(Farm.user_id == user_id).all()

# 3. Hash passwords lors de register
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"])

@router.post("/register")
def register(data: UserCreate, db: Session = Depends(get_db)):
    hashed = pwd_context.hash(data.password)
    user = User(
        name=data.name,
        email=data.email,
        password_hash=hashed,
        ...
    )
    db.add(user)
    db.commit()
    return {"user_id": user.id}

# 4. Vérifier password lors de login
@router.post("/login")
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user or not pwd_context.verify(credentials.password, user.password_hash):
        raise HTTPException(status_code=401)
    
    token = create_access_token({"sub": user.id})
    return {"access_token": token, "token_type": "bearer"}
```

### Frontend (Priority = MEDIUM)

```dart
// 1. Stocker token localement
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

// 2. Vérifier token au démarrage
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  final token = await getToken();
  if (token != null && token.isNotEmpty) {
    // Optionnel: valider token avec backend
    Navigator.pushReplacementNamed(context, '/home');
  }
}

// 3. Envoyer token dans headers API
final response = await http.get(
  Uri.parse('http://localhost:8000/api/farms/'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

## Prochaines Étapes

- [ ] Implémenter verify_token dans backend
- [ ] Implémenter hash password dans backend
- [ ] Implémenter SharedPreferences dans frontend
- [ ] Tester flow complet (register → login → use app → logout)
- [ ] Ajouter expiration token (JWT exp claim)
- [ ] Ajouter refresh token mechanism
- [ ] Tester sur device/emulator
