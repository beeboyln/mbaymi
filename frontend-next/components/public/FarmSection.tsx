type FarmSectionProps = {
  onOpenLogin: () => void;
};

export default function FarmSection({ onOpenLogin }: Readonly<FarmSectionProps>) {
  return (
    <section id="fermes" className="public-story public-story-dark">
      <div className="public-story-copy">
        <span className="story-index">FERMES</span>
        <h2>Voyez votre exploitation comme elle est.</h2>
        <p>Chaque ferme garde son identité, sa localisation, ses photos et ses parcelles. Vous passez de la vue d&apos;ensemble au détail sans perdre le fil.</p>
        <button className="story-link" onClick={onOpenLogin}>Découvrir mon espace</button>
      </div>
      <div className="story-board farm-board">
        <div className="board-label">MA FERME</div>
        <strong>Les terres de Ndiaye</strong>
        <span>Dakar · 12,5 hectares</span>
        <div className="board-line"><i /><i /><i /></div>
        <small>4 parcelles suivies</small>
      </div>
    </section>
  );
}
