import { Home, Package, Sprout, Users } from "lucide-react";

type DashboardSidebarProps = {
  activeTab: string;
  onTabChange: (tab: string) => void;
  onSettings: () => void;
};

export default function DashboardSidebar({
  activeTab,
  onTabChange,
  onSettings,
}: Readonly<DashboardSidebarProps>) {
  return (
    <aside className="dashboard-sidebar">
      <nav aria-label="Navigation principale">
        <button className={`side-link ${activeTab === "Accueil" ? "is-active" : ""}`} onClick={() => onTabChange("Accueil")}>
          <span>
            <Home size={18} aria-hidden="true" />
          </span>{" "}
          Accueil
        </button>
        <button className={`side-link ${activeTab === "Fermes" ? "is-active" : ""}`} onClick={() => onTabChange("Fermes")}>
          <span>
            <Sprout size={18} aria-hidden="true" />
          </span>{" "}
          Fermes
        </button>
        <button className={`side-link ${activeTab === "Réseau" ? "is-active" : ""}`} onClick={() => onTabChange("Réseau")}>
          <span>
            <Users size={18} aria-hidden="true" />
          </span>{" "}
          Réseau
        </button>
        <button className={`side-link ${activeTab === "Marché" ? "is-active" : ""}`} onClick={() => onTabChange("Marché")}>
          <span>
            <Package size={18} aria-hidden="true" />
          </span>{" "}
          Marché
        </button>
      </nav>
      <button className="side-settings" onClick={onSettings}>Paramètres</button>
    </aside>
  );
}
