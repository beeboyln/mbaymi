"use client";

import { useEffect, useState } from "react";
import { createCrop, deleteCrop, getFarmDetails, getFarms, updateCrop } from "@/lib/api";

type Session = { id?: number; name?: string; role?: string; access_token?: string };
type Farm = { id: number; name: string; location?: string; size_hectares?: number; image_url?: string; crops?: Array<{ crop_name?: string }>; livestocks?: Array<unknown> };
type FarmDetailState = Awaited<ReturnType<typeof getFarmDetails>>;

const tips = [
  "Arrosez tôt le matin pour réduire l'évaporation et économiser l'eau.",
  "Le compost améliore la rétention d'humidité du sol en profondeur.",
  "Diversifiez les cultures pour réduire les risques de ravageurs.",
];

export default function DashboardPage() {
  const [session, setSession] = useState<Session | null>(null);
  const [farms, setFarms] = useState<Farm[]>([]);
  const [activeTab, setActiveTab] = useState("Accueil");
  const [tip, setTip] = useState(tips[0]);
  const [selectedFarm, setSelectedFarm] = useState<FarmDetailState | null>(null);
  const [farmLoading, setFarmLoading] = useState(false);
  const [expandedCropId, setExpandedCropId] = useState<number | null>(null);
  const [actionNotice, setActionNotice] = useState("");

  useEffect(() => {
    setTip(tips[Math.floor(Math.random() * tips.length)]);
    const storedSession = window.localStorage.getItem("mbaymi_session");
    if (!storedSession) {
      window.location.assign("/");
      return;
    }

    const currentSession = JSON.parse(storedSession) as Session;
    setSession(currentSession);
    if (currentSession.id && currentSession.access_token) {
      getFarms(currentSession.access_token)
        .then(setFarms)
        .catch(() => setFarms([]));
    }
  }, []);

  function logout() {
    window.localStorage.removeItem("mbaymi_session");
    window.location.assign("/");
  }

  async function openFarm(farmId: number) {
    if (!session?.access_token) return;
    setFarmLoading(true);
    setSelectedFarm(null);
    setExpandedCropId(null);
    setActionNotice("");
    try {
      setSelectedFarm(await getFarmDetails(farmId, session.access_token));
    } finally {
      setFarmLoading(false);
    }
  }

  async function addParcel(farmId: number) {
    if (!session?.access_token) return;
    const cropName = window.prompt("Nom de la parcelle");
    if (!cropName?.trim()) return;
    await createCrop(farmId, { crop_name: cropName.trim(), status: "growing" }, session.access_token);
    await openFarm(farmId);
    setActionNotice("Parcelle créée.");
  }

  async function editParcel(cropId: number, farmId: number, currentName: string) {
    if (!session?.access_token) return;
    const cropName = window.prompt("Nom de la parcelle", currentName);
    if (!cropName?.trim()) return;
    await updateCrop(cropId, { crop_name: cropName.trim() }, session.access_token);
    await openFarm(farmId);
    setActionNotice("Parcelle mise à jour.");
  }

  async function removeParcel(cropId: number, farmId: number, cropName: string) {
    if (!session?.access_token || !window.confirm(`Supprimer « ${cropName} » ?`)) return;
    await deleteCrop(cropId, session.access_token);
    await openFarm(farmId);
    setActionNotice("Parcelle supprimée.");
  }

  function formatMoney(value = 0) {
    return new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(value) + " FCFA";
  }

  function renderFarmDetail() {
    if (farmLoading) return <div className="farm-detail-loading">Chargement de la ferme...</div>;
    if (!selectedFarm) return null;
    const { farm, crops, stats, finances } = selectedFarm;
    const cover = farm.photos?.[0]?.image_url || farm.image_url;
    return <div className="farm-detail-view">
      <button className="back-action" onClick={() => setSelectedFarm(null)}>← Toutes les fermes</button>
      <div className="farm-detail-header">
        <div className="farm-cover" style={cover ? { backgroundImage: `url(${cover})` } : undefined}><span>{cover ? "" : "⌁"}</span><small>{farm.location || "LOCALISATION NON RENSEIGNÉE"}</small></div>
        <div className="farm-detail-title"><p className="eyebrow">FICHE FERME · {farm.soil_type || "EXPLOITATION AGRICOLE"}</p><h2>{farm.name}</h2><p>{farm.size_hectares ? `${farm.size_hectares} hectares` : "Surface non renseignée"} · Données actualisées maintenant</p></div>
      </div>
      <div className="farm-stats-strip"><div><span>PARCELLES</span><strong>{stats.parcel_count ?? crops.length}</strong></div><div><span>ANIMAUX</span><strong>{stats.livestock_count ?? 0}</strong></div><div><span>REVENUS · 30 J</span><strong>{formatMoney(stats.total_revenue)}</strong></div><div><span>RÉSULTAT NET</span><strong className={(stats.net_income ?? 0) >= 0 ? "positive" : "negative"}>{formatMoney(stats.net_income)}</strong></div></div>
      <div className="farm-detail-columns">
        <article className="detail-section"><div className="section-heading"><div><span className="metric-label">PARCELLES & CULTURES</span><h3>Ce qui pousse ici</h3></div><button className="text-action" onClick={() => addParcel(farm.id)}>Ajouter ↗</button></div>{actionNotice && <p className="action-notice" role="status">{actionNotice}</p>}{crops.length ? <div className="crop-list">{crops.map((crop) => <div className="crop-entry" key={crop.id}><button className="crop-row" onClick={() => setExpandedCropId(expandedCropId === crop.id ? null : crop.id)} aria-expanded={expandedCropId === crop.id}><span className="crop-mark">✦</span><span className="crop-row-copy"><strong>{crop.crop_name || "Culture"}</strong><span>{crop.status || "En suivi"}{crop.area ? ` · ${crop.area} ha` : ""}</span></span><span>{crop.expected_yield ? `${crop.expected_yield} kg` : "⌄"}</span></button>{expandedCropId === crop.id && <div className="crop-actions"><button onClick={() => editParcel(crop.id, farm.id, crop.crop_name || "Culture")}>Modifier</button><button onClick={() => setActionNotice("Le suivi des activités sera disponible dans la prochaine vue.")}>Activités</button><button onClick={() => setActionNotice("Les finances de la parcelle seront disponibles dans la prochaine vue.")}>Finance</button><button onClick={() => setActionNotice("Les problèmes de culture seront disponibles dans la prochaine vue.")}>Problèmes</button><button onClick={() => setActionNotice("Les rappels de parcelle seront disponibles dans la prochaine vue.")}>Rappels</button><button onClick={() => setActionNotice("L’export de parcelle sera disponible dans la prochaine vue.")}>Télécharger</button><button className="danger-action" onClick={() => removeParcel(crop.id, farm.id, crop.crop_name || "Culture")}>Supprimer</button></div>}</div>)}</div> : <p className="detail-empty">Aucune parcelle enregistrée pour cette ferme.</p>}</article>
        <article className="detail-section finance-section"><div className="section-heading"><div><span className="metric-label">FINANCES · 30 JOURS</span><h3>Le mouvement</h3></div><span className="finance-badge">FCFA</span></div><div className="finance-total"><span>Revenus</span><strong>{formatMoney(stats.total_revenue)}</strong></div><div className="finance-total"><span>Dépenses</span><strong>{formatMoney(stats.total_expenses)}</strong></div>{finances.top_products?.length ? <div className="product-list"><span className="metric-label">MEILLEURES VENTES</span>{finances.top_products.slice(0, 3).map((product) => <div key={product.product} className="product-row"><span>{product.product || "Produit"}</span><strong>{formatMoney(product.revenue)}</strong></div>)}</div> : <p className="detail-empty">Pas encore de ventes classées.</p>}</article>
      </div>
    </div>;
  }

  function renderFarmsView() {
    if (selectedFarm || farmLoading) return renderFarmDetail();
    return <div className="farms-view">
      <div className="farms-view-heading"><div><p className="eyebrow">MA FERME · ESPACE PRIVÉ</p><h2>Vos fermes</h2><p className="farms-view-subtitle">Suivez vos terres, vos cultures et votre élevage au même endroit.</p></div><button className="primary-action" onClick={() => setActiveTab("Ajouter")}>+ Ajouter une ferme</button></div>
      <div className="farm-section-tabs"><button className="selected">⌁ Fermes <b>{farms.length}</b></button><button onClick={() => setActiveTab("Animaux")}>♧ Animaux</button></div>
      {farms.length ? <div className="farm-cards-grid">{farms.map((farm) => <button className="farm-detail-card" key={farm.id} onClick={() => openFarm(farm.id)}><div className="farm-detail-art" style={farm.image_url ? { backgroundImage: `url(${farm.image_url})`, backgroundSize: "cover", backgroundPosition: "center" } : undefined}><span>{farm.image_url ? "" : "⌁"}</span><small>{farm.location || "LOCALISATION"}</small></div><div className="farm-detail-body"><div><h3>{farm.name}</h3><p>{farm.size_hectares ? `${farm.size_hectares} hectares` : "Surface non renseignée"}</p></div><span className="farm-arrow">↗</span><div className="farm-detail-stats"><span>{farm.crops?.length ?? 0} cultures</span><span>{farm.livestocks?.length ?? 0} animaux</span></div></div></button>)}</div> : <div className="farms-empty-state"><span className="empty-landmark">⌁</span><p className="metric-label">AUCUNE FERME</p><h3>Votre terre mérite un espace.</h3><p>Créez votre première ferme pour commencer à suivre vos cultures et vos activités.</p><button className="primary-action" onClick={() => setActiveTab("Ajouter")}>Créer ma première ferme</button></div>}
    </div>;
  }

  return (
    <main className="dashboard-shell">
      <header className="dashboard-topbar">
        <div className="brand dashboard-brand"><span className="brand-mark">✦</span> mbaymi</div>
        <div className="dashboard-actions">
          <button className="icon-button" aria-label="Rechercher">⌕</button>
          <button className="icon-button" aria-label="Notifications">♧</button>
          <button className="avatar-button" onClick={logout} aria-label="Se déconnecter">{session?.name?.charAt(0) ?? "M"}</button>
        </div>
      </header>

      <div className="dashboard-layout">
        <aside className="dashboard-sidebar">
          <nav aria-label="Navigation principale">
            {[["Accueil", "⌂"], ["Fermes", "⌁"], ["Réseau", "◎"], ["Marché", "▱"]].map(([label, icon]) => (
              <button key={label} className={`side-link ${activeTab === label ? "is-active" : ""}`} onClick={() => setActiveTab(label)}>
                <span>{icon}</span>{label}
              </button>
            ))}
          </nav>
          <button className="side-settings" onClick={logout}>Quitter la session</button>
        </aside>

        <section className="dashboard-content">
          {activeTab === "Fermes" || activeTab === "Animaux" || activeTab === "Ajouter" ? renderFarmsView() : <>
          <div className="dashboard-heading">
            <div><p className="eyebrow">{activeTab} · mardi 15 septembre 2026</p><h1>Bonjour, <strong>{session?.name?.split(" ")[0] ?? "producteur"}</strong></h1></div>
            <span className="season-tag">☼ SAISON SÈCHE</span>
          </div>

          <div className="dashboard-grid">
            <article className="dashboard-hero panel-span-two">
              <div className="hero-grain" />
              <div className="hero-copy"><p>LE JOUR COMMENCE ICI</p><h2>Faire grandir<br /><em>l'essentiel.</em></h2><span>Votre activité agricole, au même endroit.</span></div>
              <div className="hero-orbit orbit-one" /><div className="hero-orbit orbit-two" /><div className="hero-sun">✦</div>
            </article>

            <article className="metric-panel"><span className="metric-label">MES FERMES</span><strong>{farms.length || "—"}</strong><span className="metric-note">ferme{farms.length > 1 ? "s" : ""} enregistrée{farms.length > 1 ? "s" : ""}</span><div className="metric-line" /></article>
            <article className="weather-panel"><div><span className="metric-label">MÉTÉO AUJOURD'HUI</span><strong>29°</strong><span className="metric-note">Ciel dégagé · Dakar</span></div><div className="weather-symbol">☼</div></article>

            <article className="farms-panel panel-span-two"><div className="section-heading"><div><span className="metric-label">VOTRE TERRAIN</span><h3>Les fermes</h3></div><button className="text-action" onClick={() => setActiveTab("Fermes")}>Voir tout ↗</button></div>{farms.length ? <div className="farm-list">{farms.slice(0, 3).map((farm) => <div className="farm-row" key={farm.id}><span className="farm-icon">⌁</span><div><strong>{farm.name}</strong><span>{farm.location || "Localisation non renseignée"}</span></div><span className="farm-size">{farm.size_hectares ? `${farm.size_hectares} ha` : "Ouvrir →"}</span></div>)}</div> : <div className="empty-farm"><span>⌁</span><p>Votre première ferme attend ici.</p><button className="outline-action" onClick={() => setActiveTab("Fermes")}>Créer une ferme</button></div>}</article>

            <article className="tip-panel"><span className="metric-label">CONSEIL DU JOUR</span><div className="tip-mark">✦</div><p>{tip}</p><button className="text-action">Conseils agricoles ↗</button></article>
            <article className="news-panel"><div className="section-heading"><div><span className="metric-label">À LA UNE</span><h3>Actualités</h3></div><span className="news-dot">●</span></div><div className="news-item"><span>01</span><div><strong>Les gestes simples pour préserver l'eau</strong><small>Agriculture durable · Aujourd'hui</small></div></div><div className="news-item"><span>02</span><div><strong>Préparer la prochaine récolte</strong><small>Conseils terrain · Cette semaine</small></div></div></article>
          </div>
          </>}
        </section>
      </div>

      <nav className="mobile-nav" aria-label="Navigation mobile">{[["Accueil", "⌂"], ["Fermes", "⌁"], ["Ajouter", "+"], ["Réseau", "◎"], ["Marché", "▱"]].map(([label, icon]) => <button key={label} className={activeTab === label ? "is-active" : ""} onClick={() => setActiveTab(label)}><span>{icon}</span>{label}</button>)}</nav>
    </main>
  );
}