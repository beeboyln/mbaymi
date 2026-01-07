# Deploying the Flutter web frontend to Vercel

This repo includes a GitHub Action that builds the Flutter web app and deploys it to Vercel.

Prerequisites
- A Vercel account and a project created (or you can let the action create it via token + org/project ids).
- Set the following GitHub repository secrets:
  - `VERCEL_TOKEN` — your Vercel personal token
  - `VERCEL_ORG_ID` — your Vercel organization id
  - `VERCEL_PROJECT_ID` — your Vercel project id

How it works
1. On push to `main`, the workflow `Build and Deploy Flutter Web to Vercel` runs.
2. The workflow installs Flutter, runs `flutter pub get`, builds `frontend` with `flutter build web --release`, then deploys the `frontend/build/web` directory to Vercel using `amondnet/vercel-action`.

Manual local build + deploy (alternative)
1. Build locally:

```bash
cd frontend
flutter pub get
flutter build web --release
```

2. Deploy with Vercel CLI (if you prefer):

```bash
npm i -g vercel
cd frontend/build/web
vercel --prod --token $VERCEL_TOKEN
```

Notes
- `frontend/vercel.json` sets SPA rewrites so client-side routing works correctly on Vercel.
- If you prefer automatic Vercel Git integration (connect repo on Vercel), you can skip the GitHub Action and let Vercel build — but Vercel does not ship Flutter by default; the Action approach ensures Flutter is present.
