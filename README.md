# 🌾 Mbaymi - Agricultural Platform

Plateforme numérique tout-en-un pour l'agriculture et l'élevage en Afrique.

## 📋 Vue d'ensemble

Mbaymi connecte **agriculteurs, éleveurs, acheteurs et institutions** pour :
- 📊 Gérer cultures et bétail
- 💡 Recevoir des conseils automatiques
- 💰 Accéder aux prix du marché en temps réel
- 🤝 Se connecter avec d'autres acteurs
- 📈 Contribuer aux données nationales

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│     Flutter Mobile App (Mbaymi)    │
│  (Android/iOS - User Interface)    │
└────────────────┬────────────────────┘
                 │ REST / WebSocket
┌────────────────▼────────────────────┐
│    FastAPI Backend (Python)         │
│  (API, Business Logic, Services)    │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│  PostgreSQL Neon (Cloud Database)   │
│  (Users, Farms, Livestock, Prices)  │
└─────────────────────────────────────┘
```

## 🚀 Phase 1 - MVP Features

### Pour Agriculteurs/Éleveurs
- ✅ Dashboard personnel
- ✅ Gestion parcelle/bétail
- ✅ Conseils automatiques
- ✅ Accès prix marché

### Pour Tous
- ✅ Auth (login/register)
- ✅ Profil utilisateur
- ✅ Notifications basiques

### Base de Données
- ✅ Users (agriculteurs, éleveurs, acheteurs)
- ✅ Farms (parcelles et cultures)
- ✅ Livestock (bétail)
- ✅ Market Prices (prix produits)

## 📦 Dossiers

### Backend
```
backend/
├── app/
│   ├── models/          # SQLAlchemy models (User, Farm, Livestock, etc.)
│   ├── routes/          # API endpoints (auth, farms, livestock, market, advice)
│   ├── schemas/         # Pydantic schemas (validation)
│   ├── services/        # Business logic (AdviceService)
│   ├── database.py      # DB config
│   ├── config.py        # App config
│   └── main.py          # FastAPI app
├── requirements.txt     # Dependencies
├── .env.example         # Configuration template
└── README.md           # Backend documentation
```

### Frontend
```
frontend/
├── lib/
│   ├── models/         # Dart models (User, Farm, Livestock)
│   ├── screens/        # UI screens (Login, Register, Home)
│   ├── services/       # API client (ApiService)
│   ├── widgets/        # Reusable components
│   └── main.dart       # App entry point
├── pubspec.yaml        # Dependencies
└── README.md          # Frontend documentation
```

## 🗄️ Base de Données

### Schema PostgreSQL

```sql
-- Users
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255),
  role VARCHAR(50), -- farmer, livestock_breeder, buyer, seller
  region VARCHAR(100),
  village VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Farms
CREATE TABLE farms (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  name VARCHAR(100) NOT NULL,
  location VARCHAR(200),
  size_hectares FLOAT,
  soil_type VARCHAR(50), -- sandy, loamy, clay
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crops
CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  farm_id INTEGER REFERENCES farms(id),
  crop_name VARCHAR(100) NOT NULL, -- maïs, riz, arachide, etc.
  planted_date TIMESTAMP,
  expected_harvest_date TIMESTAMP,
  quantity_planted FLOAT,
  expected_yield FLOAT,
  status VARCHAR(50) DEFAULT 'growing', -- growing, harvested, failed
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Livestock
CREATE TABLE livestock (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  animal_type VARCHAR(50) NOT NULL, -- cattle, goat, sheep, poultry, pig
  breed VARCHAR(100),
  quantity INTEGER DEFAULT 1,
  age_months INTEGER,
  weight_kg FLOAT,
  health_status VARCHAR(50) DEFAULT 'healthy',
  last_vaccination_date TIMESTAMP,
  feeding_type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market Prices
CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  region VARCHAR(100) NOT NULL,
  price_per_kg FLOAT,
  currency VARCHAR(10) DEFAULT 'CFA',
  price_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  source VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## ⚙️ Setup Complet

### 🪟 Windows Users

**Follow the dedicated Windows setup guide**: [SETUP_WINDOWS.md](SETUP_WINDOWS.md)

Quick start:
```powershell
# Backend setup
cd backend
.\setup_windows.bat
.\run.bat

# Frontend setup (in another terminal)
cd frontend
.\setup_windows.bat
.\run.bat
```

### 🐧 Linux/Mac Users

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure .env
cp .env.example .env
# Edit .env with your database URL

# Run
uvicorn app.main:app --reload
# API at http://localhost:8000
```

**Frontend:**
```bash
cd frontend
flutter pub get
flutter run
```

## 🔗 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | Créer un compte |
| `/api/auth/login` | POST | Se connecter |
| `/api/farms/` | POST | Ajouter une ferme |
| `/api/farms/{id}` | GET | Récupérer une ferme |
| `/api/farms/user/{user_id}` | GET | Fermes d'un utilisateur |
| `/api/livestock/` | POST | Ajouter du bétail |
| `/api/livestock/user/{user_id}` | GET | Bétail d'un utilisateur |
| `/api/market/prices` | GET | Tous les prix |
| `/api/market/prices/{product}` | GET | Prix d'un produit |
| `/api/advice/` | POST | Obtenir conseils |

## 🤖 Service Conseils (Automatisé)

Le `AdviceService` fournit des conseils sans IA basés sur des règles :

**Cultures** : maïs, riz, arachide, millet, tomate, etc.
**Élevage** : bétail, chèvres, moutons, volaille, porcs

```python
# Exemple
advice_service = AdviceService()
advice = advice_service.get_crop_advice("maïs")
# Retourne: {title, advice, tips[], warnings[]}
```

## 📱 Connection Frontend-Backend

Flutter utilise `http` package pour appeler les APIs :

```dart
final advice = await ApiService.getAdvice(
  type: 'crop',
  topic: 'maïs',
  region: 'Dakar'
);
```

**Configuration API URL** (dans `lib/services/api_service.dart`) :
```dart
static const String baseUrl = 'http://localhost:8000/api';
// Pour émulateur Android: 'http://10.0.2.2:8000/api'
```

## 🔐 Configuration Neon PostgreSQL

1. Créer compte sur [neon.tech](https://neon.tech)
2. Créer projet PostgreSQL
3. Copier connection string dans `.env` :
```
DATABASE_URL=postgresql://user:password@host/dbname
```

4. La DB se crée automatiquement au premier lancement du serveur

## 📈 Phases futures

- **Phase 2** : Chat, notifications, uploads photos, système d'achat/vente
- **Phase 3** : Dashboard ministère, analytics, recommandations IA, expansion régionale

## 👥 Rôles Utilisateurs

1. **Farmer** (Agriculteur) : Gère cultures, reçoit conseils
2. **Livestock Breeder** (Éleveur) : Gère bétail, santé animaux
3. **Buyer** (Acheteur) : Cherche produits, voit inventaires
4. **Seller** (Vendeur) : Vend produits, négocie prix
5. **Institution** (Futur) : Accès aux données nationales

## 🌍 Langues

MVP en français/anglais. Extensible à wolof, pulaar, etc.

## 📝 Licences

MIT License - Open source pour adoption africaine

---

**Made for African farmers & breeders 🌾**
"# mbaymi" 
"# mbaymi" 
