# 🚀 Deployment & Configuration Guide

## Déploiement Backend (FastAPI)

### Option 1: Koyeb (Recommandé - Gratuit)

1. **Créer compte** : [koyeb.com](https://koyeb.com)

2. **Connecter GitHub** :
   - Settings → Git Provider → Authorize GitHub
   - Pousser backend vers GitHub

3. **Déployer** :
   - Services → Create a web service
   - Select: GitHub → Repository
   - Build: Python (auto-detected)
   - Environment variables:
     ```
     DATABASE_URL=postgresql://...
     SECRET_KEY=your-secret-key
     DEBUG=False
     ```
   - Port: 8000

### Option 2: Render

1. Créer compte [render.com](https://render.com)
2. New → Web Service
3. Connect GitHub repo
4. Environment:
   ```
   DATABASE_URL=postgresql://...
   SECRET_KEY=...
   ```
5. Deploy

### Option 3: Railway

Similar à Render, très simple.

## Déploiement Frontend (Flutter)

### Android Release

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk
```

**Distribuer** :
- Google Play Store
- ou APK direct (fichier `.apk`)

### iOS Release

```bash
flutter build ios --release
# Xcode → Product → Archive
```

**Distribuer** : App Store

### Web (Bonus)

```bash
flutter build web --release
# Deploy static files sur Vercel/Netlify
```

## Configuration Neon PostgreSQL

1. **Créer base** : neon.tech → New Project
2. **Copier URL** dans `.env` :
   ```
   DATABASE_URL=postgresql://...neon.tech/mbaymi
   ```
3. **Backup auto** : Neon gère automatiquement

## Configuration Firebase (Optionnel - Phase 2)

Pour notifications Push :

1. Créer projet Firebase
2. Download `google-services.json` (Android)
3. Download `GoogleService-Info.plist` (iOS)
4. Ajouter dépendances Flutter

## Variables d'environnement

### Backend (.env)

```
# Database
DATABASE_URL=postgresql://user:pass@host/db

# JWT
SECRET_KEY=your-long-random-secret-key-here

# App
DEBUG=False
ALLOWED_ORIGINS=https://yourdomain.com,http://localhost:3000
```

### Frontend (lib/services/api_service.dart)

```dart
static const String baseUrl = 'https://api.yourdomain.com/api';
// En développement: 'http://localhost:8000/api'
```

## SSL Certificates

Koyeb/Render fournissent automatiquement HTTPS.

Pour custom domain :
- Koyeb: Auto avec Let's Encrypt
- Render: Auto avec Let's Encrypt
- Railway: Auto

## CI/CD avec GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Koyeb
        run: |
          # Koyeb CLI commands
          koyeb apps deploy mbaymi-backend --git github.com/user/mbaymi
```

## Monitoring

### Logs Backend

```bash
# Koyeb
koyeb logs mbaymi-api

# Render
# Dashboard → Logs tab

# Local
tail -f uvicorn.log
```

### Performance

- **Koyeb** : Free tier (1 web service) - sufficient for MVP
- **Database** : Neon free tier (3GB) - sufficient for MVP
- **Flutter APK** : ~70-90 MB

## Scaling (Phase 2+)

Quand utilisateurs augmentent :

1. **Backend** : Upgrade Koyeb instance
2. **Database** : Upgrade Neon plan
3. **Caching** : Ajouter Redis (Upstash)
4. **CDN** : Ajouter Cloudflare
5. **Storage** : Images → Cloudinary/S3

## Cost Estimate (Monthly)

| Service | Cost |
|---------|------|
| Koyeb (web service) | Free - $4 |
| Neon PostgreSQL | Free - $15 |
| Firebase (optional) | Free - $10 |
| Domain | $10 |
| **Total** | **$10-39** |

## Checklist Déploiement

- [ ] Repository GitHub créé et code pushé
- [ ] `.env.example` documenté
- [ ] Base de données Neon créée
- [ ] Backend déployé (Koyeb/Render)
- [ ] Frontend testé avec API réelle
- [ ] Flutter APK compilé
- [ ] Custom domain configuré
- [ ] Tests de sécurité faits
- [ ] Monitoring configuré

---

**Ready to scale! 🚀**
