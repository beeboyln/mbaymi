import type { ChangeEvent, FormEvent } from "react";
import { ArrowLeft, Sprout, Users } from "lucide-react";
import type { Livestock } from "@/lib/api";

type LivestockFormState = {
  animal_type: string;
  breed: string;
  quantity: string;
  age_months: string;
  weight_kg: string;
  health_status: string;
  location: string;
  notes: string;
  image_url: string;
  visibility: string;
};

type LivestockViewProps = {
  farmsCount: number;
  livestock: Livestock[];
  loading: boolean;
  selectedLivestock: Livestock | null;
  formOpen: boolean;
  form: LivestockFormState;
  formLoading: boolean;
  formError: string;
  photoLoading: boolean;
  onFarmTab: () => void;
  onSelect: (animal: Livestock) => void;
  onClearSelection: () => void;
  onOpenForm: () => void;
  onCloseForm: () => void;
  onFormChange: (form: LivestockFormState) => void;
  onPhotoChange: (event: ChangeEvent<HTMLInputElement>) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onRemove: () => void;
};

export default function LivestockView({
  farmsCount,
  livestock,
  loading,
  selectedLivestock,
  formOpen,
  form,
  formLoading,
  formError,
  photoLoading,
  onFarmTab,
  onSelect,
  onClearSelection,
  onOpenForm,
  onCloseForm,
  onFormChange,
  onPhotoChange,
  onSubmit,
  onRemove,
}: Readonly<LivestockViewProps>) {
  if (selectedLivestock && !formOpen) {
    return (
      <div className="livestock-view">
        <Tabs farmsCount={farmsCount} livestockCount={livestock.length} onFarmTab={onFarmTab} />
        <button className="back-action" onClick={onClearSelection}>
          <ArrowLeft size={15} aria-hidden="true" /> Tous les animaux
        </button>
        <div className="livestock-detail-header">
          <div className="livestock-detail-art" style={selectedLivestock.image_url ? { backgroundImage: `url(${selectedLivestock.image_url})` } : undefined}>
            {!selectedLivestock.image_url && <Sprout size={46} aria-hidden="true" />}
          </div>
          <div><p className="eyebrow">FICHE ANIMAL</p><h2>{selectedLivestock.animal_type}</h2><p>{selectedLivestock.breed || "Race non renseignée"}</p></div>
        </div>
        <div className="livestock-detail-facts">
          <div><span>QUANTITÉ</span><strong>{selectedLivestock.quantity ?? 1}</strong></div>
          <div><span>ÉTAT DE SANTÉ</span><strong>{selectedLivestock.health_status || "Non renseigné"}</strong></div>
          <div><span>LOCALISATION</span><strong>{selectedLivestock.location || "Non renseignée"}</strong></div>
          <div><span>POIDS</span><strong>{selectedLivestock.weight_kg ? `${selectedLivestock.weight_kg} kg` : "Non renseigné"}</strong></div>
        </div>
        {selectedLivestock.notes && <p className="livestock-notes">{selectedLivestock.notes}</p>}
        <div className="livestock-detail-actions">
          <button className="primary-action" onClick={onOpenForm}>Modifier</button>
          <button className="profile-logout" onClick={onRemove}>Supprimer</button>
        </div>
      </div>
    );
  }

  if (formOpen) {
    return (
      <div className="livestock-view">
        <button className="back-action" onClick={onCloseForm}><ArrowLeft size={15} aria-hidden="true" /> Retour aux animaux</button>
        <div className="section-page-heading"><div><p className="eyebrow">ÉLEVAGE · {selectedLivestock ? "MODIFIER" : "NOUVEL ANIMAL"}</p><h2>{selectedLivestock ? "Modifier l'animal" : "Ajouter un animal"}</h2></div></div>
        <form className="livestock-form" onSubmit={onSubmit}>
          <label>Type d&apos;animal<input required value={form.animal_type} onChange={(event) => onFormChange({ ...form, animal_type: event.target.value })} placeholder="Ex. Bovin" /></label>
          <label>Race<input value={form.breed} onChange={(event) => onFormChange({ ...form, breed: event.target.value })} /></label>
          <div className="form-row"><label>Quantité<input type="number" min="1" value={form.quantity} onChange={(event) => onFormChange({ ...form, quantity: event.target.value })} /></label><label>Âge en mois<input type="number" min="0" value={form.age_months} onChange={(event) => onFormChange({ ...form, age_months: event.target.value })} /></label></div>
          <div className="form-row"><label>Poids en kg<input type="number" min="0" step="0.1" value={form.weight_kg} onChange={(event) => onFormChange({ ...form, weight_kg: event.target.value })} /></label><label>État de santé<select value={form.health_status} onChange={(event) => onFormChange({ ...form, health_status: event.target.value })}><option value="healthy">En bonne santé</option><option value="sick">Malade</option><option value="under_treatment">En traitement</option></select></label></div>
          <label>Localisation<input value={form.location} onChange={(event) => onFormChange({ ...form, location: event.target.value })} /></label>
          <label className="photo-picker">Photo de l&apos;animal<input type="file" accept="image/*" capture="environment" onChange={onPhotoChange} disabled={photoLoading} /><span>{photoLoading ? "Envoi de la photo..." : "Choisir une image ou prendre une photo"}</span>{form.image_url && <img src={form.image_url} alt="Aperçu de l'animal" />}</label>
          <label>Notes<textarea value={form.notes} onChange={(event) => onFormChange({ ...form, notes: event.target.value })} rows={4} /></label>
          {formError && <p className="error-message" role="alert">{formError}</p>}
          <button className="primary-action" type="submit" disabled={formLoading}>{formLoading ? "Enregistrement..." : "Enregistrer"}</button>
        </form>
      </div>
    );
  }

  return (
    <div className="livestock-view">
      <div className="section-page-heading"><div><p className="eyebrow">ÉLEVAGE · ESPACE PRIVÉ</p><h2>Vos animaux</h2><p>Retrouvez votre cheptel et les informations essentielles de chaque animal.</p></div><button className="primary-action" onClick={onOpenForm}>+ Ajouter un animal</button></div>
      <Tabs farmsCount={farmsCount} livestockCount={livestock.length} onFarmTab={onFarmTab} />
      {loading ? <div className="farm-detail-loading">Chargement des animaux...</div> : livestock.length ? <div className="livestock-grid">{livestock.map((animal) => <button className="livestock-card" key={animal.id} type="button" onClick={() => onSelect(animal)}><div className="livestock-art" style={animal.image_url ? { backgroundImage: `url(${animal.image_url})` } : undefined}>{!animal.image_url && <Sprout size={34} aria-hidden="true" />}</div><div className="livestock-card-body"><div className="section-heading"><div><span className="metric-label">ANIMAL</span><h3>{animal.animal_type}</h3></div><strong className="livestock-quantity">{animal.quantity ?? 1}</strong></div><p>{animal.breed || "Race non renseignée"}</p><div className="livestock-meta"><span>{animal.health_status || "État non renseigné"}</span><span>{animal.location || "Localisation non renseignée"}</span></div></div></button>)}</div> : <div className="farms-empty-state"><Sprout size={38} aria-hidden="true" /><h3>Aucun animal enregistré.</h3><p>Votre cheptel apparaîtra ici dès que vous aurez ajouté un animal.</p></div>}
    </div>
  );
}

function Tabs({ farmsCount, livestockCount, onFarmTab }: { farmsCount: number; livestockCount: number; onFarmTab: () => void }) {
  return <div className="farm-section-tabs"><button onClick={onFarmTab}><Sprout size={15} aria-hidden="true" /> Fermes <b>{farmsCount}</b></button><button className="selected"><Users size={15} aria-hidden="true" /> Animaux <b>{livestockCount}</b></button></div>;
}
