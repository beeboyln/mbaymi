import { ArrowRight, ArrowUpRight, Sprout, X } from "lucide-react";

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
          <div className="menu-topline">
            <div className="menu-brand">
              <Sprout size={21} aria-hidden="true" />
              <span>MBAYMI</span>
              <small>Votre activité agricole, au même endroit.</small>
            </div>
            <button className="menu-close" onClick={onMenuClose} aria-label="Fermer le menu">
              <X size={22} aria-hidden="true" />
            </button>
          </div>
          <div className="menu-content">
            <div className="menu-navigation">
              <p className="menu-kicker">Explorer Mbaymi</p>
              <a className="is-active" href="#accueil" onClick={onMenuClose}>
                <span>01</span>Accueil<ArrowRight size={20} aria-hidden="true" />
              </a>
              <a href="#fermes" onClick={onMenuClose}>
                <span>02</span>Fermes<ArrowRight size={20} aria-hidden="true" />
              </a>
              <a href="#activites" onClick={onMenuClose}>
                <span>03</span>Activités<ArrowRight size={20} aria-hidden="true" />
              </a>
              <a href="#finances" onClick={onMenuClose}>
                <span>04</span>Finances<ArrowRight size={20} aria-hidden="true" />
              </a>
              <a href="#contact" onClick={onMenuClose}>
                <span>05</span>Contact<ArrowRight size={20} aria-hidden="true" />
              </a>
            </div>
            <aside className="menu-highlight">
              <span className="menu-highlight-label">AU RYTHME DE VOTRE FERME</span>
              <h2>Le terrain d&apos;abord. Le reste, en plus clair.</h2>
              <p>Retrouvez vos fermes, vos activités et vos décisions au même endroit.</p>
              <div className="menu-actions">
                <button className="menu-login menu-login-primary" onClick={() => { onMenuClose(); onRegister(); }}>
                  Créer mon compte <ArrowUpRight size={17} aria-hidden="true" />
                </button>
                <button className="menu-login menu-login-secondary" onClick={() => { onMenuClose(); onLogin(); }}>
                  Se connecter <ArrowUpRight size={17} aria-hidden="true" />
                </button>
              </div>
            </aside>
          </div>
          <div className="menu-bottomline">
            <span>Une agriculture mieux organisée, jour après jour.</span>
            <span>© Mbaymi 2026</span>
          </div>
        </nav>
      )}
    </header>
  );
}
