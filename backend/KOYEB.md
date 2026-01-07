# Deploying the backend to Koyeb

Follow these concise steps to deploy the FastAPI backend using the Dockerfile included in this repo.

1) Prepare the repo
- Remove any committed `.env` containing secrets (do not keep secrets in git).
- Ensure `backend/.env.example` is filled locally as `.env` for testing.

2) Build & test locally (optional)

```bash
# from repo/backend
docker build -t mbaymi-backend:local .
docker run -e DATABASE_URL="postgresql://..." -e SECRET_KEY="..." -p 8000:8000 mbaymi-backend:local
# then open http://localhost:8000/ and /health
```

3) Push to GitHub
- Push your backend code (including `Dockerfile`) to a GitHub repository.

4) Create a Koyeb service
- Login to Koyeb and create a new Web Service → Connect GitHub → choose your repo and branch.
- Koyeb will detect the `Dockerfile` and build the image.

5) Environment variables (set in Koyeb dashboard)
- `DATABASE_URL` (required)
- `SECRET_KEY` (required)
- `DEBUG` (False)
- `ALLOWED_ORIGINS` (comma separated list)
- Optional: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`, `GOOGLE_MAPS_API_KEY`

6) Port & health checks
- Set the service port to `8000` (the Dockerfile exposes 8000 and the app listens on $PORT).
- Optionally configure a health check path: `/health` (HTTP 200 expected).

7) Secrets & safety
- Never commit production secrets. Use Koyeb's Environment → Secrets to store values.

8) Post-deploy
- Check logs in Koyeb dashboard for startup messages and DB initialization output.
- Verify `/health` returns `{"status":"healthy"}` and API docs at `/docs`.

Troubleshooting
- If DB initialization fails, check `DATABASE_URL` and network access (do you allow incoming connections from Koyeb to your DB?).
- If image build fails due to missing build deps, ensure `libpq-dev` is installed (the Dockerfile includes it).

Procfile (Buildpack note)

- If you deploy using Buildpacks (no Dockerfile), add a `Procfile` at the root of the `backend/` folder to force the correct run command. Example `backend/Procfile`:

```
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

- Koyeb may default to `gunicorn` when no `Procfile` is present, which will fail if `gunicorn` is not installed. Adding the `Procfile` ensures the app is launched with `uvicorn`.
