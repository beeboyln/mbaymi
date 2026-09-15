# Mbaymi Web Next.js

Nouvelle interface web Mbaymi indépendante de l’application Flutter. Elle utilise le même backend et les mêmes routes API.

## Configuration

Copier `.env.example` vers `.env.local` :

```env
NEXT_PUBLIC_API_BASE_URL=https://burning-yetty-bigboyme-428f3176.koyeb.app/api
```

L’API doit donc exposer les routes d’authentification sous `/api/auth/login` et `/api/auth/refresh`.
La base Neon reste uniquement dans les variables d’environnement du backend Koyeb. Ne jamais mettre `DATABASE_URL` dans ce frontend.

## Développement

```bash
npm install
npm run dev
```

Ouvrir `http://localhost:3000`. La session reçue après connexion est conservée dans `localStorage` sous `mbaymi_session`.

Le script de développement utilise Webpack pour rester compatible avec les installations Windows où le binding natif SWC/Turbopack n'est pas disponible.

## Production

```bash
npm run build
npm run start
```