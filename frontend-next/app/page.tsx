"use client";

import { FormEvent, useState } from "react";
import { login } from "@/lib/api";
import { ArrowUpRight, Menu, X } from "lucide-react";

export default function Home() {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [loginOpen, setLoginOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

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
    <main className="public-home">
      <header className="public-topbar"><div className="brand"><img className="brand-logo" src="/mbaymi-logo.png" alt="" /><span>mbaymi</span></div><div className="public-header-actions"><button className={`menu-trigger ${menuOpen ? "is-open" : ""}`} aria-label={menuOpen ? "Fermer le menu" : "Ouvrir le menu"} aria-expanded={menuOpen} aria-controls="public-menu" onClick={() => setMenuOpen((isOpen) => !isOpen)}><Menu size={21} strokeWidth={1.8} aria-hidden="true" /></button></div>{menuOpen && <nav id="public-menu" className="public-menu" aria-label="Navigation principale"><a className="is-active" href="#accueil" onClick={() => setMenuOpen(false)}>Accueil</a><a href="#fermes" onClick={() => setMenuOpen(false)}>Fermes</a><a href="#activites" onClick={() => setMenuOpen(false)}>Activités</a><a href="#finances" onClick={() => setMenuOpen(false)}>Finances</a><a href="#contact" onClick={() => setMenuOpen(false)}>Contact</a><button className="menu-login" onClick={() => { setMenuOpen(false); setLoginOpen(true); }}>Se connecter <ArrowUpRight size={15} aria-hidden="true" /></button></nav>}</header>
      <section id="accueil" className="public-hero"><div className="public-hero-copy"><p className="eyebrow">L'agriculture au quotidien</p><h1>Votre terrain.<br /><em>Votre rythme.</em></h1><p>Retrouvez vos fermes, vos cultures et vos activités dans un seul espace.</p><button className="primary-action" onClick={() => setLoginOpen(true)}>Accéder à mon espace <ArrowUpRight size={16} aria-hidden="true" /></button></div><div className="public-hero-image"><img src="https://i.pinimg.com/736x/5c/ea/87/5cea87d48e3f7aee5ee592c34f6244eb.jpg" alt="Paysage agricole" /></div></section>
      <section className="public-intro"><p className="eyebrow">Un espace pour avancer</p><h2>Tout ce qui compte<br /><em>sur le terrain.</em></h2><p>Mbaymi rassemble les informations utiles de votre exploitation pour vous aider à décider au bon moment, depuis votre téléphone comme depuis votre ordinateur.</p></section>
      <section id="fermes" className="public-story public-story-dark"><div className="public-story-copy"><span className="story-index">01 / FERMES</span><h2>Voyez votre exploitation comme elle est.</h2><p>Chaque ferme garde son identité, sa localisation, ses photos et ses parcelles. Vous passez de la vue d'ensemble au détail sans perdre le fil.</p><button className="story-link" onClick={() => setLoginOpen(true)}>Découvrir mon espace</button></div><div className="story-board farm-board"><div className="board-label">MA FERME</div><strong>Les terres de Ndiaye</strong><span>Dakar · 12,5 hectares</span><div className="board-line"><i /><i /><i /></div><small>4 parcelles suivies</small></div></section>
      <section id="activites" className="public-story public-story-light"><div className="story-board activity-board"><div className="board-label">AUJOURD'HUI</div><div className="activity-line"><b>06:40</b><span>Arrosage · Parcelle Nord</span><i>OK</i></div><div className="activity-line"><b>09:15</b><span>Inspection · Serre 02</span><i>OK</i></div><div className="activity-line"><b>16:30</b><span>Récolte · Tomates</span><i>À FAIRE</i></div></div><div className="public-story-copy"><span className="story-index">02 / ACTIVITÉS</span><h2>Gardez la mémoire du travail accompli.</h2><p>Notez une activité, ajoutez une photo, associez un intrant ou un montant. Votre historique devient un outil de décision.</p><button className="story-link" onClick={() => setLoginOpen(true)}>Suivre mes activités</button></div></section>
      <section id="finances" className="public-story public-story-sand"><div className="public-story-copy"><span className="story-index">03 / FINANCES</span><h2>Comprenez le mouvement de votre ferme.</h2><p>Intrants, dépenses, ventes et revenus se retrouvent au même endroit pour vous donner une lecture claire de votre activité.</p><button className="story-link" onClick={() => setLoginOpen(true)}>Voir mes finances</button></div><div className="story-board finance-board"><div className="board-label">CE MOIS-CI</div><div className="finance-number">+ 184 500 <small>FCFA</small></div><div className="finance-bars"><i /><i /><i /><i /><i /><i /></div><div className="finance-caption"><span>Revenus</span><span>Dépenses · 72 000 FCFA</span></div></div></section>
      <section className="public-features"><article><span>04</span><strong>Vos fermes</strong><p>Les terres, les photos et les cultures rassemblées.</p></article><article><span>05</span><strong>Vos activités</strong><p>Chaque action du quotidien reste accessible.</p></article><article><span>06</span><strong>Vos décisions</strong><p>Des informations simples pour agir au bon moment.</p></article></section>
      <section id="contact" className="public-final"><p className="eyebrow">Commencer simplement</p><h2>Votre prochaine décision<br /><em>commence ici.</em></h2><button className="primary-action" onClick={() => setLoginOpen(true)}>Ouvrir mon espace Mbaymi <ArrowUpRight size={16} aria-hidden="true" /></button></section>
      {loginOpen && <div className="login-modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setLoginOpen(false); }}><section className="login-modal" role="dialog" aria-modal="true" aria-labelledby="login-title"><button className="modal-close" onClick={() => setLoginOpen(false)} aria-label="Fermer"><X size={20} aria-hidden="true" /></button><p className="eyebrow">Espace producteur</p><h2 id="login-title">Content de vous revoir.</h2><p className="auth-card-intro">Connectez-vous pour retrouver vos informations et vos fermes.</p><form onSubmit={handleSubmit}><div className="field"><label htmlFor="identifier">Email ou numéro de téléphone</label><input id="identifier" required value={identifier} onChange={(event) => setIdentifier(event.target.value)} autoComplete="username" /></div><div className="field"><label htmlFor="password">Mot de passe</label><input id="password" required type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" /></div>{error && <p className="error-message" role="alert">{error}</p>}<button className="submit-button" type="submit" disabled={loading}>{loading ? "Connexion..." : "Se connecter"}</button></form><p className="api-note">Hey</p></section></div>}
    </main>
  );
}