import type { ComponentProps } from "react";
import { ArrowLeft, ArrowUpRight, Sprout, Users } from "lucide-react";

type Farm = {
  id: number;
  name: string;
  location?: string;
  size_hectares?: number;
  image_url?: string;
  photos?: Array<{ image_url?: string }>;
  crops?: Array<{ crop_name?: string }>;
};
type FormSubmitEvent = Parameters<NonNullable<ComponentProps<"form">["onSubmit"]>>[0];

type FarmViewProps = {
  activeTab: string;
  farms: Farm[];
  farmFormError: string;
  farmFormLoading: boolean;
  onTabChange: (tab: string) => void;
  onOpenFarm: (farmId: number) => void;
  onSubmitFarm: (event: FormSubmitEvent) => void;
};

export default function FarmView({ activeTab, farms, farmFormError, farmFormLoading, onTabChange, onOpenFarm, onSubmitFarm }: Readonly<FarmViewProps>) {
  if (activeTab === "Ajouter") {
    return <div className="farm-create-view"><button className="back-action" onClick={() => onTabChange("Fermes")}><ArrowLeft size={15} aria-hidden="true" /> Retour aux fermes</button><div className="section-page-heading"><div><p className="eyebrow">MA FERME · NOUVELLE EXPLOITATION</p><h2>Ajouter une ferme</h2><p>Créez votre espace pour suivre vos parcelles, activités et finances.</p></div></div><form className="farm-create-form" onSubmit={onSubmitFarm}><label>Nom de la ferme<input name="name" required placeholder="Ex. Ferme familiale de Ndiaye" /></label><label>Localisation<input name="location" placeholder="Ex. Dakar, Sénégal" /></label><div className="form-row"><label>Surface en hectares<input name="size_hectares" type="number" min="0" step="0.01" placeholder="12.5" /></label><label>Type de sol<input name="soil_type" placeholder="Ex. argileux" /></label></div>{farmFormError && <p className="error-message" role="alert">{farmFormError}</p>}<button className="primary-action" type="submit" disabled={farmFormLoading}>{farmFormLoading ? "Création..." : "Créer la ferme"}</button></form></div>;
  }
  return <div className="farms-view"><div className="farms-view-heading"><div><p className="eyebrow">MA FERME · ESPACE PRIVÉ</p><h2>Vos fermes</h2><p className="farms-view-subtitle">Suivez vos terres, vos cultures et votre élevage au même endroit.</p></div><button className="primary-action" onClick={() => onTabChange("Ajouter")}>+ Ajouter une ferme</button></div><div className="farm-section-tabs"><button className="selected"><Sprout size={15} aria-hidden="true" /> Fermes <b>{farms.length}</b></button><button onClick={() => onTabChange("Animaux")}><Users size={15} aria-hidden="true" /> Animaux</button></div>{farms.length ? <div className="farm-cards-grid">{farms.map((farm) => { const image = farm.photos?.[0]?.image_url || farm.image_url; return <button className="farm-detail-card" key={farm.id} onClick={() => onOpenFarm(farm.id)}><div className="farm-detail-art">{image && <img src={image} alt={`Paysage de ${farm.name}`} />}<span>{image ? "" : <Sprout size={42} aria-hidden="true" />}</span><small>{farm.location || "LOCALISATION"}</small></div><div className="farm-detail-body"><div><h3>{farm.name}</h3><p>{farm.size_hectares ? `${farm.size_hectares} hectares` : "Surface non renseignée"}</p></div><span className="farm-arrow"><ArrowUpRight size={18} aria-hidden="true" /></span><div className="farm-detail-stats"><span>{farm.crops?.length ?? 0} cultures</span></div></div></button>; })}</div> : <div className="farms-empty-state"><span className="empty-landmark"><Sprout size={42} aria-hidden="true" /></span><p className="metric-label">AUCUNE FERME</p><h3>Votre terre mérite un espace.</h3><p>Créez votre première ferme pour commencer à suivre vos cultures et vos activités.</p><button className="primary-action" onClick={() => onTabChange("Ajouter")}>Créer ma première ferme</button></div>}</div>;
}