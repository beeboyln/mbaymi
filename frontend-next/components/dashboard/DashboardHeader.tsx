import {
  Home,
  Menu,
  Package,
  Search,
  Settings,
  Sprout,
  Users,
} from "lucide-react";

type DashboardHeaderProps = {
  profileImage?: string;
  profileName?: string;
  sessionName?: string;
  mobileMenuOpen: boolean;
  activeTab: string;
  onProfile: () => void;
  onMenuToggle: () => void;
  onTabChange: (tab: string) => void;
};

const mobileItems: Array<[string, typeof Home | null]> = [
  ["Accueil", Home],
  ["Fermes", Sprout],
  ["Ajouter", null],
  ["Animaux", Users],
  ["Réseau", Users],
  ["Marché", Package],
  ["Paramètres", Settings],
];

export default function DashboardHeader({
  profileImage,
  profileName,
  sessionName,
  mobileMenuOpen,
  activeTab,
  onProfile,
  onMenuToggle,
  onTabChange,
}: Readonly<DashboardHeaderProps>) {
  return (
    <header className="dashboard-topbar">
      
      <div className="dashboard-actions">
        <button className="avatar-button" onClick={onProfile} aria-label="Ouvrir mon profil">
          {profileImage ? (
            <img src={profileImage} alt={profileName || "Profil"} />
          ) : (
            profileName?.charAt(0) ?? sessionName?.charAt(0) ?? "M"
          )}
        </button>
        <button
          className={`dashboard-menu-trigger ${mobileMenuOpen ? "is-open" : ""}`}
          aria-label={mobileMenuOpen ? "Fermer le menu" : "Ouvrir le menu"}
          aria-expanded={mobileMenuOpen}
          aria-controls="dashboard-mobile-menu"
          onClick={onMenuToggle}
        >
          <Menu size={21} strokeWidth={1.8} aria-hidden="true" />
        </button>
      </div>
      {mobileMenuOpen && (
        <nav id="dashboard-mobile-menu" className="dashboard-mobile-menu" aria-label="Navigation mobile">
          {mobileItems.map(([label, Icon]) => (
            <button
              key={label}
              className={activeTab === label ? "is-active" : ""}
              onClick={() => onTabChange(label)}
            >
              {Icon ? <Icon size={18} aria-hidden="true" /> : <span className="mobile-add-icon">+</span>}
              {label}
            </button>
          ))}
        </nav>
      )}
    </header>
  );
}
