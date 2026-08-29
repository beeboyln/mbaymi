# Checklist Déploiement Production - Cache & Pagination

## 🔥 Avant de Pousser en Production

### 1. Backend Preparation

- [ ] **Run Database Indexes Script**
  ```bash
  cd backend
  python add_db_indexes.py
  ```
  Cela crée les indexes pour:
  - sales (user_id, created_at, category)
  - farm (user_id, created_at, location)
  - livestock (user_id, created_at, animal_type, visibility)
  - farm_image_post (user_id, farm_id)

- [ ] **Verify API Endpoints**
  Test les nouveaux endpoints avant deploy:
  ```bash
  # Local test
  python -m app.main &
  
  # Test pagination
  curl "http://localhost:8000/api/sales/?page=1&limit=20"
  curl "http://localhost:8000/api/farms/user/1?page=1&limit=20&location=Dakar"
  curl "http://localhost:8000/api/livestock/user/1?page=1&limit=20"
  
  # Test stats
  curl "http://localhost:8000/api/farms/1/stats"
  curl "http://localhost:8000/api/farms/1/financial-summary"
  ```

- [ ] **Database Backup**
  ```bash
  # PostgreSQL
  pg_dump -h $DB_HOST -U $DB_USER $DB_NAME > backup_$(date +%Y%m%d).sql
  
  # Or if using managed DB (Koyeb, Railway, etc.)
  # Use their built-in backup feature
  ```

- [ ] **Performance Test**
  Create sample data and measure:
  - Query time with indexes
  - Pagination response time
  - Stats aggregation time

### 2. Frontend Preparation

- [ ] **Update API Calls for Pagination**
  Adapter les écrans qui utilisent les endpoints modifiés:
  - `MarketScreen`: Implémenter pagination UI
  - `FarmProfileScreen`: Adapter pour pagination
  - `UserProfileScreen`: Si nécessaire

- [ ] **Test on Device**
  ```bash
  flutter run --release
  ```
  Vérifier:
  - Load de listes fonctionnent
  - Pagination (si implémentée UI)
  - Cache invalidation après actions
  - No memory leaks avec longues listes

- [ ] **Analyze for Warnings**
  ```bash
  flutter analyze --no-pub
  ```
  Résoudre warnings critiques (ne pas laisser deprecated APIs)

- [ ] **Run All Tests**
  ```bash
  flutter test
  ```
  ✅ Tous les tests doivent passer

### 3. Deployment Steps

#### Option A: Vercel/Railway (Recommandé)

**Backend**:
```bash
# Push à production
git add backend/
git commit -m "feat: pagination backend + indexes"
git push origin main

# CI/CD va:
# 1. Build Docker image
# 2. Run tests
# 3. Deploy to Koyeb/Railway
# 4. Run migrations (si nécessaire)
```

**Frontend**:
```bash
# Push à production
git add frontend/
git commit -m "feat: cache architecture + pagination prep"
git push origin main

# Vercel va:
# 1. Build Flutter web
# 2. Run tests
# 3. Deploy to Vercel edge
```

#### Option B: Manual Deployment

**Backend**:
```bash
# SSH to server
ssh user@backend-server

# Pull latest code
cd /app/mbaymi/backend
git pull origin main

# Run indexes
python add_db_indexes.py

# Restart server
systemctl restart mbaymi-api
# ou
docker-compose restart api
```

**Database**:
```bash
# If needed, run any pending migrations
# (currently using Base.metadata.create_all())
# In future, run Alembic:
# alembic upgrade head
```

### 4. Post-Deployment Verification

- [ ] **Check Logs**
  ```bash
  # Backend logs
  docker logs -f mbaymi-backend
  # ou
  tail -f /var/log/mbaymi/api.log
  ```
  Vérifier: No errors, indexes créés avec succès

- [ ] **Monitor Performance**
  - Comparer query times avant/après
  - Vérifier cache hit rates
  - Monitor memory usage

- [ ] **Frontend Health Check**
  - Load app en production
  - Navigate different screens
  - Create/edit/delete items
  - Verify cache invalidation works

- [ ] **Database Health Check**
  ```sql
  -- PostgreSQL
  SELECT schemaname, tablename, indexname 
  FROM pg_indexes 
  WHERE tablename IN ('sale', 'farm', 'livestock');
  
  -- Verify no slow queries
  SELECT query, mean_time, calls 
  FROM pg_stat_statements 
  ORDER BY mean_time DESC LIMIT 10;
  ```

- [ ] **Test Pagination in Production**
  ```bash
  curl "https://api.mbaymi.com/api/sales/?page=1&limit=20"
  curl "https://api.mbaymi.com/api/farms/user/123?page=1&limit=20"
  ```

### 5. Rollback Plan

Si quelque chose casse:

**Option 1: Immediate Rollback**
```bash
# Backend
git revert <commit-hash>
git push origin main
# CI/CD redeploy automatically

# Frontend
# Vercel auto-rollback previous deployment
```

**Option 2: Disable Pagination (Soft Fallback)**
If pagination endpoints crash, frontend still works with:
- Old non-paginated endpoints (if kept)
- Local pagination in memory
- Cache-only mode (serve cached data)

**Option 3: Database Rollback**
```bash
# If indexes cause issues
DROP INDEX IF EXISTS idx_sales_user_id_created_at;
DROP INDEX IF EXISTS idx_farm_user_id_created_at;
# etc.
```

### 6. Monitoring Checklist

**Set up Monitoring**:
- [ ] API response times (target: <100ms)
- [ ] Cache hit rates (target: >80% for repeat requests)
- [ ] Database slow query log
- [ ] Memory usage on frontend
- [ ] Error rates on new endpoints

**Tools**:
- Sentry for error tracking
- DataDog/New Relic for performance
- Grafana for metrics visualization

---

## 📋 Checklist Complet

```
PRÉ-DEPLOYMENT
  [ ] Backend compilation OK
  [ ] Frontend compilation OK
  [ ] All tests passing
  [ ] Database backup taken
  [ ] Code reviewed

DEPLOYMENT
  [ ] Backend deployed
  [ ] Database indexes created
  [ ] Frontend deployed
  [ ] DNS/routing verified

POST-DEPLOYMENT  
  [ ] No errors in logs
  [ ] APIs responding <100ms
  [ ] Cache working correctly
  [ ] Pagination endpoints tested
  [ ] Frontend loads data correctly
  [ ] Stats endpoints returning valid data
  [ ] Mobile app tested
  [ ] Desktop app tested

MONITORING
  [ ] Performance dashboard active
  [ ] Alerting configured
  [ ] Logs aggregated
  [ ] Error tracking enabled

DOCUMENTATION
  [ ] Architecture documented ✅
  [ ] API changes documented ✅
  [ ] Rollback procedure documented ✅
  [ ] Monitoring instructions documented
```

---

## 🆘 Troubleshooting

### Problème: Pagination endpoints retournent 500 error

**Solution**:
```bash
# Vérifier les imports dans farm_stats.py
python -c "from app.routes import farm_stats; print('OK')"

# Vérifier que farm_stats est bien importé dans main.py
grep "farm_stats" app/main.py
```

### Problème: Indexes ne sont pas créés

**Solution**:
```bash
# Exécuter le script avec verbose output
python add_db_indexes.py

# Vérifier directement si indexes existent
psql -c "SELECT * FROM pg_indexes WHERE tablename IN ('sale', 'farm');"
```

### Problème: Cache ne s'invalide pas après créer item

**Solution**:
- Vérifier que `AppEventBus.emit()` est appelé dans ApiService
- Vérifier que écran écoute les events
- Check que `mounted` flag est correct dans widget

### Problème: Queries encore lentes malgré indexes

**Solution**:
```bash
# Analyser query plan
EXPLAIN ANALYZE SELECT * FROM sale WHERE user_id = 1 ORDER BY created_at DESC LIMIT 20;

# Indexes peuvent pas être utilisés si:
# - Colonne type incompatible (int vs text)
# - Stats pas à jour: ANALYZE; REINDEX;
```

---

## 📞 Questions?

Pour support:
1. Vérifier logs backend: `docker logs mbaymi-backend`
2. Vérifier logs frontend: Browser console (F12)
3. Vérifier database: `psql` ou pgAdmin
4. Revert si urgent: `git revert + push`

---

**Status**: 🟢 READY FOR PRODUCTION
**Last Review**: 2026-08-29
