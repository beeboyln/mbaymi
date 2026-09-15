"use client";

import { FormEvent, useState } from "react";
import { apiBaseUrl, login } from "@/lib/api";

export default function Home() {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const session = await login(identifier.trim(), password);
      window.localStorage.setItem("mbaymi_session", JSON.stringify(session));
      window.location.assign("/dashboard");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Connexion impossible.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="auth-shell">
      <section className="auth-visual" aria-label="Mbaymi">
        <div className="brand"><span className="brand-mark">✦</span> mbaymi</div>
        <div className="visual-copy">
          <p className="eyebrow">Votre agriculture, en mouvement</p>
          <h1>Les bonnes décisions commencent sur le terrain.</h1>
          <p>Retrouvez vos fermes, vos cultures et vos activités dans une expérience web rapide et pensée pour le quotidien.</p>
        </div>
        <div className="visual-footer">Une nouvelle interface, le même backend Mbaymi.</div>
      </section>

      <section className="auth-panel">
        <div className="auth-card">
          <p className="eyebrow">Espace producteur</p>
          <h2>Content de vous revoir.</h2>
          <p className="auth-card-intro">Connectez-vous avec les mêmes identifiants que dans l’application Mbaymi.</p>

          <form onSubmit={handleSubmit}>
            <div className="field">
              <label htmlFor="identifier">Email ou numéro de téléphone</label>
              <input id="identifier" required value={identifier} onChange={(event) => setIdentifier(event.target.value)} autoComplete="username" />
            </div>
            <div className="field">
              <label htmlFor="password">Mot de passe</label>
              <input id="password" required type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" />
            </div>
            {error && <p className="error-message" role="alert">{error}</p>}
            <button className="submit-button" type="submit" disabled={loading}>
              {loading ? "Connexion..." : "Se connecter"}
            </button>
          </form>
          <p className="api-note">API connectée sur <code>{apiBaseUrl}</code></p>
        </div>
      </section>
    </main>
  );
}