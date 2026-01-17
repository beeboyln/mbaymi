# 🌾 Mbaymi Backend

API FastAPI pour la plateforme Mbaymi d'agriculture et d'élevage.

## 🚀 Setup

### 1. Dépendances

```bash
pip install -r requirements.txt
```

### 2. Configuration

Copier `.env.example` vers `.env` et mettre à jour :

```bash
cp .env.example .env
```

Remplir :
- `DATABASE_URL` : URL de connexion PostgreSQL Neon
- `SECRET_KEY` : Clé secrète pour JWT

### 3. Base de données

```bash
# Migration Alembic (optionnel)
alembic init
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### 4. Lancer le serveur

```bash
uvicorn app.main:app --reload
```

Server disponible à : `http://localhost:8000`

## 📚 API Endpoints

### Auth
- `POST /api/auth/register` - Créer un compte
- `POST /api/auth/login` - Se connecter

### Info
- `GET /version` - Retourne le nom de l'application, la version, le timestamp de build (UTC) et le commit Git si fourni via `GIT_COMMIT`.

### Farms
- `POST /api/farms/` - Créer une ferme
- `GET /api/farms/{farm_id}` - Récupérer une ferme
- `GET /api/farms/user/{user_id}` - Récupérer les fermes d'un utilisateur
- `POST /api/farms/{farm_id}/crops` - Ajouter une culture
- `GET /api/farms/{farm_id}/crops` - Récupérer les cultures d'une ferme

### Livestock
- `POST /api/livestock/` - Ajouter du bétail
- `GET /api/livestock/{livestock_id}` - Récupérer un bétail
- `GET /api/livestock/user/{user_id}` - Récupérer le bétail d'un utilisateur
- `PUT /api/livestock/{livestock_id}` - Mettre à jour du bétail

### Market
- `GET /api/market/prices` - Récupérer tous les prix du marché
- `GET /api/market/prices/region/{region}` - Récupérer les prix par région
- `GET /api/market/prices/{product}` - Récupérer les prix d'un produit

### Advice
- `POST /api/advice/` - Obtenir des conseils (cultures/élevage)

## 🗄️ Structure DB

```
users
├── id (PK)
├── name, email, phone
├── password_hash
├── role (farmer, livestock_breeder, buyer, seller)
├── region, village
└── created_at, updated_at

farms
├── id (PK)
├── user_id (FK)
├── name, location, size_hectares, soil_type
└── created_at, updated_at

crops
├── id (PK)
├── farm_id (FK)
├── crop_name, planted_date, expected_harvest_date
├── quantity_planted, expected_yield, status
└── created_at, updated_at

livestock
├── id (PK)
├── user_id (FK)
├── animal_type, breed, quantity, age_months, weight_kg
├── health_status, last_vaccination_date, feeding_type, location
└── created_at, updated_at

market_prices
├── id (PK)
├── product_name, region, price_per_kg, currency
├── price_date, source
└── created_at
```

## 🤖 Service Conseils

Le `AdviceService` fournit des conseils automatiques basés sur des règles pour :

**Cultures** : maïs, riz, arachide, millet, tomate
**Élevage** : bétail, chèvres, moutons, volaille, porcs

Exemple d'utilisation:
```python
advice_service = AdviceService()
advice = advice_service.get_crop_advice("maïs")
```

## 📝 Notes

- Utilise PostgreSQL avec Neon
- JWT pour authentification (à implémenter complètement)
- CORS activé pour Flutter frontend
- Pas d'IA au début - règles prédéfinies uniquement
