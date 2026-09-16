import { ArrowUpRight } from "lucide-react";

type PublicHeaderProps = {
  headerVisible: boolean;
  menuOpen: boolean;
  onMenuToggle: () => void;
  onMenuClose: () => void;
  onLogin: () => void;
  onRegister: () => void;
};

export default function PublicHeader({
  headerVisible,
  menuOpen,
  onMenuToggle,
  onMenuClose,
  onLogin,
  onRegister,
}: Readonly<PublicHeaderProps>) {
  return (
    <header className={`public-topbar ${headerVisible ? "is-visible" : "is-hidden"}`}>
      <div className="brand">
        <img className="brand-logo" src="/mbaymi-logo.png" alt="" />
        <span>MBAYMI</span>
      </div>
      <div className="public-header-actions">
        <button
          className={`menu-trigger ${menuOpen ? "is-open" : ""}`}
          aria-label={menuOpen ? "Fermer le menu" : "Ouvrir le menu"}
          aria-expanded={menuOpen}
          aria-controls="public-menu"
          onClick={onMenuToggle}
        >
          <span aria-hidden="true" />
          <span aria-hidden="true" />
        </button>
      </div>
      {menuOpen && (
        <nav id="public-menu" className="public-menu" aria-label="Navigation principale">
          <a className="is-active" href="#accueil" onClick={onMenuClose}>Accueil</a>
          <a href="#fermes" onClick={onMenuClose}>Fermes</a>
          <a href="#activites" onClick={onMenuClose}>Activités</a>
          <a href="#finances" onClick={onMenuClose}>Finances</a>
          <a href="#contact" onClick={onMenuClose}>Contact</a>
          <button className="menu-login" onClick={() => { onMenuClose(); onLogin(); }}>
            Se connecter <ArrowUpRight size={15} aria-hidden="true" />
          </button>
          <button className="menu-login" onClick={() => { onMenuClose(); onRegister(); }}>
            Créer un compte <ArrowUpRight size={15} aria-hidden="true" />
          </button>
        </nav>
      )}
    </header>
  );
}
