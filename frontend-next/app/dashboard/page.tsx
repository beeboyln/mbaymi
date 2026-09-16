"use client";

import type { ChangeEvent, FormEvent } from "react";
import { useEffect, useState } from "react";
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
import DashboardHeader from "../../components/dashboard/DashboardHeader";
import DashboardSidebar from "../../components/dashboard/DashboardSidebar";
import DashboardHome from "../../components/dashboard/DashboardHome";
import LivestockView from "../../components/dashboard/LivestockView";
import NetworkView from "../../components/dashboard/NetworkView";
import MarketView from "../../components/dashboard/MarketView";
import ProfileView from "../../components/dashboard/ProfileView";
import SettingsView from "../../components/dashboard/SettingsView";
import FarmView from "../../components/dashboard/FarmView";
import FarmDetailView from "../../components/dashboard/FarmDetailView";
import DashboardModals from "../../components/dashboard/DashboardModals";
import { Sprout, Sun } from "lucide-react";

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
type FormSubmitEvent = FormEvent<HTMLFormElement>;

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
    return <ProfileView session={session} userProfile={userProfile} onBack={() => setActiveTab("Accueil")} onLogout={logout} />;
  }

  function renderSettingsView() {
    return <SettingsView onBack={() => setActiveTab("Accueil")} />;
  }

  function renderLivestockView() {
    return <LivestockView farmsCount={farms.length} livestock={livestock} loading={livestockLoading} selectedLivestock={selectedLivestock} formOpen={livestockFormOpen} form={livestockForm} formLoading={livestockFormLoading} formError={livestockFormError} photoLoading={livestockPhotoLoading} onFarmTab={() => setActiveTab("Fermes")} onSelect={setSelectedLivestock} onClearSelection={() => setSelectedLivestock(null)} onOpenForm={() => { if (selectedLivestock) openLivestockEditor(selectedLivestock); else { setSelectedLivestock(null); openLivestockEditor(); } }} onCloseForm={() => setLivestockFormOpen(false)} onFormChange={setLivestockForm} onPhotoChange={handleLivestockPhotoChange} onSubmit={submitLivestock} onRemove={removeLivestock} />;
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

  async function submitLivestock(event: FormSubmitEvent) {
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

  async function submitFarmEdit(event: FormSubmitEvent) {
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

  async function submitCropForm(event: FormSubmitEvent) {
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

  async function submitFarm(event: FormSubmitEvent) {
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

  async function submitComment(event: FormSubmitEvent) {
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
    return <NetworkView posts={networkPosts} loading={sectionLoading} actionNotice={actionNotice} commentsPost={commentsPost} comments={comments} commentsLoading={commentsLoading} commentText={commentText} formatDate={formatDate} onRefresh={() => setActiveTab("Réseau")} onLike={togglePostLike} onOpenComments={openComments} onCloseComments={() => setCommentsPost(null)} onCommentTextChange={setCommentText} onSubmitComment={submitComment} />;
  }

  function renderMarketView() {
    return <MarketView prices={marketPrices} sales={marketSales} loading={sectionLoading} selectedSale={selectedSale} sellerProfile={sellerProfile ? { name: sellerProfile.name ?? undefined, profile_image: sellerProfile.profile_image ?? undefined, total_farms: sellerProfile.total_farms ?? undefined, total_followers: sellerProfile.total_followers ?? undefined } : null} formatMoney={formatMoney} formatDate={formatDate} onPublish={() => setParcelModal(null)} onOpenSale={openSaleDetails} onCloseSale={() => setSelectedSale(null)} />;
  }

  return (
    <main className="dashboard-shell">
      <DashboardHeader
        profileImage={userProfile?.profile_image ?? undefined}
        profileName={userProfile?.name}
        sessionName={session?.name}
        mobileMenuOpen={mobileMenuOpen}
        activeTab={activeTab}
        onProfile={() => { setActiveTab("Profil"); setMobileMenuOpen(false); }}
        onMenuToggle={() => setMobileMenuOpen((isOpen) => !isOpen)}
        onTabChange={(tab) => { setActiveTab(tab); setMobileMenuOpen(false); }}
      />

      <div className="dashboard-layout">
        <DashboardSidebar
          activeTab={activeTab}
          onTabChange={setActiveTab}
          onSettings={() => setActiveTab("Paramètres")}
        />

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
            selectedFarm || farmLoading ? (
              <FarmDetailView
                farm={selectedFarm}
                loading={farmLoading}
                expandedCropId={expandedCropId}
                actionNotice={actionNotice}
                formatMoney={formatMoney}
                formatDate={formatDate}
                onBack={() => setSelectedFarm(null)}
                onEditFarm={openFarmEditor}
                onDeleteFarm={removeFarm}
                onAddCrop={() => openCropEditor()}
                onEditCrop={openCropEditor}
                onToggleCrop={(cropId) => setExpandedCropId(expandedCropId === cropId ? null : cropId)}
                onNotice={setActionNotice}
                onDeleteParcel={removeParcel}
              />
            ) : activeTab === "Animaux" ? (
              renderLivestockView()
            ) : (
              <FarmView
                activeTab={activeTab}
                farms={farms}
                farmFormError={farmFormError}
                farmFormLoading={farmFormLoading}
                onTabChange={setActiveTab}
                onOpenFarm={openFarm}
                onSubmitFarm={submitFarm}
              />
            )
          ) : activeTab === "Accueil" ? (
            <DashboardHome
              activeTab={activeTab}
              firstName={session?.name?.split(" ")[0]}
              farms={farms}
              tip={tip}
              onTabChange={setActiveTab}
            />
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

      <DashboardModals
        cropOpen={cropModalOpen}
        cropEditingId={editingCropId}
        cropForm={cropForm}
        cropLoading={cropFormLoading}
        cropError={cropFormError}
        farmOpen={farmEditOpen}
        farmForm={farmEditForm}
        farmLoading={farmEditLoading}
        farmError={farmEditError}
        farmPhotoLoading={farmPhotoLoading}
        onCloseCrop={() => setCropModalOpen(false)}
        onCropChange={setCropForm}
        onSubmitCrop={submitCropForm}
        onCloseFarm={() => setFarmEditOpen(false)}
        onFarmChange={setFarmEditForm}
        onFarmPhotoChange={handleFarmPhotoChange}
        onSubmitFarm={submitFarmEdit}
      />
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
