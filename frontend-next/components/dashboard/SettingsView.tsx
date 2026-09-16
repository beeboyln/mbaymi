import { ArrowLeft, ArrowUpRight, Settings } from "lucide-react";

type SettingsViewProps = {
  onBack: () => void;
};

export default function SettingsView({ onBack }: Readonly<SettingsViewProps>) {
  return (
    <div className="settings-view">
      <button className="back-action" onClick={onBack}>
        <ArrowLeft size={15} aria-hidden="true" /> Retour à l&apos;accueil
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
          <div><strong>Conditions d&apos;utilisation</strong><small>Consultez les règles d&apos;utilisation de Mbaymi.</small></div>
          <ArrowUpRight size={17} aria-hidden="true" />
        </a>
        <div className="settings-item settings-item-static">
          <span><Settings size={19} aria-hidden="true" /></span>
          <div><strong>Gestion des données</strong><small>Pour toute demande concernant vos données, contactez l&apos;équipe Mbaymi.</small></div>
        </div>
      </div>
    </div>
  );
}
