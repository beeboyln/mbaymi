"use client";

import { useEffect, useState } from "react";
import { createCrop, deleteCrop, getFarmDetails, getFarms, updateCrop } from "@/lib/api";
import ParcelActionModal from "@/components/parcel-action-modal";

type Session = { id?: number; name?: string; role?: string; access_token?: string };
type Farm = { id: number; name: string; location?: string; size_hectares?: number; image_url?: string; crops?: Array<{ crop_name?: string }>; livestocks?: Array<unknown> };
type FarmDetailState = Awaited<ReturnType<typeof getFarmDetails>>;
type ParcelModal = { mode: "activity" | "finance" | "problems" | "reminders"; cropId: number } | null;

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
  const [parcelModal, setParcelModal] = useState<ParcelModal>(null);

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

  useEffect(() => {
    function routeParcelAction(event: MouseEvent) {
      const target = event.target as HTMLElement;
      const button = target.closest(".crop-actions button") as HTMLButtonElement | null;
      if (!button) return;
      const label = button.textContent?.toLowerCase() ?? "";
      if (["activités", "finance", "intrants", "problèmes", "rappels"].some((action) => label.startsWith(action))) {
        const cropEntry = button.closest(".crop-entry");
        const cropId = cropEntry ? selectedFarm?.crops[Array.from(document.querySelectorAll(".crop-entry")).indexOf(cropEntry)]?.id : undefined;
        const farmId = selectedFarm?.farm.id;
        if (cropId && farmId) {
          event.preventDefault();
          event.stopPropagation();
          const page = label.startsWith("activités") ? "activity" : label.startsWith("problèmes") ? "problems" : label.startsWith("rappels") ? "reminders" : "finance";
          setParcelModal({ mode: page as "activity" | "finance" | "problems" | "reminders", cropId: Number(cropId) });
        }
      }
    }
    document.addEventListener("click", routeParcelAction, true);
    return () => document.removeEventListener("click", routeParcelAction, true);
  }, [selectedFarm]);

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

  function formatDate(value?: string) {
    if (!value) return "Date non renseignée";
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? "Date non renseignée" : new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" }).format(date);
  }

  function renderFarmDetail() {
    if (farmLoading) return <div className="farm-detail-loading">Chargement de la ferme...</div>;
    if (!selectedFarm) return null;
    const { farm, crops, stats, finances, inputs, activities, transactions } = selectedFarm;
    const cover = farm.photos?.[0]?.image_url || farm.image_url;
    const totalIncome = transactions.filter((item) => item.transaction_type === "income").reduce((sum, item) => sum + (item.amount ?? 0), 0);
    const totalExpenses = transactions.filter((item) => item.transaction_type === "expense").reduce((sum, item) => sum + (item.amount ?? 0), 0);
    const cropInputs = (cropId: number) => inputs.filter((item) => item.crop_id === cropId);
    const cropActivities = (cropId: number) => activities.filter((item) => item.crop_id === cropId);
    const cropRoute = (cropId: number, page: string) => `/farm/${farm.id}/parcel/${cropId}/${page}`;
    return <div className="farm-detail-view">
      <button className="back-action" onClick={() => setSelectedFarm(null)}>← Toutes les fermes</button>
      <div className="farm-detail-header">
        <div className="farm-cover" style={cover ? { backgroundImage: `url(${cover})` } : undefined}><span>{cover ? "" : "⌁"}</span><small>{farm.location || "LOCALISATION NON RENSEIGNÉE"}</small></div>
        <div className="farm-detail-title"><p className="eyebrow">FICHE FERME · {farm.soil_type || "EXPLOITATION AGRICOLE"}</p><h2>{farm.name}</h2><p>{farm.size_hectares ? `${farm.size_hectares} hectares` : "Surface non renseignée"} · Données actualisées maintenant</p></div>
      </div>
      <div className="farm-stats-strip"><div><span>PARCELLES</span><strong>{stats.parcel_count ?? crops.length}</strong></div><div><span>ANIMAUX</span><strong>{stats.livestock_count ?? 0}</strong></div><div><span>REVENUS</span><strong>{formatMoney(totalIncome || stats.total_revenue)}</strong></div><div><span>RÉSULTAT NET</span><strong className={(totalIncome - totalExpenses) >= 0 ? "positive" : "negative"}>{formatMoney(totalIncome - totalExpenses)}</strong></div></div>
      <div className="farm-detail-columns">
        <article className="detail-section"><div className="section-heading"><div><span className="metric-label">PARCELLES & CULTURES</span><h3>Ce qui pousse ici</h3></div><button className="text-action" onClick={() => addParcel(farm.id)}>Ajouter ↗</button></div>{actionNotice && <p className="action-notice" role="status">{actionNotice}</p>}{crops.length ? <div className="crop-list">{crops.map((crop) => <div className="crop-entry" key={crop.id}><button className="crop-row" onClick={() => setExpandedCropId(expandedCropId === crop.id ? null : crop.id)} aria-expanded={expandedCropId === crop.id}><span className="crop-mark"></span>{crop.image_url && <img className="crop-thumb" src={crop.image_url} alt="" /> }<span className="crop-row-copy"><strong>{crop.crop_name || "Culture"}{crop.variety ? ` · ${crop.variety}` : ""}</strong><span>{crop.status || "En suivi"}{crop.area ? ` · ${crop.area} m²` : ""} · {cropActivities(crop.id).length} activités · {cropInputs(crop.id).length} intrants</span></span><span>{crop.expected_yield ? `${crop.expected_yield} kg` : "⌄"}</span></button>{expandedCropId === crop.id && <div className="crop-expanded"><div className="crop-meta"><span>PLANTÉE <b>{formatDate(crop.planted_date)}</b></span><span>RÉCOLTE PRÉVUE <b>{formatDate(crop.expected_harvest_date)}</b></span><span>QUANTITÉ <b>{crop.quantity_planted ?? "—"}</b></span><span>RENDEMENT <b>{crop.expected_yield ? `${crop.expected_yield} kg` : "—"}</b></span></div>{crop.notes && <p className="crop-notes">{crop.notes}</p>}<div className="crop-actions"><button onClick={() => editParcel(crop.id, farm.id, crop.crop_name || "Culture")}>Modifier</button><button onClick={() => setActionNotice(`${cropActivities(crop.id).length} activité(s) chargée(s) pour cette parcelle.`)}>Activités ({cropActivities(crop.id).length})</button><button onClick={() => setActionNotice(`${formatMoney(transactions.filter((item) => item.crop_id === crop.id).reduce((sum, item) => sum + (item.amount ?? 0), 0))} de transactions pour cette parcelle.`)}>Finance</button><button onClick={() => setActionNotice(`${cropInputs(crop.id).length} intrant(s) chargé(s) pour cette parcelle.`)}>Intrants ({cropInputs(crop.id).length})</button><button onClick={() => setActionNotice("Les problèmes de culture seront disponibles dans la prochaine vue.")}>Problèmes</button><button onClick={() => setActionNotice("Les rappels de parcelle seront disponibles dans la prochaine vue.")}>Rappels</button><button onClick={() => setActionNotice("L’export de parcelle sera disponible dans la prochaine vue.")}>Télécharger</button><button className="danger-action" onClick={() => removeParcel(crop.id, farm.id, crop.crop_name || "Culture")}>Supprimer</button></div></div>}</div>)}</div> : <p className="detail-empty">Aucune parcelle enregistrée pour cette ferme.</p>}</article>
        <article className="detail-section finance-section"><div className="section-heading"><div><span className="metric-label">FINANCES</span><h3>Le mouvement</h3></div><span className="finance-badge">FCFA</span></div><div className="finance-total"><span>Revenus</span><strong>{formatMoney(totalIncome || stats.total_revenue)}</strong></div><div className="finance-total"><span>Dépenses</span><strong>{formatMoney(totalExpenses || stats.total_expenses)}</strong></div>{transactions.length ? <div className="product-list"><span className="metric-label">TRANSACTIONS</span>{transactions.slice(0, 5).map((item) => <div key={item.id} className="product-row"><span>{item.category || item.transaction_type || "Transaction"}<small>{formatDate(item.transaction_date)}</small></span><strong className={item.transaction_type === "expense" ? "expense-value" : "income-value"}>{item.transaction_type === "expense" ? "-" : "+"}{formatMoney(item.amount)}</strong></div>)}</div> : <p className="detail-empty">Aucune transaction financière enregistrée.</p>}</article>
      </div>
      <div className="farm-data-columns"><article className="detail-section"><div className="section-heading"><div><span className="metric-label">ACTIVITÉS</span><h3>Dernières actions</h3></div><span className="finance-badge">{activities.length}</span></div>{activities.length ? activities.slice(0, 6).map((item) => <div className="data-row" key={item.id}><span className="data-row-icon"></span><div><strong>{item.activity_type || "Activité"}</strong><span>{formatDate(item.activity_date)}{item.notes ? ` · ${item.notes}` : ""}</span></div><b>{item.finance_amount ? formatMoney(item.finance_amount) : ""}</b></div>) : <p className="detail-empty">Aucune activité enregistrée.</p>}</article><article className="detail-section"><div className="section-heading"><div><span className="metric-label">INTRANTS</span><h3>Stock utilisé</h3></div><span className="finance-badge">{inputs.length}</span></div>{inputs.length ? inputs.slice(0, 6).map((item) => <div className="data-row" key={item.id}><span className="data-row-icon">♧</span><div><strong>{item.name || item.input_type || "Intrant"}</strong><span>{item.quantity ?? "—"} {item.unit || ""} · {formatDate(item.applied_date)}</span></div><b>{item.cost ? formatMoney(item.cost) : ""}</b></div>) : <p className="detail-empty">Aucun intrant enregistré.</p>}</article></div>
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
        <div className="brand dashboard-brand"><img className="brand-logo" src="/mbaymi-logo.png" alt="" /> <span>mbaymi</span></div>
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
              <div className="hero-orbit orbit-one" /><div className="hero-orbit orbit-two" /><div className="hero-sun"></div>
            </article>

            <article className="metric-panel"><span className="metric-label">MES FERMES</span><strong>{farms.length || "—"}</strong><span className="metric-note">ferme{farms.length > 1 ? "s" : ""} enregistrée{farms.length > 1 ? "s" : ""}</span><div className="metric-line" /></article>
            <article className="weather-panel"><div><span className="metric-label">MÉTÉO AUJOURD'HUI</span><strong>29°</strong><span className="metric-note">Ciel dégagé · Dakar</span></div><div className="weather-symbol">☼</div></article>

            <article className="farms-panel panel-span-two"><div className="section-heading"><div><span className="metric-label">VOTRE TERRAIN</span><h3>Les fermes</h3></div><button className="text-action" onClick={() => setActiveTab("Fermes")}>Voir tout ↗</button></div>{farms.length ? <div className="farm-list">{farms.slice(0, 3).map((farm) => <div className="farm-row" key={farm.id}><span className="farm-icon">⌁</span><div><strong>{farm.name}</strong><span>{farm.location || "Localisation non renseignée"}</span></div><span className="farm-size">{farm.size_hectares ? `${farm.size_hectares} ha` : "Ouvrir →"}</span></div>)}</div> : <div className="empty-farm"><span>⌁</span><p>Votre première ferme attend ici.</p><button className="outline-action" onClick={() => setActiveTab("Fermes")}>Créer une ferme</button></div>}</article>

            <article className="tip-panel"><span className="metric-label">CONSEIL DU JOUR</span><div className="tip-mark"></div><p>{tip}</p><button className="text-action">Conseils agricoles ↗</button></article>
            <article className="news-panel"><div className="section-heading"><div><span className="metric-label">À LA UNE</span><h3>Actualités</h3></div><span className="news-dot">●</span></div><div className="news-item"><span>01</span><div><strong>Les gestes simples pour préserver l'eau</strong><small>Agriculture durable · Aujourd'hui</small></div></div><div className="news-item"><span>02</span><div><strong>Préparer la prochaine récolte</strong><small>Conseils terrain · Cette semaine</small></div></div></article>
          </div>
          </>}
        </section>
      </div>

      <nav className="mobile-nav" aria-label="Navigation mobile">{[["Accueil", "⌂"], ["Fermes", "⌁"], ["Ajouter", "+"], ["Réseau", "◎"], ["Marché", "▱"]].map(([label, icon]) => <button key={label} className={activeTab === label ? "is-active" : ""} onClick={() => setActiveTab(label)}><span>{icon}</span>{label}</button>)}</nav>
      {parcelModal && selectedFarm && <ParcelActionModal mode={parcelModal.mode} farmId={selectedFarm.farm.id} cropId={parcelModal.cropId} onClose={() => setParcelModal(null)} />}
    </main>
  );
}