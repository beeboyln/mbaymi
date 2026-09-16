import { Sprout, Sun } from "lucide-react";

type Farm = {
  id: number;
  name: string;
  location?: string;
  size_hectares?: number;
  image_url?: string;
  photos?: Array<{ image_url?: string }>;
};

type DashboardHomeProps = {
  activeTab: string;
  firstName?: string;
  farms: Farm[];
  tip: string;
  onTabChange: (tab: string) => void;
};

export default function DashboardHome({
  activeTab,
  firstName,
  farms,
  tip,
  onTabChange,
}: Readonly<DashboardHomeProps>) {
  return (
    <>
      <div className="dashboard-heading">
        <div>
          <h1>Bonjour, <strong>{firstName ?? "producteur"}</strong></h1>
        </div>
        <span className="season-tag"><Sun size={14} aria-hidden="true" /> SAISON SÈCHE</span>
      </div>
      <div className="dashboard-grid">
        <article className="dashboard-hero panel-span-two">
          <div className="hero-grain" />
          <div className="hero-copy">
            <p>LE JOUR COMMENCE ICI</p>
            <h2>Faire grandir<br /><em>l&apos;essentiel.</em></h2>
            <span>Votre activité agricole, au même endroit.</span>
          </div>
          <div className="hero-orbit orbit-one" />
          <div className="hero-orbit orbit-two" />
          <div className="hero-sun" />
        </article>
        <article className="metric-panel">
          <span className="metric-label">MES FERMES</span>
          <strong>{farms.length || "—"}</strong>
          <span className="metric-note">ferme{farms.length > 1 ? "s" : ""} enregistrée{farms.length > 1 ? "s" : ""}</span>
          <div className="metric-line" />
        </article>
        <article className="weather-panel">
          <div>
            <span className="metric-label">MÉTÉO AUJOURD&apos;HUI</span>
            <strong>29°</strong>
            <span className="metric-note">Ciel dégagé · Dakar</span>
          </div>
          <div className="weather-symbol"><Sun size={42} aria-hidden="true" /></div>
        </article>
        <article className="farms-panel panel-span-two">
          <div className="section-heading">
            <div><span className="metric-label">VOTRE TERRAIN</span><h3>Les fermes</h3></div>
            <button className="text-action" onClick={() => onTabChange("Fermes")}>Voir tout</button>
          </div>
          {farms.length ? (
            <div className="farm-list">
              {farms.slice(0, 3).map((farm) => (
                <div className="farm-row" key={farm.id}>
                  <span className="farm-icon">
                    {farm.image_url || farm.photos?.[0]?.image_url ? <img src={farm.image_url || farm.photos?.[0]?.image_url} alt={`Photo de ${farm.name}`} /> : <Sprout size={18} aria-hidden="true" />}
                  </span>
                  <div><strong>{farm.name}</strong><span>{farm.location || "Localisation non renseignée"}</span></div>
                  <span className="farm-size">{farm.size_hectares ? `${farm.size_hectares} ha` : "Ouvrir"}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-farm">
              <span><Sprout size={28} aria-hidden="true" /></span>
              <p>Votre première ferme attend ici.</p>
              <button className="outline-action" onClick={() => onTabChange("Fermes")}>Créer une ferme</button>
            </div>
          )}
        </article>
        <article className="tip-panel">
          <span className="metric-label">CONSEIL DU JOUR</span>
          <div className="tip-mark" />
          <p>{tip}</p>
          <button className="text-action">Conseils agricoles</button>
        </article>
        <article className="news-panel">
          <div className="section-heading"><div><span className="metric-label">À LA UNE</span><h3>Actualités</h3></div><span className="news-dot">●</span></div>
          <div className="news-item"><span>01</span><div><strong>Les gestes simples pour préserver l&apos;eau</strong><small>Agriculture durable · Aujourd&apos;hui</small></div></div>
          <div className="news-item"><span>02</span><div><strong>Préparer la prochaine récolte</strong><small>Conseils terrain · Cette semaine</small></div></div>
        </article>
      </div>
    </>
  );
}
