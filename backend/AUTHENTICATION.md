# Architecture Authentification - Mbaymi

## Modèle d'Accès

### 1. Accès Public (Sans Authentification)
```
Écran: PublicMarketScreen
Routes accessibles:
- GET /api/market/prices            (Tous les prix)
- GET /api/market/prices/region/{region}  (Par région)
- GET /api/market/prices/{product}  (Par produit)

Fonctionnalités:
✅ Voir les prix du marché en temps réel
✅ Parcourir les produits disponibles
✅ Voir les régions et prix par kg
❌ Gérer fermes/cultures
❌ Gérer bétail/animaux
❌ Recevoir conseils personnalisés
```

### 2. Accès Authentifié (Après Login/Register)
```
Écran: HomeScreen (avec userToken)
Routes protégées:
- POST /api/auth/register          (Inscription)
- POST /api/auth/login             (Connexion)
- GET /api/farms/                  (Lister fermes)
- POST /api/farms/                 (Créer ferme)
- POST /api/crops/                 (Ajouter cultures)
- POST /api/livestock/             (Ajouter animaux)
- POST /api/advice/                (Demander conseils)

Fonctionnalités:
✅ Tout ce qui est public
✅ Gérer vos fermes et cultures
✅ Gérer votre bétail
✅ Recevoir conseils personnalisés
✅ Accéder au marché détaillé
✅ Se déconnecter
```

## Flux d'Utilisateur

### Nouveau Visiteur
```
1. Démarre l'app
   ↓ (PublicMarketScreen par défaut)
2. Voit le marché public
   ↓ (Bouton "Devenir agriculteur" ou "Se connecter")
3. Clique sur un bouton
   ↓ (Va à RegisterScreen ou LoginScreen)
4. Remplit le formulaire
   ↓ (API envoie user_id + role + region)
5. Après inscription/login → HomeScreen
   ↓ (Peut maintenant accéder toutes features)
6. Clique logout
   ↓ (Retour à PublicMarketScreen)
```

### Utilisateur Existant
```
1. Démarre l'app
   ↓ (PublicMarketScreen)
2. Clique "Se connecter"
   ↓ (LoginScreen)
3. Entre email/password
   ↓ (API valide et retourne token)
4. Reçoit token et va à HomeScreen
   ↓ (Peut gérer ses fermes/bétail)
5. Clique logout
   ↓ (Token supprimé, retour marché public)
```

## Implémentation Frontend

### Navigation Routes
```dart
routes: {
  '/market':    PublicMarketScreen(),    // Défaut (accès public)
  '/login':     LoginScreen(),           // Authentification
  '/register':  RegisterScreen(),        // Inscription
  '/home':      HomeScreen(token),       // Protégé (avec token)
}
```

### Gestion du Token
```dart
// Dans LoginScreen/RegisterScreen:
final token = response['access_token'];

// Navigation sécurisée:
Navigator.pushReplacementNamed(context, '/home');

// Lors du logout dans HomeScreen:
Navigator.pushNamedAndRemoveUntil(
  context,
  '/market',
  (route) => false,
);
```

### API Service
```dart
class ApiService {
  // Public (pas de token requis)
  static Future<List<MarketPrice>> getMarketPrices() { }
  
  // Authentification (pas de token pour s'enregistrer/connecter)
  static Future<Map> register(...) { }
  static Future<Map> login(...) { }
  
  // Protégé (token requis dans header)
  static Future<List<Farm>> getFarms(token) { }
  static Future<void> addLivestock(token, data) { }
  static Future<Advice> getAdvice(token, data) { }
}
```

## Implémentation Backend

### Routes Publiques (dans market.py)
```python
@router.get("/prices")
def get_all_prices(db: Session = Depends(get_db)):
    # ✅ SANS authentification
    prices = db.query(MarketPrice).all()
    return prices
```

### Routes Protégées (dans farmers.py, livestock.py, advice.py)
```python
from app.dependencies import verify_token

@router.get("/farms/")
def get_farms(token: str = Depends(verify_token), db: Session = Depends(get_db)):
    # ✅ AVEC vérification token
    user = get_user_from_token(token, db)
    return db.query(Farm).filter(Farm.user_id == user.id).all()
```

### Authentification (dans auth.py)
```python
# Public - pas de token requis
@router.post("/register")
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Crée nouvel utilisateur
    return {"user_id": user.id, "message": "User created"}

@router.post("/login")
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    # Vérifie password et retourne token
    token = create_access_token(user.id)
    return {"access_token": token, "token_type": "bearer"}
```

## Sécurité

### À Implémenter
```python
# 1. Vérification du token dans les routes protégées
from fastapi import Depends, HTTPException
from jose import jwt

def verify_token(token: str = Header(...)) -> int:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401)
        return user_id
    except:
        raise HTTPException(status_code=401)

# 2. Utiliser dans les routes
@router.get("/farms/")
def get_farms(user_id: int = Depends(verify_token), ...):
    # user_id est automatiquement extrait du token
    pass

# 3. Hash des passwords
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"])

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

## Avantages du Modèle Freemium

✅ **Engagement immédiat** - Voir le marché sans friction
✅ **Conversion naturelle** - "Devenir agriculteur" à portée
✅ **Sécurité** - Données personnelles protégées par authentification
✅ **Données publiques** - Marché visible, encourage participation
✅ **Monétisation future** - Services premium possibles

## Prochaines Étapes

1. ✅ **Frontend**: PublicMarketScreen + navigation
2. ✅ **Frontend**: HomeScreen protégé
3. ⏳ **Backend**: verify_token middleware
4. ⏳ **Backend**: Hash passwords en production
5. ⏳ **Backend**: JWT tokens (longueur, expiration)
6. ⏳ **Frontend**: Stocker token localement (SharedPreferences)
7. ⏳ **Frontend**: Vérifier token à chaque démarrage app
