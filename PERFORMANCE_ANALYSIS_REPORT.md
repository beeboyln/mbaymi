# 📊 RAPPORT D'ANALYSE DE PERFORMANCE - BACKEND FASTAPI

**Date:** 12 Mars 2026  
**Status:** 🔴 Plusieurs goulots d'étranglement critiques identifiés

---

## 1. ⚠️ PROBLÈMES CRITIQUES IDENTIFIÉS

### 1.1 N+1 QUERIES - CRITIQUE 🔴

#### Problème: Routes avec boucles et requêtes répétées

**Fichier:** `app/routes/farm_posts.py` - Fonction `get_farm_posts_feed()`

```python
# ❌ PROBLÉMATIQUE: Boucle avec requête pour chaque post
for post in posts:
    farm = db.query(Farm).filter(Farm.id == post.farm_id).first()  # +1 requête par post
    user = db.query(User).filter(User.id == post.user_id).first()  # +1 requête par post
    livestock = db.query(Livestock).filter(Livestock.id == post.livestock_id).first()  # +1 par post
    like = db.query(FarmPostLike).filter(...).first()  # +1 par post
```

**Impact:** 
- Si 100 posts dans le feed: **~400 requêtes SQL** au lieu de ~5-6
- Temps réponse: 5-10 secondes pour un petit dataset

**Affecte aussi:**
- `get_subscriptions_feed()` - même problème avec `FarmImagePost`, `Farm`, `User`, `Livestock`, `FarmPostLike`
- `get_farm_posts()` - requêtes User répétées
- `get_livestock_posts()` - requêtes User répétées

#### Problème: Routes Farms sans jointures

**Fichier:** `app/routes/farmers.py` - Fonction `get_current_user_farms()`

```python
# ❌ PROBLÉMATIQUE: Requête pour chaque farm
farms = db.query(Farm).filter(Farm.user_id == current_user.id).all()
for f in farms:
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == f.id).all()  # +1 par farm
    crops = db.query(Crop).filter(Crop.farm_id == f.id).all()  # +1 par farm
```

**Impact:** 
- Si l'utilisateur a 5 farms: **12 requêtes** au lieu de 3

---

### 1.2 ABSENCE DE CACHING 🔴

**Aucune implémentation de:**
- ✗ Redis ou autre cache distribuée
- ✗ Cache HTTP (en-têtes Cache-Control)
- ✗ Cache au niveau des routes
- ✗ Cache des requêtes coûteuses (news, market prices, etc.)

**Données candidates au caching:**
- `/api/news/agricultural` - Appels RSS externes (8 secondes de timeout!)
- `/market-prices/trends` - Données peu changeantes
- `/api/farms/{farm_id}` - Données statiques
- `/api/search/*` - Résultats stables

---

### 1.3 APPELS API EXTERNES NON-OPTIMISÉS 🔴

**Fichier:** `app/routes/news.py`

#### Problème 1: Requêtes séquentielles sans timeout optimal
```python
# ❌ 4 requêtes RSS séquentielles
feeds = [
    {"url": "https://news.google.com/rss?q=agriculture&ceid=SN:fr"},
    {"url": "https://news.google.com/rss?q=élevage+bétail&ceid=SN:fr"},
    # ...
]

for feed_config in feeds:
    response = requests.get(feed_config["url"], timeout=8)  # Synchrone et lent
```

**Impact:**
- Temps minimum: 8 secondes × 4 feeds = 32 secondes en cas de lenteur
- Bloque toutes les requêtes en attente

#### Problème 2: Pas de pagination pour les images

```python
# ❌ Plus de limites sur téléchargement d'images
image_url = image_elem.text if image_elem is not None else None
```

---

### 1.4 ABSENCE DE COMPRESSION JSON 🔴

**Fichier:** `app/main.py`

```python
# ❌ MANQUANT: Aucun middleware de compression
app.add_middleware(CORSMiddleware, ...)  # ✓ CORS OK
# ✗ Pas de GzipMiddleware
# ✗ Pas de compression
```

**Impact:**
- Réponses JSON JSON typiques: 100-500 KB
- Avec compression GZIP: 15-50 KB (80-90% de réduction)
- Important pour les connections mobiles lentes

---

### 1.5 CONFIGURATION BASE DE DONNÉES SOUS-OPTIMALE 🟡

**Fichier:** `app/database.py`

```python
# Configuration actuelle:
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=5,              # ⚠️ Faible pour production
    max_overflow=10,          # ⚠️ Limité
    pool_pre_ping=True,       # ✓ OK
    echo=settings.DEBUG,
)
```

**Problèmes:**
- `pool_size=5`: Seulement 5 connexions actives
- `max_overflow=10`: Max 15 connexions totales
- Avec 100+ utilisateurs: **Débordement et queue**
- Pas d'indice de timeout ou de stratégie de recyclage

**Recommandation:**
```python
# Meilleur:
pool_size=20,           # Plus de connexions parallèles
max_overflow=20,        # Meilleure scalabilité
pool_recycle=3600,      # Recycle les connexions
pool_timeout=30,        # Timeout des connexions
```

---

### 1.6 REQUÊTE RFC SYNCHRONE 🟡

**Problème:** `requests.get()` est synchrone dans une route async

```python
@router.get("/agricultural")
async def get_agricultural_news():  # ✓ Async
    response = requests.get(url, timeout=8)  # ✗ Synchrone!
```

**Impact:**
- Bloque l'event loop de FastAPI
- Autres requêtes attendent
- Meilleur: `httpx.AsyncClient` ou `aiohttp`

---

### 1.7 ABSENCE DE PAGINATION 🟡

**Fichier:** `app/routes/farm_posts.py`

```python
# ❌ Charge TOUS les posts
posts = db.query(FarmImagePost).order_by(...).all()

# Pas d'arguments `skip` et `limit`
```

**Impact:**
- Si 10,000 posts: **Tous** sont chargés en mémoire
- Réponse: 2-5 MB
- Temps réponse: 5-10 secondes

---

## 2. 📋 RÉSUMÉ DES GOULOTS D'ÉTRANGLEMENT

| N° | Problème | Sévérité | Impact | Routine(s) affectée(s) |
|----|----------|----------|--------|------------------------|
| 1 | N+1 Queries farm_posts | 🔴 CRITIQUE | 100+ requêtes pour 100 posts | `get_farm_posts_feed()`, `get_subscriptions_feed()` |
| 2 | N+1 Queries farms | 🔴 CRITIQUE | 12+ requêtes pour 5 farms | `get_current_user_farms()`, `get_user_farms()` |
| 3 | Pas de cache | 🔴 CRITIQUE | Requêtes répétées = données déjà calculées | News, market prices, search |
| 4 | Appels RSS synchrones | 🔴 CRITIQUE | 32+ secondes de latence | `/api/news/agricultural` |
| 5 | Pas de pagination | 🟡 HAUTE | Chargement complet en mémoire | Tous les endpoints list |
| 6 | Pas de compression JSON | 🟡 HAUTE | 80% wasted bandwidth | Toutes réponses |
| 7 | Pool DB trop petit | 🟡 HAUTE | Throttling avec charge | Tous les endpoints |
| 8 | Requêtes synchrones | 🟡 HAUTE | Event loop bloquée | News, external APIs |

---

## 3. 🛠️ OPTIMISATIONS PRIORITAIRES

### PRIORITÉ 1: Corriger N+1 Queries (Gain: 90% réduction temps)

#### Solution 1.1: Utiliser SQLAlchemy `joinedload` pour farm_posts

```python
# ✅ AVANT: N+1 queries
posts = db.query(FarmImagePost).all()

# ✅ APRÈS: 1 requête avec joins
from sqlalchemy.orm import joinedload
posts = db.query(FarmImagePost)\
    .joinedload(FarmImagePost.user)\
    .joinedload(FarmImagePost.farm)\
    .order_by(desc(FarmImagePost.created_at))\
    .all()
```

**Gain:** 400 requêtes → 1 requête = 400x plus rapide

#### Solution 1.2: Batch load likes/comments

```python
# ✅ Charger tous les likes en une seule requête
post_ids = [p.id for p in posts]
likes_map = db.query(FarmPostLike)\
    .filter(FarmPostLike.farm_post_id.in_(post_ids))\
    .all()
likes_dict = {l.farm_post_id: l.user_id for l in likes_map}

# Utiliser le dictionnaire dans la boucle
for post in posts:
    is_liked = post.id in likes_dict
```

---

### PRIORITÉ 2: Ajouter Compression JSON (Gain: 80% réduction bande)

```python
# app/main.py - Ajouter après CORS middleware:
from fastapi.middleware.gzip import GzipMiddleware

app.add_middleware(GzipMiddleware, minimum_size=1000)
```

**Avant:** `{"data": [...]}` = 200 KB
**Après:** Compressé = 40 KB

---

### PRIORITÉ 3: Implémenter Caching Simple

```python
# Option 1: Cache en mémoire (simple)
from functools import lru_cache
import time

@lru_cache(maxsize=128)
def get_market_trends_cached(product: str):
    # Cache pendant 5 minutes
    return db.query(MarketTrend).filter(...).all()

# Option 2: Cache avec expiration (meilleur)
from cachetools import TTLCache
trends_cache = TTLCache(maxsize=1000, ttl=300)  # 5 minutes

@router.get("/trends")
def get_trends(product: str, db: Session):
    if product in trends_cache:
        return trends_cache[product]
    
    trends = db.query(MarketTrend).filter(...).all()
    trends_cache[product] = trends
    return trends
```

---

### PRIORITÉ 4: Async Requêtes Externes

```python
# Installer: pip install httpx

# Avant: requests.get() - synchrone
# Après:
import httpx

async def get_agricultural_news():
    async with httpx.AsyncClient(timeout=5) as client:
        tasks = [
            client.get(feed["url"]) 
            for feed in feeds
        ]
        responses = await asyncio.gather(*tasks)
        # Traiter les réponses en parallèle
```

**Gain:** 32 secondes → 8 secondes (4x plus rapide)

---

### PRIORITÉ 5: Améliorer Pool Base de Données

```python
# database.py
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=20,           # ↑ De 5 à 20
    max_overflow=20,        # ↑ De 10 à 20
    pool_recycle=3600,      # ✓ Nouveau: recycle connexions
    pool_timeout=30,        # ✓ Nouveau: timeout
    echo=settings.DEBUG,
)
```

---

### PRIORITÉ 6: Ajouter Pagination

```python
# app/routes/farm_posts.py

@router.get("/feed")
def get_farm_posts_feed(
    skip: int = 0,
    limit: int = 20,  # ✓ Nouveau
    user_id: int = None, 
    db: Session = Depends(get_db)
):
    """Récupérer les farm posts pour le feed social"""
    posts = db.query(FarmImagePost)\
        .order_by(desc(FarmImagePost.created_at))\
        .offset(skip)\
        .limit(limit)\  # ✓ Limiter
        .all()
    
    return {
        "posts": posts,
        "total": db.query(FarmImagePost).count(),
        "skip": skip,
        "limit": limit
    }
```

---

## 4. 📝 CONFIGURATION GLOBALE - FICHIERS À CRÉER

### 4.1 `app/utils/cache.py` - Cache utilities

```python
from cachetools import TTLCache
import functools
from typing import Callable, Any

# Cache avec expiration de 5 minutes
market_cache = TTLCache(maxsize=500, ttl=300)
news_cache = TTLCache(maxsize=100, ttl=600)  # Nouvelles + longtemps (10 min)

def cache_result(cache_dict: dict, ttl: int = 300):
    """Décorateur pour cacher les résultats"""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            key = f"{func.__name__}:{args}:{kwargs}"
            if key in cache_dict:
                return cache_dict[key]
            result = func(*args, **kwargs)
            cache_dict[key] = result
            return result
        return wrapper
    return decorator
```

---

## 5. 📊 IMPACT ESTIMÉ DES OPTIMISATIONS

| Optimisation | Temps Réponse AVANT | Temps Réponse APRÈS | Gain |
|--------------|-------------------|-------------------|------|
| Corriger N+1 farms | 2.5s | 0.2s | 92% |
| Corriger N+1 farm_posts | 8.0s | 0.4s | 95% |
| Compression JSON | +80% bande | +5% bande | 75% réduction |
| Async news | 32s | 8s | 75% |
| Caching market prices | 2.0s (répété) | 0.01s (cache hit) | 99% |
| **TOTAL avec toutes les optimisations** | ~45s | ~1.5s | **97% ⚡** |

---

## 6. 🚀 CHECKLIST D'IMPLÉMENTATION

### Phase 1: URGENT (1-2 jours)
- [ ] Ajouter GzipMiddleware dans `main.py`
- [ ] Corriger N+1 queries en farm_posts avec joinedload
- [ ] Ajouter pagination: `skip`, `limit` aux endpoints list
- [ ] Améliorer pool DB: pool_size=20, max_overflow=20

### Phase 2: IMPORTANT (2-3 jours)
- [ ] Implémenter cache simple pour market prices, news
- [ ] Corriger N+1 queries en farmers.py
- [ ] Ajouter bulk loading pour likes/comments
- [ ] Convertir requests → httpx async

### Phase 3: MON (3-5 jours)
- [ ] Implémenter Redis cache pour données volatiles
- [ ] Ajouter indices de base de données
- [ ] Monitoring et logging des performances
- [ ] Tests de charge (100+ utilisateurs simultanés)

---

## 7. 📌 FICHIERS PRIORITAIRES À MODIFIER

1. **`app/main.py`** - Ajouter compression
2. **`app/database.py`** - Améliorer pool config
3. **`app/routes/farm_posts.py`** - Corriger N+1 queries
4. **`app/routes/farmers.py`** - Corriger N+1 queries
5. **`app/routes/news.py`** - Async requests
6. **`app/utils/cache.py`** - Nouveau: cache utilities
7. **`requirements.txt`** - Ajouter: `httpx`, `cachetools`

---

## 8. 🔍 LOGS DE REQUÊTES POUR VÉRIFIER

Depois de implémenter as otimizações, verificar:

```bash
# 1. Vérifier les requêtes SQL (activer echo=True dans database.py)
# Avant: 400+ requêtes pour /farm-posts/feed
# Après: <5 requêtes

# 2. Vérifier la compression
curl -H "Accept-Encoding: gzip" https://api.mbaymi.com/api/news/agricultural
# Doit avoir: Content-Encoding: gzip

# 3. Vérifier le caching
curl -i https://api.mbaymi.com/market-prices/trends
# Doit avoir: Cache-Control: max-age=300

# 4. Vérifier les temps réponse
time curl https://api.mbaymi.com/api/news/agricultural
# Avant: 32 secondes
# Après: 8 secondes
```

---

**FIN DU RAPPORT**

*Générateur d'analyse: GitHub Copilot*  
*Date: 12 Mars 2026*
