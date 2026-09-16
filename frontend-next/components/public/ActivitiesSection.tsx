type ActivitiesSectionProps = {
  onOpenLogin: () => void;
};

export default function ActivitiesSection({ onOpenLogin }: ActivitiesSectionProps) {
  return (
    <section id="activites" className="public-story public-story-light">
      <div className="story-board activity-board">
        <div className="board-label">AUJOURD&apos;HUI</div>
        <div className="activity-line"><b>06:40</b><span>Arrosage · Parcelle Nord</span><i>OK</i></div>
        <div className="activity-line"><b>09:15</b><span>Inspection · Serre 02</span><i>OK</i></div>
        <div className="activity-line"><b>16:30</b><span>Récolte · Tomates</span><i>À FAIRE</i></div>
      </div>
      <div className="public-story-copy">
        <span className="story-index">ACTIVITÉS</span>
        <h2>Gardez la mémoire du travail accompli.</h2>
        <p>Notez une activité, ajoutez une photo, associez un intrant ou un montant. Votre historique devient un outil de décision.</p>
        <button className="story-link" onClick={onOpenLogin}>Suivre mes activités</button>
      </div>
    </section>
  );
}
