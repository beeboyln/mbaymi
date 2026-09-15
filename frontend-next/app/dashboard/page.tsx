"use client";

import { ChangeEvent, FormEvent, useEffect, useState } from "react";
import {
  createCrop,
  createFarm,
  createLivestock,
  deleteFarm,
  deleteLivestock,
  deleteCrop,
  getFarmDetails,
  getFarms,
  getMarketPrices,
  getMarketSales,
  getMyLivestock,
  getNetworkFeed,
  getNetworkPostComments,
  addNetworkPostComment,
  getUserProfile,
  updateCrop,
  updateFarm,
  updateLivestock,
  uploadImage,
  likeNetworkPost,
  unlikeNetworkPost,
} from "@/lib/api";
import ParcelActionModal from "@/components/parcel-action-modal";
import {
  ArrowLeft,
  ArrowUpRight,
  ChevronDown,
  Home,
  Package,
  Search,
  Sprout,
  Sun,
  Heart,
  MessageCircle,
  X,
  MapPin,
  Menu,
  RefreshCw,
  Store,
  Settings,
  TrendingUp,
  UserRound,
  Users,
} from "lucide-react";

type Session = {
  id?: number;
  name?: string;
  role?: string;
  currency?: string;
  access_token?: string;
};
type Farm = {
  id: number;
  name: string;
  location?: string;
  size_hectares?: number;
  image_url?: string;
  soil_type?: string;
  photos?: Array<{ image_url?: string }>;
  crops?: Array<{ crop_name?: string }>;
  livestocks?: Array<unknown>;
};
type FarmDetailState = Awaited<ReturnType<typeof getFarmDetails>>;
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
type FarmEditFormState = {
  name: string;
  location: string;
  size_hectares: string;
  soil_type: string;
  image_url: string;
};
type ParcelModal = {
  mode: "activity" | "finance" | "problems" | "reminders";
  cropId: number;
} | null;

const tips = [
  "Arrosez tôt le matin pour réduire l'évaporation et économiser l'eau.",
  "Le compost améliore la rétention d'humidité du sol en profondeur.",
  "Diversifiez les cultures pour réduire les risques de ravageurs.",
];

const emptyLivestockForm: LivestockFormState = {
  animal_type: "",
  breed: "",
  quantity: "1",
  age_months: "",
  weight_kg: "",
  health_status: "healthy",
  location: "",
  notes: "",
  image_url: "",
  visibility: "PRIVATE",
};

const activeTabStorageKey = "mbaymi_dashboard_active_tab";

export default function DashboardPage() {
  const [session, setSession] = useState<Session | null>(null);
  const [farms, setFarms] = useState<Farm[]>([]);
  const [livestock, setLivestock] = useState<import("@/lib/api").Livestock[]>([]);
  const [livestockLoading, setLivestockLoading] = useState(false);
  const [selectedLivestock, setSelectedLivestock] = useState<import("@/lib/api").Livestock | null>(null);
  const [livestockFormOpen, setLivestockFormOpen] = useState(false);
  const [livestockForm, setLivestockForm] = useState<LivestockFormState>(emptyLivestockForm);
  const [livestockFormLoading, setLivestockFormLoading] = useState(false);
  const [livestockFormError, setLivestockFormError] = useState("");
  const [livestockPhotoLoading, setLivestockPhotoLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("Accueil");
  const [dashboardHydrated, setDashboardHydrated] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [tip, setTip] = useState(tips[0]);
  const [selectedFarm, setSelectedFarm] = useState<FarmDetailState | null>(
    null,
  );
  const [farmLoading, setFarmLoading] = useState(false);
  const [expandedCropId, setExpandedCropId] = useState<number | null>(null);
  const [actionNotice, setActionNotice] = useState("");
  const [parcelModal, setParcelModal] = useState<ParcelModal>(null);
  const [networkPosts, setNetworkPosts] = useState<Array<Record<string, unknown>>>([]);
  const [marketSales, setMarketSales] = useState<Array<Record<string, unknown>>>([]);
  const [marketPrices, setMarketPrices] = useState<Array<Record<string, unknown>>>([]);
  const [sectionLoading, setSectionLoading] = useState(false);
  const [commentsPost, setCommentsPost] = useState<Record<string, unknown> | null>(null);
  const [comments, setComments] = useState<Array<Record<string, unknown>>>([]);
  const [commentText, setCommentText] = useState("");
  const [commentsLoading, setCommentsLoading] = useState(false);
  const [selectedSale, setSelectedSale] = useState<Record<string, unknown> | null>(null);
  const [userProfile, setUserProfile] = useState<import("@/lib/api").UserProfile | null>(null);
  const [sellerProfile, setSellerProfile] = useState<import("@/lib/api").UserProfile | null>(null);
  const [farmFormError, setFarmFormError] = useState("");
  const [farmFormLoading, setFarmFormLoading] = useState(false);
  const [farmEditOpen, setFarmEditOpen] = useState(false);
  const [farmEditForm, setFarmEditForm] = useState<FarmEditFormState>({ name: "", location: "", size_hectares: "", soil_type: "", image_url: "" });
  const [farmEditLoading, setFarmEditLoading] = useState(false);
  const [farmEditError, setFarmEditError] = useState("");
  const [farmPhotoLoading, setFarmPhotoLoading] = useState(false);
  const [cropModalOpen, setCropModalOpen] = useState(false);
  const [editingCropId, setEditingCropId] = useState<number | null>(null);
  const [cropForm, setCropForm] = useState({ crop_name: "", status: "growing", area: "" });
  const [cropFormLoading, setCropFormLoading] = useState(false);
  const [cropFormError, setCropFormError] = useState("");

  useEffect(() => {
    const storedTab = window.localStorage.getItem(activeTabStorageKey);
    if (storedTab) setActiveTab(storedTab);
    setDashboardHydrated(true);

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
      getUserProfile(currentSession.id, currentSession.access_token, currentSession.id)
        .then(setUserProfile)
        .catch(() => setUserProfile(null));
    }
  }, []);

  useEffect(() => {
    if (!dashboardHydrated) return;
    window.localStorage.setItem(activeTabStorageKey, activeTab);
  }, [activeTab, dashboardHydrated]);

  useEffect(() => {
    if (!session?.access_token || !session.id || !["Réseau", "Marché"].includes(activeTab)) return;
    setSectionLoading(true);
    const loadSection = activeTab === "Réseau"
      ? getNetworkFeed(session.id, session.access_token).then((items) => setNetworkPosts(items as Array<Record<string, unknown>>))
      : Promise.all([getMarketSales(session.access_token), getMarketPrices(session.access_token)]).then(([sales, prices]) => {
          setMarketSales(sales as Array<Record<string, unknown>>);
          setMarketPrices(prices as Array<Record<string, unknown>>);
        });
    loadSection.catch(() => {}).finally(() => setSectionLoading(false));
  }, [activeTab, session]);

  useEffect(() => {
    if (activeTab !== "Animaux" || !session?.access_token) return;
    setLivestockLoading(true);
    getMyLivestock(session.access_token)
      .then(setLivestock)
      .catch(() => setLivestock([]))
      .finally(() => setLivestockLoading(false));
  }, [activeTab, session]);

  useEffect(() => {
    function routeParcelAction(event: MouseEvent) {
      const target = event.target as HTMLElement;
      const button = target.closest(
        ".crop-actions button",
      ) as HTMLButtonElement | null;
      if (!button) return;
      const label = button.textContent?.toLowerCase() ?? "";
      if (
        ["activités", "finance", "intrants", "problèmes", "rappels"].some(
          (action) => label.startsWith(action),
        )
      ) {
        const cropEntry = button.closest(".crop-entry");
        const cropId = cropEntry
          ? selectedFarm?.crops[
              Array.from(document.querySelectorAll(".crop-entry")).indexOf(
                cropEntry,
              )
            ]?.id
          : undefined;
        const farmId = selectedFarm?.farm.id;
        if (cropId && farmId) {
          event.preventDefault();
          event.stopPropagation();
          const page = label.startsWith("activités")
            ? "activity"
            : label.startsWith("problèmes")
              ? "problems"
              : label.startsWith("rappels")
                ? "reminders"
                : "finance";
          setParcelModal({
            mode: page as "activity" | "finance" | "problems" | "reminders",
            cropId: Number(cropId),
          });
        }
      }
    }
    document.addEventListener("click", routeParcelAction, true);
    return () => document.removeEventListener("click", routeParcelAction, true);
  }, [selectedFarm]);

  function logout() {
    window.localStorage.removeItem("mbaymi_session");
    window.localStorage.removeItem(activeTabStorageKey);
    window.location.assign("/");
  }

  function renderProfileView() {
    const profileName = userProfile?.name || session?.name || "Producteur";
    const profileEmail = userProfile?.email || "Email non renseigné";
    const profilePhone = userProfile?.phone || "Téléphone non renseigné";

    return (
      <div className="profile-view">
        <button className="back-action" onClick={() => setActiveTab("Accueil")}>
          <ArrowLeft size={15} aria-hidden="true" /> Retour à l'accueil
        </button>
        <div className="section-page-heading">
          <div>
            <p className="eyebrow">ESPACE PERSONNEL</p>
            <h2>Mon profil</h2>
            <p>Gérez vos informations et votre session Mbaymi.</p>
          </div>
        </div>
        <article className="profile-card">
          <div className="profile-card-header">
            <div className="profile-large-avatar">
              {userProfile?.profile_image ? (
                <img src={userProfile.profile_image} alt={`Photo de ${profileName}`} />
              ) : (
                <UserRound size={34} aria-hidden="true" />
              )}
            </div>
            <div>
              <span className="metric-label">PRODUCTEUR</span>
              <h3>{profileName}</h3>
              <p>Votre espace agricole personnel</p>
            </div>
          </div>
          <div className="profile-details">
            <div><span>Email</span><strong>{profileEmail}</strong></div>
            <div><span>Téléphone</span><strong>{profilePhone}</strong></div>
            <div><span>Devise</span><strong>{userProfile?.currency || session?.currency || "FCFA"}</strong></div>
          </div>
          <button className="profile-logout" onClick={logout}>Se déconnecter</button>
        </article>
      </div>
    );
  }

  function renderSettingsView() {
    return (
      <div className="settings-view">
        <button className="back-action" onClick={() => setActiveTab("Accueil")}>
          <ArrowLeft size={15} aria-hidden="true" /> Retour à l'accueil
        </button>
        <div className="section-page-heading">
          <div>
            <p className="eyebrow">VOTRE ESPACE</p>
            <h2>Paramètres</h2>
            <p>Gérez vos préférences et consultez les informations importantes.</p>
          </div>
        </div>
        <div className="settings-list">
          <a className="settings-item" href="/confidentialite">
            <span><Settings size={19} aria-hidden="true" /></span>
            <div><strong>Politique de confidentialité</strong><small>Découvrez comment vos données sont protégées.</small></div>
            <ArrowUpRight size={17} aria-hidden="true" />
          </a>
          <a className="settings-item" href="/conditions">
            <span><Settings size={19} aria-hidden="true" /></span>
            <div><strong>Conditions d'utilisation</strong><small>Consultez les règles d'utilisation de Mbaymi.</small></div>
            <ArrowUpRight size={17} aria-hidden="true" />
          </a>
          <div className="settings-item settings-item-static">
            <span><Settings size={19} aria-hidden="true" /></span>
            <div><strong>Gestion des données</strong><small>Pour toute demande concernant vos données, contactez l'équipe Mbaymi.</small></div>
          </div>
        </div>
      </div>
    );
  }

  function renderLivestockView() {
    if (selectedLivestock && !livestockFormOpen) return renderLivestockDetail();
    if (livestockFormOpen) return renderLivestockForm();
    return (
      <div className="livestock-view">
        <div className="section-page-heading">
          <div>
            <p className="eyebrow">ÉLEVAGE · ESPACE PRIVÉ</p>
            <h2>Vos animaux</h2>
            <p>Retrouvez votre cheptel et les informations essentielles de chaque animal.</p>
          </div>
          <button className="primary-action" onClick={() => { setSelectedLivestock(null); openLivestockEditor(); }}>+ Ajouter un animal</button>
        </div>
        <div className="farm-section-tabs">
          <button onClick={() => setActiveTab("Fermes")}>
            <Sprout size={15} aria-hidden="true" /> Fermes <b>{farms.length}</b>
          </button>
          <button className="selected">
            <Users size={15} aria-hidden="true" /> Animaux <b>{livestock.length}</b>
          </button>
        </div>
        {livestockLoading ? (
          <div className="farm-detail-loading">Chargement des animaux...</div>
        ) : livestock.length ? (
          <div className="livestock-grid">
            {livestock.map((animal) => (
              <button className="livestock-card" key={animal.id} type="button" onClick={() => setSelectedLivestock(animal)}>
                <div className="livestock-art" style={animal.image_url ? { backgroundImage: `url(${animal.image_url})` } : undefined}>
                  {!animal.image_url && <Sprout size={34} aria-hidden="true" />}
                </div>
                <div className="livestock-card-body">
                  <div className="section-heading">
                    <div><span className="metric-label">ANIMAL</span><h3>{animal.animal_type}</h3></div>
                    <strong className="livestock-quantity">{animal.quantity ?? 1}</strong>
                  </div>
                  <p>{animal.breed || "Race non renseignée"}</p>
                  <div className="livestock-meta">
                    <span>{animal.health_status || "État non renseigné"}</span>
                    <span>{animal.location || "Localisation non renseignée"}</span>
                  </div>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="farms-empty-state">
            <Sprout size={38} aria-hidden="true" />
            <h3>Aucun animal enregistré.</h3>
            <p>Votre cheptel apparaîtra ici dès que vous aurez ajouté un animal.</p>
          </div>
        )}
      </div>
    );
  }

  function renderLivestockDetail() {
    if (!selectedLivestock) return null;
    return (
      <div className="livestock-view">
        <div className="farm-section-tabs">
          <button onClick={() => setActiveTab("Fermes")}><Sprout size={15} aria-hidden="true" /> Fermes <b>{farms.length}</b></button>
          <button className="selected"><Users size={15} aria-hidden="true" /> Animaux <b>{livestock.length}</b></button>
        </div>
        <button className="back-action" onClick={() => setSelectedLivestock(null)}><ArrowLeft size={15} aria-hidden="true" /> Tous les animaux</button>
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
          <button className="primary-action" onClick={() => openLivestockEditor(selectedLivestock)}>Modifier</button>
          <button className="profile-logout" onClick={removeLivestock}>Supprimer</button>
        </div>
      </div>
    );
  }

  function openLivestockEditor(animal?: import("@/lib/api").Livestock) {
    setLivestockFormError("");
    setLivestockForm({
      animal_type: animal?.animal_type || "",
      breed: animal?.breed || "",
      quantity: String(animal?.quantity ?? 1),
      age_months: animal?.age_months ? String(animal.age_months) : "",
      weight_kg: animal?.weight_kg ? String(animal.weight_kg) : "",
      health_status: animal?.health_status || "healthy",
      location: animal?.location || "",
      notes: animal?.notes || "",
      image_url: animal?.image_url || "",
      visibility: animal?.visibility || "PRIVATE",
    });
    setLivestockFormOpen(true);
  }

  async function handleLivestockPhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const image = event.target.files?.[0];
    if (!image || !session?.access_token) return;
    setLivestockPhotoLoading(true);
    try {
      const uploaded = await uploadImage(image, session.access_token);
      setLivestockForm((current) => ({ ...current, image_url: uploaded.url }));
    } catch (requestError) {
      setLivestockFormError(requestError instanceof Error ? requestError.message : "Photo impossible à envoyer.");
    } finally {
      setLivestockPhotoLoading(false);
    }
  }

  async function submitLivestock(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!session?.id || !session.access_token || !livestockForm.animal_type.trim()) return;
    setLivestockFormLoading(true);
    setLivestockFormError("");
    const payload = {
      animal_type: livestockForm.animal_type.trim(),
      breed: livestockForm.breed.trim() || undefined,
      quantity: Number(livestockForm.quantity) || 1,
      age_months: livestockForm.age_months ? Number(livestockForm.age_months) : undefined,
      weight_kg: livestockForm.weight_kg ? Number(livestockForm.weight_kg) : undefined,
      health_status: livestockForm.health_status,
      location: livestockForm.location.trim() || undefined,
      notes: livestockForm.notes.trim() || undefined,
      image_url: livestockForm.image_url.trim() || undefined,
      visibility: livestockForm.visibility,
    };
    try {
      const saved = selectedLivestock
        ? await updateLivestock(selectedLivestock.id, payload, session.access_token)
        : await createLivestock(payload, session.id, session.access_token);
      setLivestock((current) => selectedLivestock ? current.map((animal) => animal.id === saved.id ? saved : animal) : [saved, ...current]);
      setSelectedLivestock(saved);
      setLivestockFormOpen(false);
    } catch (requestError) {
      setLivestockFormError(requestError instanceof Error ? requestError.message : "Enregistrement impossible.");
    } finally {
      setLivestockFormLoading(false);
    }
  }

  async function removeLivestock() {
    if (!selectedLivestock || !session?.access_token || !window.confirm("Supprimer cet animal ?")) return;
    await deleteLivestock(selectedLivestock.id, session.access_token);
    setLivestock((current) => current.filter((animal) => animal.id !== selectedLivestock.id));
    setSelectedLivestock(null);
  }

  function renderLivestockForm() {
    return (
      <div className="livestock-view">
        <button className="back-action" onClick={() => setLivestockFormOpen(false)}><ArrowLeft size={15} aria-hidden="true" /> Retour aux animaux</button>
        <div className="section-page-heading"><div><p className="eyebrow">ÉLEVAGE · {selectedLivestock ? "MODIFIER" : "NOUVEL ANIMAL"}</p><h2>{selectedLivestock ? "Modifier l'animal" : "Ajouter un animal"}</h2></div></div>
        <form className="livestock-form" onSubmit={submitLivestock}>
          <label>Type d'animal<input required value={livestockForm.animal_type} onChange={(event) => setLivestockForm({ ...livestockForm, animal_type: event.target.value })} placeholder="Ex. Bovin" /></label>
          <label>Race<input value={livestockForm.breed} onChange={(event) => setLivestockForm({ ...livestockForm, breed: event.target.value })} /></label>
          <div className="form-row"><label>Quantité<input type="number" min="1" value={livestockForm.quantity} onChange={(event) => setLivestockForm({ ...livestockForm, quantity: event.target.value })} /></label><label>Âge en mois<input type="number" min="0" value={livestockForm.age_months} onChange={(event) => setLivestockForm({ ...livestockForm, age_months: event.target.value })} /></label></div>
          <div className="form-row"><label>Poids en kg<input type="number" min="0" step="0.1" value={livestockForm.weight_kg} onChange={(event) => setLivestockForm({ ...livestockForm, weight_kg: event.target.value })} /></label><label>État de santé<select value={livestockForm.health_status} onChange={(event) => setLivestockForm({ ...livestockForm, health_status: event.target.value })}><option value="healthy">En bonne santé</option><option value="sick">Malade</option><option value="under_treatment">En traitement</option></select></label></div>
          <label>Localisation<input value={livestockForm.location} onChange={(event) => setLivestockForm({ ...livestockForm, location: event.target.value })} /></label>
          <label className="photo-picker">Photo de l'animal<input type="file" accept="image/*" capture="environment" onChange={handleLivestockPhotoChange} disabled={livestockPhotoLoading} /><span>{livestockPhotoLoading ? "Envoi de la photo..." : "Choisir une image ou prendre une photo"}</span>{livestockForm.image_url && <img src={livestockForm.image_url} alt="Aperçu de l'animal" />}</label>
          <label>Notes<textarea value={livestockForm.notes} onChange={(event) => setLivestockForm({ ...livestockForm, notes: event.target.value })} rows={4} /></label>
          {livestockFormError && <p className="error-message" role="alert">{livestockFormError}</p>}
          <button className="primary-action" type="submit" disabled={livestockFormLoading}>{livestockFormLoading ? "Enregistrement..." : "Enregistrer"}</button>
        </form>
      </div>
    );
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

  function openFarmEditor(farm: Farm) {
    setFarmEditForm({
      name: farm.name,
      location: farm.location || "",
      size_hectares: farm.size_hectares ? String(farm.size_hectares) : "",
      soil_type: farm.soil_type || "",
      image_url: farm.image_url || "",
    });
    setFarmEditError("");
    setFarmEditOpen(true);
  }

  async function handleFarmPhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const image = event.target.files?.[0];
    if (!image || !session?.access_token) return;
    setFarmPhotoLoading(true);
    try {
      const uploaded = await uploadImage(image, session.access_token);
      setFarmEditForm((current) => ({ ...current, image_url: uploaded.url }));
    } catch (requestError) {
      setFarmEditError(requestError instanceof Error ? requestError.message : "Photo impossible à envoyer.");
    } finally {
      setFarmPhotoLoading(false);
    }
  }

  async function submitFarmEdit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedFarm || !session?.access_token || !farmEditForm.name.trim()) return;
    setFarmEditLoading(true);
    setFarmEditError("");
    try {
      await updateFarm(selectedFarm.farm.id, {
        name: farmEditForm.name.trim(),
        location: farmEditForm.location.trim() || undefined,
        size_hectares: farmEditForm.size_hectares.trim() ? Number(farmEditForm.size_hectares) : undefined,
        soil_type: farmEditForm.soil_type.trim() || undefined,
        image_url: farmEditForm.image_url.trim() || undefined,
      }, session.access_token);
      setFarms(await getFarms(session.access_token));
      setFarmEditOpen(false);
      await openFarm(selectedFarm.farm.id);
    } catch (requestError) {
      setFarmEditError(requestError instanceof Error ? requestError.message : "Modification impossible.");
    } finally {
      setFarmEditLoading(false);
    }
  }

  function openCropEditor(crop?: { id?: number; crop_name?: string; status?: string; area?: number }) {
    setEditingCropId(crop?.id ?? null);
    setCropForm({ crop_name: crop?.crop_name || "", status: crop?.status || "growing", area: crop?.area ? String(crop.area) : "" });
    setCropFormError("");
    setCropModalOpen(true);
  }

  async function submitCropForm(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedFarm || !session?.access_token || !cropForm.crop_name.trim()) return;
    setCropFormLoading(true);
    setCropFormError("");
    const payload = { crop_name: cropForm.crop_name.trim(), status: cropForm.status, area: cropForm.area ? Number(cropForm.area) : undefined };
    try {
      if (editingCropId) await updateCrop(editingCropId, payload, session.access_token);
      else await createCrop(selectedFarm.farm.id, payload, session.access_token);
      setCropModalOpen(false);
      await openFarm(selectedFarm.farm.id);
      setActionNotice(editingCropId ? "Parcelle mise à jour." : "Parcelle créée.");
    } catch (requestError) {
      setCropFormError(requestError instanceof Error ? requestError.message : "Enregistrement impossible.");
    } finally {
      setCropFormLoading(false);
    }
  }

  async function removeFarm() {
    if (!selectedFarm || !session?.access_token || !window.confirm(`Supprimer la ferme « ${selectedFarm.farm.name} » et toutes ses données ?`)) return;
    await deleteFarm(selectedFarm.farm.id, session.access_token);
    setFarms((current) => current.filter((farm) => farm.id !== selectedFarm.farm.id));
    setSelectedFarm(null);
    setActiveTab("Fermes");
  }

  async function removeParcel(
    cropId: number,
    farmId: number,
    cropName: string,
  ) {
    if (
      !session?.access_token ||
      !window.confirm(`Supprimer « ${cropName} » ?`)
    )
      return;
    await deleteCrop(cropId, session.access_token);
    await openFarm(farmId);
    setActionNotice("Parcelle supprimée.");
  }

  async function submitFarm(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!session?.id || !session.access_token) return;
    const form = new FormData(event.currentTarget);
    const name = String(form.get("name") || "").trim();
    if (!name) return;
    setFarmFormLoading(true);
    setFarmFormError("");
    try {
      const farm = await createFarm({
        name,
        location: String(form.get("location") || "").trim() || undefined,
        soil_type: String(form.get("soil_type") || "").trim() || undefined,
        size_hectares: form.get("size_hectares") ? Number(form.get("size_hectares")) : undefined,
      }, session.id, session.access_token);
      const refreshedFarms = await getFarms(session.access_token);
      setFarms(refreshedFarms);
      setActiveTab("Fermes");
      await openFarm(farm.id);
    } catch (requestError) {
      setFarmFormError(requestError instanceof Error ? requestError.message : "Création impossible.");
    } finally {
      setFarmFormLoading(false);
    }
  }

  function formatMoney(value = 0) {
    return (
      new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(
        value,
      ) + " FCFA"
    );
  }

  function formatDate(value?: string) {
    if (!value) return "Date non renseignée";
    const date = new Date(value);
    return Number.isNaN(date.getTime())
      ? "Date non renseignée"
      : new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" }).format(date);
  }

  async function openSaleDetails(sale: Record<string, unknown>) {
    setSelectedSale(sale);
    setSellerProfile(null);
    if (session?.access_token && sale.user_id) {
      try {
        setSellerProfile(await getUserProfile(Number(sale.user_id), session.access_token, session.id));
      } catch {
        setSellerProfile(null);
      }
    }
  }

  async function openComments(post: Record<string, unknown>) {
    if (!session?.access_token) return;
    setCommentsPost(post);
    setCommentsLoading(true);
    try {
      setComments(await getNetworkPostComments(Number(post.id), session.access_token));
    } finally {
      setCommentsLoading(false);
    }
  }

  async function submitComment(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!session?.access_token || !session.id || !commentsPost || !commentText.trim()) return;
    const created = await addNetworkPostComment(Number(commentsPost.id), session.id, commentText.trim(), session.access_token);
    setComments((current) => [...current, created]);
    setCommentText("");
    setNetworkPosts((current) => current.map((post) => post.id === commentsPost.id ? { ...post, comments_count: Number(post.comments_count || 0) + 1 } : post));
  }

  async function togglePostLike(post: Record<string, unknown>) {
    if (!session?.access_token) return;
    const isLiked = Boolean(post.is_liked);
    try {
      await (isLiked
        ? unlikeNetworkPost(Number(post.id), session.access_token)
        : likeNetworkPost(Number(post.id), session.access_token));
      setNetworkPosts((current) => current.map((item) => item.id === post.id ? {
        ...item,
        is_liked: !isLiked,
        likes_count: Math.max(0, Number(item.likes_count || 0) + (isLiked ? -1 : 1)),
      } : item));
    } catch (requestError) {
      setActionNotice(requestError instanceof Error ? requestError.message : "Impossible de modifier le like.");
    }
  }

  function renderNetworkView() {
    return <div className="social-view"><div className="section-page-heading"><div><p className="eyebrow">RÉSEAU AGRICOLE</p><h2>Les nouvelles du terrain</h2><p>Découvrez les publications des fermes et des agriculteurs suivis.</p></div><button className="outline-action" onClick={() => setActiveTab("Réseau")}><RefreshCw size={15} aria-hidden="true" /> Actualiser</button></div>{actionNotice && <p className="action-notice" role="alert">{actionNotice}</p>}{sectionLoading ? <div className="farm-detail-loading">Chargement du réseau...</div> : networkPosts.length ? <div className="social-feed">{networkPosts.map((post) => <article className="social-post" key={String(post.id)}>{Boolean(post.image_url) && <img src={String(post.image_url)} alt="" />}<div className="social-post-body"><div className="social-post-meta"><span><Sprout size={15} aria-hidden="true" /> {String(post.farm_name || "Ferme")}</span><small>{formatDate(String(post.created_at || ""))}</small></div><h3>{String(post.owner_name || "Agriculteur")}</h3><p>{String(post.caption || "Une nouvelle publication agricole.")}</p><div className="social-post-actions"><button onClick={() => togglePostLike(post)}><Heart size={16} fill={post.is_liked ? "currentColor" : "none"} aria-hidden="true" /> {String(post.likes_count || 0)}</button><button onClick={() => openComments(post)}><MessageCircle size={16} aria-hidden="true" /> {String(post.comments_count || 0)}</button></div></div></article>)}</div> : <div className="farms-empty-state"><Users size={38} aria-hidden="true" /><h3>Le réseau se construit ici.</h3><p>Les publications des fermes apparaîtront dès qu'elles seront partagées.</p></div>}{commentsPost && <div className="comments-modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setCommentsPost(null); }}><section className="comments-modal"><header><div><span className="metric-label">DISCUSSION</span><h3>{String(commentsPost.farm_name || "Publication")}</h3></div><button onClick={() => setCommentsPost(null)} aria-label="Fermer"><X size={20} /></button></header><div className="comments-list">{commentsLoading ? <p>Chargement...</p> : comments.length ? comments.map((comment) => <div className="comment-item" key={String(comment.id)}><strong>{String(comment.user_name || "Utilisateur")}</strong><p>{String(comment.comment || "")}</p></div>) : <p className="detail-empty">Aucun commentaire. Soyez le premier à répondre.</p>}</div><form onSubmit={submitComment}><input value={commentText} onChange={(event) => setCommentText(event.target.value)} placeholder="Écrire un commentaire..." /><button type="submit"><MessageCircle size={17} /></button></form></section></div>}</div>;
  }

  function renderMarketView() {
    return <div className="market-view"><div className="section-page-heading"><div><p className="eyebrow">MARCHÉ AGRICOLE</p><h2>Vendre et comparer</h2><p>Consultez les annonces et les prix de référence du marché.</p></div><button className="primary-action" onClick={() => setParcelModal(null)}><Store size={15} aria-hidden="true" /> Publier une annonce</button></div>{sectionLoading ? <div className="farm-detail-loading">Chargement du marché...</div> : <><section className="market-prices"><div className="section-heading"><div><span className="metric-label">PRIX DE RÉFÉRENCE</span><h3>Les cours récents</h3></div><TrendingUp size={20} aria-hidden="true" /></div><div className="market-price-grid">{marketPrices.slice(0, 8).map((price) => <div className="market-price-card" key={String(price.id)}><strong>{String(price.product_name || "Produit")}</strong><span><MapPin size={13} aria-hidden="true" /> {String(price.region || "Sénégal")}</span><b>{formatMoney(Number(price.price_per_kg || 0))} / kg</b><small>{formatDate(String(price.price_date || ""))}</small></div>)}</div>{!marketPrices.length && <p className="detail-empty">Aucun prix disponible pour le moment.</p>}</section><section className="market-sales"><div className="section-heading"><div><span className="metric-label">ANNONCES</span><h3>Produits à vendre</h3></div><span className="finance-badge">{marketSales.length}</span></div>{marketSales.length ? <div className="market-sales-grid">{marketSales.slice(0, 12).map((sale) => <button className="market-sale-card" key={String(sale.id)} onClick={() => openSaleDetails(sale)}>{Boolean(sale.image_url) && <img src={String(sale.image_url)} alt="" />}<div><span className="metric-label">{String(sale.category || "PRODUCTION")}</span><h3>{String(sale.product_name || "Produit")}</h3><p>{String(sale.quantity ?? "—")} {String(sale.unit || "kg")} · {String(sale.delivery_location || "Lieu non renseigné")}</p><strong>{formatMoney(Number(sale.price_per_unit || 0))} / unité</strong></div></button>)}</div> : <p className="detail-empty">Aucune annonce publiée pour le moment.</p>}</section></>}{selectedSale && <div className="sale-detail-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setSelectedSale(null); }}><section className="sale-detail-modal"><button className="modal-close" onClick={() => setSelectedSale(null)} aria-label="Fermer"><X size={20} aria-hidden="true" /></button>{Boolean(selectedSale.image_url) && <img className="sale-detail-image" src={String(selectedSale.image_url)} alt="" />}<div className="sale-detail-content">{sellerProfile && <div className="seller-profile"><div className="seller-avatar">{sellerProfile.profile_image ? <img src={sellerProfile.profile_image} alt="" /> : <Users size={18} aria-hidden="true" />}</div><div><span className="metric-label">VENDEUR</span><strong>{sellerProfile.name || "Agriculteur"}</strong><small>{sellerProfile.total_farms || 0} ferme(s) · {sellerProfile.total_followers || 0} abonné(s)</small></div></div>}<span className="metric-label">{String(selectedSale.category || "PRODUCTION")}</span><h2>{String(selectedSale.product_name || "Produit")}</h2><strong className="sale-detail-price">{formatMoney(Number(selectedSale.price_per_unit || 0))} / {String(selectedSale.unit || "unité")}</strong><div className="sale-detail-facts"><span>QUANTITÉ <b>{String(selectedSale.quantity ?? "—")} {String(selectedSale.unit || "")}</b></span><span>LOCALISATION <b>{String(selectedSale.delivery_location || "Non renseignée")}</b></span><span>MONNAIE <b>{String(selectedSale.currency || "FCFA")}</b></span></div><p>{String(selectedSale.description || "Aucune description pour cette annonce.")}</p>{Boolean(selectedSale.contact) && <a className="primary-action" href={`tel:${String(selectedSale.contact)}`}>Contacter le vendeur</a>}</div></section></div>}</div>;
  }

  function renderFarmDetail() {
    if (farmLoading)
      return (
        <div className="farm-detail-loading">Chargement de la ferme...</div>
      );
    if (!selectedFarm) return null;
    const { farm, crops, stats, finances, inputs, activities, transactions } =
      selectedFarm;
    const cover = farm.photos?.[0]?.image_url || farm.image_url;
    const totalIncome = transactions
      .filter((item) => item.transaction_type === "income")
      .reduce((sum, item) => sum + (item.amount ?? 0), 0);
    const totalExpenses = transactions
      .filter((item) => item.transaction_type === "expense")
      .reduce((sum, item) => sum + (item.amount ?? 0), 0);
    const cropInputs = (cropId: number) =>
      inputs.filter((item) => item.crop_id === cropId);
    const cropActivities = (cropId: number) =>
      activities.filter((item) => item.crop_id === cropId);
    const cropRoute = (cropId: number, page: string) =>
      `/farm/${farm.id}/parcel/${cropId}/${page}`;
    return (
      <div className="farm-detail-view">
        <div className="farm-detail-actions">
          <button className="back-action" onClick={() => setSelectedFarm(null)}>
            <ArrowLeft size={15} aria-hidden="true" /> Toutes les fermes
          </button>
          <div className="farm-detail-action-buttons">
            <button className="outline-action" onClick={() => openFarmEditor(farm)}>Modifier la ferme</button>
            <button className="danger-action farm-delete-action" onClick={removeFarm}>Supprimer la ferme</button>
          </div>
        </div>
        <div className="farm-detail-header">
          <div
            className="farm-cover"
            style={cover ? { backgroundImage: `url(${cover})` } : undefined}
          >
            <span>{cover ? "" : <Sprout size={48} aria-hidden="true" />}</span>
            <small>{farm.location || "LOCALISATION NON RENSEIGNÉE"}</small>
          </div>
          <div className="farm-detail-title">
            <p className="eyebrow">
              FICHE FERME · {farm.soil_type || "EXPLOITATION AGRICOLE"}
            </p>
            <h2>{farm.name}</h2>
            <p>
              {farm.size_hectares
                ? `${farm.size_hectares} hectares`
                : "Surface non renseignée"}{" "}
              · Données actualisées maintenant
            </p>
          </div>
        </div>
        <div className="farm-stats-strip">
          <div>
            <span>PARCELLES</span>
            <strong>{stats.parcel_count ?? crops.length}</strong>
          </div>
          <div>
            <span>REVENUS</span>
            <strong>{formatMoney(totalIncome || stats.total_revenue)}</strong>
          </div>
          <div>
            <span>RÉSULTAT NET</span>
            <strong
              className={
                totalIncome - totalExpenses >= 0 ? "positive" : "negative"
              }
            >
              {formatMoney(totalIncome - totalExpenses)}
            </strong>
          </div>
        </div>
        <div className="farm-detail-columns">
          <article className="detail-section">
            <div className="section-heading">
              <div>
                <span className="metric-label">PARCELLES & CULTURES</span>
                <h3>Ce qui pousse ici</h3>
              </div>
              <button
                className="text-action"
                onClick={() => openCropEditor()}
              >
                Ajouter <ArrowUpRight size={15} aria-hidden="true" />
              </button>
            </div>
            {actionNotice && (
              <p className="action-notice" role="status">
                {actionNotice}
              </p>
            )}
            {crops.length ? (
              <div className="crop-list">
                {crops.map((crop) => (
                  <div className="crop-entry" key={crop.id}>
                    <button
                      className="crop-row"
                      onClick={() =>
                        setExpandedCropId(
                          expandedCropId === crop.id ? null : crop.id,
                        )
                      }
                      aria-expanded={expandedCropId === crop.id}
                    >
                      <span className="crop-mark"></span>
                      {crop.image_url && (
                        <img
                          className="crop-thumb"
                          src={crop.image_url}
                          alt=""
                        />
                      )}
                      <span className="crop-row-copy">
                        <strong>
                          {crop.crop_name || "Culture"}
                          {crop.variety ? ` · ${crop.variety}` : ""}
                        </strong>
                        <span>
                          {crop.status || "En suivi"}
                          {crop.area ? ` · ${crop.area} m²` : ""} ·{" "}
                          {cropActivities(crop.id).length} activités ·{" "}
                          {cropInputs(crop.id).length} intrants
                        </span>
                      </span>
                      <span>
                        {crop.expected_yield
                          ? `${crop.expected_yield} kg`
                          : <ChevronDown size={16} aria-hidden="true" />}
                      </span>
                    </button>
                    {expandedCropId === crop.id && (
                      <div className="crop-expanded">
                        <div className="crop-meta">
                          <span>
                            PLANTÉE <b>{formatDate(crop.planted_date)}</b>
                          </span>
                          <span>
                            RÉCOLTE PRÉVUE{" "}
                            <b>{formatDate(crop.expected_harvest_date)}</b>
                          </span>
                          <span>
                            QUANTITÉ <b>{crop.quantity_planted ?? "—"}</b>
                          </span>
                          <span>
                            RENDEMENT{" "}
                            <b>
                              {crop.expected_yield
                                ? `${crop.expected_yield} kg`
                                : "—"}
                            </b>
                          </span>
                        </div>
                        {crop.notes && (
                          <p className="crop-notes">{crop.notes}</p>
                        )}
                        <div className="crop-actions">
                          <button
                            onClick={() => openCropEditor(crop)}
                          >
                            Modifier
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                `${cropActivities(crop.id).length} activité(s) chargée(s) pour cette parcelle.`,
                              )
                            }
                          >
                            Activités ({cropActivities(crop.id).length})
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                `${formatMoney(transactions.filter((item) => item.crop_id === crop.id).reduce((sum, item) => sum + (item.amount ?? 0), 0))} de transactions pour cette parcelle.`,
                              )
                            }
                          >
                            Finance
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                `${cropInputs(crop.id).length} intrant(s) chargé(s) pour cette parcelle.`,
                              )
                            }
                          >
                            Intrants ({cropInputs(crop.id).length})
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                "Les problèmes de culture seront disponibles dans la prochaine vue.",
                              )
                            }
                          >
                            Problèmes
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                "Les rappels de parcelle seront disponibles dans la prochaine vue.",
                              )
                            }
                          >
                            Rappels
                          </button>
                          <button
                            onClick={() =>
                              setActionNotice(
                                "L’export de parcelle sera disponible dans la prochaine vue.",
                              )
                            }
                          >
                            Télécharger
                          </button>
                          <button
                            className="danger-action"
                            onClick={() =>
                              removeParcel(
                                crop.id,
                                farm.id,
                                crop.crop_name || "Culture",
                              )
                            }
                          >
                            Supprimer
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="detail-empty">
                Aucune parcelle enregistrée pour cette ferme.
              </p>
            )}
          </article>
          <article className="detail-section finance-section">
            <div className="section-heading">
              <div>
                <span className="metric-label">FINANCES</span>
                <h3>Le mouvement</h3>
              </div>
              <span className="finance-badge">FCFA</span>
            </div>
            <div className="finance-total">
              <span>Revenus</span>
              <strong>{formatMoney(totalIncome || stats.total_revenue)}</strong>
            </div>
            <div className="finance-total">
              <span>Dépenses</span>
              <strong>
                {formatMoney(totalExpenses || stats.total_expenses)}
              </strong>
            </div>
            {transactions.length ? (
              <div className="product-list">
                <span className="metric-label">TRANSACTIONS</span>
                {transactions.slice(0, 5).map((item) => (
                  <div key={item.id} className="product-row">
                    <span>
                      {item.category || item.transaction_type || "Transaction"}
                      <small>{formatDate(item.transaction_date)}</small>
                    </span>
                    <strong
                      className={
                        item.transaction_type === "expense"
                          ? "expense-value"
                          : "income-value"
                      }
                    >
                      {item.transaction_type === "expense" ? "-" : "+"}
                      {formatMoney(item.amount)}
                    </strong>
                  </div>
                ))}
              </div>
            ) : (
              <p className="detail-empty">
                Aucune transaction financière enregistrée.
              </p>
            )}
          </article>
        </div>
        <div className="farm-data-columns">
          <article className="detail-section">
            <div className="section-heading">
              <div>
                <span className="metric-label">ACTIVITÉS</span>
                <h3>Dernières actions</h3>
              </div>
              <span className="finance-badge">{activities.length}</span>
            </div>
            {activities.length ? (
              activities.slice(0, 6).map((item) => (
                <div className="data-row" key={item.id}>
                  <span className="data-row-icon"></span>
                  <div>
                    <strong>{item.activity_type || "Activité"}</strong>
                    <span>
                      {formatDate(item.activity_date)}
                      {item.notes ? ` · ${item.notes}` : ""}
                    </span>
                  </div>
                  <b>
                    {item.finance_amount
                      ? formatMoney(item.finance_amount)
                      : ""}
                  </b>
                </div>
              ))
            ) : (
              <p className="detail-empty">Aucune activité enregistrée.</p>
            )}
          </article>
          <article className="detail-section">
            <div className="section-heading">
              <div>
                <span className="metric-label">INTRANTS</span>
                <h3>Stock utilisé</h3>
              </div>
              <span className="finance-badge">{inputs.length}</span>
            </div>
            {inputs.length ? (
              inputs.slice(0, 6).map((item) => (
                <div className="data-row" key={item.id}>
                  <span className="data-row-icon"><Package size={15} aria-hidden="true" /></span>
                  <div>
                    <strong>{item.name || item.input_type || "Intrant"}</strong>
                    <span>
                      {item.quantity ?? "—"} {item.unit || ""} ·{" "}
                      {formatDate(item.applied_date)}
                    </span>
                  </div>
                  <b>{item.cost ? formatMoney(item.cost) : ""}</b>
                </div>
              ))
            ) : (
              <p className="detail-empty">Aucun intrant enregistré.</p>
            )}
          </article>
        </div>
      </div>
    );
  }

  function renderFarmsView() {
    if (selectedFarm || farmLoading) return renderFarmDetail();
    if (activeTab === "Animaux") return renderLivestockView();
    if (activeTab === "Ajouter") return <div className="farm-create-view"><button className="back-action" onClick={() => setActiveTab("Fermes")}><ArrowLeft size={15} aria-hidden="true" /> Retour aux fermes</button><div className="section-page-heading"><div><p className="eyebrow">MA FERME · NOUVELLE EXPLOITATION</p><h2>Ajouter une ferme</h2><p>Créez votre espace pour suivre vos parcelles, activités et finances.</p></div></div><form className="farm-create-form" onSubmit={submitFarm}><label>Nom de la ferme<input name="name" required placeholder="Ex. Ferme familiale de Ndiaye" /></label><label>Localisation<input name="location" placeholder="Ex. Dakar, Sénégal" /></label><div className="form-row"><label>Surface en hectares<input name="size_hectares" type="number" min="0" step="0.01" placeholder="12.5" /></label><label>Type de sol<input name="soil_type" placeholder="Ex. argileux" /></label></div>{farmFormError && <p className="error-message" role="alert">{farmFormError}</p>}<button className="primary-action" type="submit" disabled={farmFormLoading}>{farmFormLoading ? "Création..." : "Créer la ferme"}</button></form></div>;
    return (
      <div className="farms-view">
        <div className="farms-view-heading">
          <div>
            <p className="eyebrow">MA FERME · ESPACE PRIVÉ</p>
            <h2>Vos fermes</h2>
            <p className="farms-view-subtitle">
              Suivez vos terres, vos cultures et votre élevage au même endroit.
            </p>
          </div>
          <button
            className="primary-action"
            onClick={() => setActiveTab("Ajouter")}
          >
            + Ajouter une ferme
          </button>
        </div>
        <div className="farm-section-tabs">
          <button className="selected">
            <Sprout size={15} aria-hidden="true" /> Fermes <b>{farms.length}</b>
          </button>
          <button onClick={() => setActiveTab("Animaux")}><Users size={15} aria-hidden="true" /> Animaux</button>
        </div>
        {farms.length ? (
          <div className="farm-cards-grid">
            {farms.map((farm) => (
              <button
                className="farm-detail-card"
                key={farm.id}
                onClick={() => openFarm(farm.id)}
              >
                <div
                  className="farm-detail-art"
                  style={
                    farm.image_url
                      ? {
                          backgroundImage: `url(${farm.image_url})`,
                          backgroundSize: "cover",
                          backgroundPosition: "center",
                        }
                      : undefined
                  }
                >
                  <span>{farm.image_url ? "" : <Sprout size={42} aria-hidden="true" />}</span>
                  <small>{farm.location || "LOCALISATION"}</small>
                </div>
                <div className="farm-detail-body">
                  <div>
                    <h3>{farm.name}</h3>
                    <p>
                      {farm.size_hectares
                        ? `${farm.size_hectares} hectares`
                        : "Surface non renseignée"}
                    </p>
                  </div>
                  <span className="farm-arrow"><ArrowUpRight size={18} aria-hidden="true" /></span>
                  <div className="farm-detail-stats">
                    <span>{farm.crops?.length ?? 0} cultures</span>
                  </div>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="farms-empty-state">
            <span className="empty-landmark"><Sprout size={42} aria-hidden="true" /></span>
            <p className="metric-label">AUCUNE FERME</p>
            <h3>Votre terre mérite un espace.</h3>
            <p>
              Créez votre première ferme pour commencer à suivre vos cultures et
              vos activités.
            </p>
            <button
              className="primary-action"
              onClick={() => setActiveTab("Ajouter")}
            >
              Créer ma première ferme
            </button>
          </div>
        )}
      </div>
    );
  }

  return (
    <main className="dashboard-shell">
      <header className="dashboard-topbar">
        <div className="brand dashboard-brand">
          <img className="brand-logo" src="/mbaymi-logo.png" alt="" />{" "}
          <span>mbaymi</span>
        </div>
        <div className="dashboard-actions">
          <button className="icon-button" aria-label="Rechercher">
            <Search size={24} aria-hidden="true" />
          </button>
          <button
            className="avatar-button"
            onClick={() => {
              setActiveTab("Profil");
              setMobileMenuOpen(false);
            }}
            aria-label="Ouvrir mon profil"
          >
            {userProfile?.profile_image ? <img src={userProfile.profile_image} alt={userProfile.name || "Profil"} /> : userProfile?.name?.charAt(0) ?? session?.name?.charAt(0) ?? "M"}
          </button>
          <button
            className={`dashboard-menu-trigger ${mobileMenuOpen ? "is-open" : ""}`}
            aria-label={mobileMenuOpen ? "Fermer le menu" : "Ouvrir le menu"}
            aria-expanded={mobileMenuOpen}
            aria-controls="dashboard-mobile-menu"
            onClick={() => setMobileMenuOpen((isOpen) => !isOpen)}
          >
            <Menu size={21} strokeWidth={1.8} aria-hidden="true" />
          </button>
        </div>
        {mobileMenuOpen && (
          <nav id="dashboard-mobile-menu" className="dashboard-mobile-menu" aria-label="Navigation mobile">
            {[
              ["Accueil", Home],
              ["Fermes", Sprout],
              ["Ajouter", null],
              ["Animaux", Users],
              ["Réseau", Users],
              ["Marché", Package],
              ["Paramètres", Settings],
            ].map(([label, Icon]) => (
              <button
                key={label as string}
                className={activeTab === label ? "is-active" : ""}
                onClick={() => {
                  setActiveTab(label as string);
                  setMobileMenuOpen(false);
                }}
              >
                {Icon ? <Icon size={18} aria-hidden="true" /> : <span className="mobile-add-icon">+</span>}
                {label as string}
              </button>
            ))}
          </nav>
        )}
      </header>

      <div className="dashboard-layout">
        <aside className="dashboard-sidebar">
          <nav aria-label="Navigation principale">
            <button
              className={`side-link ${activeTab === "Accueil" ? "is-active" : ""}`}
              onClick={() => setActiveTab("Accueil")}
            >
              <span>
                <Home size={18} aria-hidden="true" />
              </span>
              Accueil
            </button>
            <button
              className={`side-link ${activeTab === "Fermes" ? "is-active" : ""}`}
              onClick={() => setActiveTab("Fermes")}
            >
              <span>
                <Sprout size={18} aria-hidden="true" />
              </span>
              Fermes
            </button>
            <button
              className={`side-link ${activeTab === "Réseau" ? "is-active" : ""}`}
              onClick={() => setActiveTab("Réseau")}
            >
              <span>
                <Users size={18} aria-hidden="true" />
              </span>
              Réseau
            </button>
            <button
              className={`side-link ${activeTab === "Marché" ? "is-active" : ""}`}
              onClick={() => setActiveTab("Marché")}
            >
              <span>
                <Package size={18} aria-hidden="true" />
              </span>
              Marché
            </button>
          </nav>
          <button className="side-settings" onClick={() => setActiveTab("Paramètres")}>
            Paramètres
          </button>
        </aside>

        <section className="dashboard-content">
          {activeTab === "Profil" ? (
            renderProfileView()
          ) : activeTab === "Paramètres" ? (
            renderSettingsView()
          ) : activeTab === "Réseau" ? (
            renderNetworkView()
          ) : activeTab === "Marché" ? (
            renderMarketView()
          ) : activeTab === "Fermes" || activeTab === "Animaux" || activeTab === "Ajouter" ? (
            renderFarmsView()
          ) : (
            <>
              <div className="dashboard-heading">
                <div>
                  <p className="eyebrow">
                    {activeTab} · mardi 15 septembre 2026
                  </p>
                  <h1>
                    Bonjour,{" "}
                    <strong>
                      {session?.name?.split(" ")[0] ?? "producteur"}
                    </strong>
                  </h1>
                </div>
                <span className="season-tag">
                  <Sun size={14} aria-hidden="true" /> SAISON SÈCHE
                </span>
              </div>

              <div className="dashboard-grid">
                <article className="dashboard-hero panel-span-two">
                  <div className="hero-grain" />
                  <div className="hero-copy">
                    <p>LE JOUR COMMENCE ICI</p>
                    <h2>
                      Faire grandir
                      <br />
                      <em>l'essentiel.</em>
                    </h2>
                    <span>Votre activité agricole, au même endroit.</span>
                  </div>
                  <div className="hero-orbit orbit-one" />
                  <div className="hero-orbit orbit-two" />
                  <div className="hero-sun"></div>
                </article>

                <article className="metric-panel">
                  <span className="metric-label">MES FERMES</span>
                  <strong>{farms.length || "—"}</strong>
                  <span className="metric-note">
                    ferme{farms.length > 1 ? "s" : ""} enregistrée
                    {farms.length > 1 ? "s" : ""}
                  </span>
                  <div className="metric-line" />
                </article>
                <article className="weather-panel">
                  <div>
                    <span className="metric-label">MÉTÉO AUJOURD'HUI</span>
                    <strong>29°</strong>
                    <span className="metric-note">Ciel dégagé · Dakar</span>
                  </div>
                  <div className="weather-symbol">
                    <Sun size={42} aria-hidden="true" />
                  </div>
                </article>

                <article className="farms-panel panel-span-two">
                  <div className="section-heading">
                    <div>
                      <span className="metric-label">VOTRE TERRAIN</span>
                      <h3>Les fermes</h3>
                    </div>
                    <button
                      className="text-action"
                      onClick={() => setActiveTab("Fermes")}
                    >
                      Voir tout
                    </button>
                  </div>
                  {farms.length ? (
                    <div className="farm-list">
                      {farms.slice(0, 3).map((farm) => (
                        <div className="farm-row" key={farm.id}>
                          <span className="farm-icon">
                            {farm.image_url || farm.photos?.[0]?.image_url ? (
                              <img
                                src={farm.image_url || farm.photos?.[0]?.image_url}
                                alt={`Photo de ${farm.name}`}
                              />
                            ) : (
                              <Sprout size={18} aria-hidden="true" />
                            )}
                          </span>
                          <div>
                            <strong>{farm.name}</strong>
                            <span>
                              {farm.location || "Localisation non renseignée"}
                            </span>
                          </div>
                          <span className="farm-size">
                            {farm.size_hectares
                              ? `${farm.size_hectares} ha`
                              : "Ouvrir"}
                          </span>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="empty-farm">
                      <span><Sprout size={28} aria-hidden="true" /></span>
                      <p>Votre première ferme attend ici.</p>
                      <button
                        className="outline-action"
                        onClick={() => setActiveTab("Fermes")}
                      >
                        Créer une ferme
                      </button>
                    </div>
                  )}
                </article>

                <article className="tip-panel">
                  <span className="metric-label">CONSEIL DU JOUR</span>
                  <div className="tip-mark"></div>
                  <p>{tip}</p>
                  <button className="text-action">Conseils agricoles</button>
                </article>
                <article className="news-panel">
                  <div className="section-heading">
                    <div>
                      <span className="metric-label">À LA UNE</span>
                      <h3>Actualités</h3>
                    </div>
                    <span className="news-dot">●</span>
                  </div>
                  <div className="news-item">
                    <span>01</span>
                    <div>
                      <strong>Les gestes simples pour préserver l'eau</strong>
                      <small>Agriculture durable · Aujourd'hui</small>
                    </div>
                  </div>
                  <div className="news-item">
                    <span>02</span>
                    <div>
                      <strong>Préparer la prochaine récolte</strong>
                      <small>Conseils terrain · Cette semaine</small>
                    </div>
                  </div>
                </article>
              </div>
            </>
          )}
        </section>
      </div>

      {cropModalOpen && (
        <div className="farm-edit-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setCropModalOpen(false); }}>
          <section className="farm-edit-modal crop-edit-modal" role="dialog" aria-modal="true" aria-labelledby="crop-edit-title">
            <div className="action-modal-header">
              <div><span className="metric-label">PARCELLE</span><h2 id="crop-edit-title">{editingCropId ? "Modifier la parcelle" : "Ajouter une parcelle"}</h2></div>
              <button className="modal-close" onClick={() => setCropModalOpen(false)} aria-label="Fermer"><X size={20} aria-hidden="true" /></button>
            </div>
            <form className="modal-form" onSubmit={submitCropForm}>
              <label>Nom de la parcelle<input required value={cropForm.crop_name} onChange={(event) => setCropForm({ ...cropForm, crop_name: event.target.value })} placeholder="Ex. Parcelle Nord" /></label>
              <label>Statut<select value={cropForm.status} onChange={(event) => setCropForm({ ...cropForm, status: event.target.value })}><option value="growing">En croissance</option><option value="planned">Planifiée</option><option value="harvested">Récoltée</option><option value="paused">En pause</option></select></label>
              <label>Surface en m²<input type="number" min="0" step="0.01" value={cropForm.area} onChange={(event) => setCropForm({ ...cropForm, area: event.target.value })} /></label>
              {cropFormError && <p className="error-message" role="alert">{cropFormError}</p>}
              <button className="primary-action" type="submit" disabled={cropFormLoading}>{cropFormLoading ? "Enregistrement..." : "Enregistrer"}</button>
            </form>
          </section>
        </div>
      )}
      {farmEditOpen && (
        <div className="farm-edit-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setFarmEditOpen(false); }}>
          <section className="farm-edit-modal" role="dialog" aria-modal="true" aria-labelledby="farm-edit-title">
            <div className="action-modal-header">
              <div><span className="metric-label">MA FERME</span><h2 id="farm-edit-title">Modifier la ferme</h2></div>
              <button className="modal-close" onClick={() => setFarmEditOpen(false)} aria-label="Fermer"><X size={20} aria-hidden="true" /></button>
            </div>
            <form className="modal-form" onSubmit={submitFarmEdit}>
              <label>Nom de la ferme<input required value={farmEditForm.name} onChange={(event) => setFarmEditForm({ ...farmEditForm, name: event.target.value })} /></label>
              <label>Localisation<input value={farmEditForm.location} onChange={(event) => setFarmEditForm({ ...farmEditForm, location: event.target.value })} /></label>
              <label>Surface en hectares<input type="number" min="0" step="0.01" value={farmEditForm.size_hectares} onChange={(event) => setFarmEditForm({ ...farmEditForm, size_hectares: event.target.value })} /></label>
              <label>Type de sol<input value={farmEditForm.soil_type} onChange={(event) => setFarmEditForm({ ...farmEditForm, soil_type: event.target.value })} /></label>
              <label className="photo-picker">Photo de la ferme<input type="file" accept="image/*" capture="environment" onChange={handleFarmPhotoChange} disabled={farmPhotoLoading} /><span>{farmPhotoLoading ? "Envoi de la photo..." : "Choisir une image ou prendre une photo"}</span>{farmEditForm.image_url && <img src={farmEditForm.image_url} alt="Aperçu de la ferme" />}</label>
              {farmEditError && <p className="error-message" role="alert">{farmEditError}</p>}
              <button className="primary-action" type="submit" disabled={farmEditLoading}>{farmEditLoading ? "Enregistrement..." : "Enregistrer les modifications"}</button>
            </form>
          </section>
        </div>
      )}
      {parcelModal && selectedFarm && (
        <ParcelActionModal
          mode={parcelModal.mode}
          farmId={selectedFarm.farm.id}
          cropId={parcelModal.cropId}
          onClose={() => setParcelModal(null)}
        />
      )}
    </main>
  );
}
