type FinanceSectionProps = {
  onOpenLogin: () => void;
};

export default function FinanceSection({ onOpenLogin }: FinanceSectionProps) {
  return (
    <section id="finances" className="public-story public-story-sand">
      <div className="public-story-copy">
        <span className="story-index">FINANCES</span>
        <h2>Comprenez le mouvement de votre ferme.</h2>
        <p>Intrants, dépenses, ventes et revenus se retrouvent au même endroit pour vous donner une lecture claire de votre activité.</p>
        <button className="story-link" onClick={onOpenLogin}>Voir mes finances</button>
      </div>
      <div className="story-board finance-board">
        <div className="board-label">CE MOIS-CI</div>
        <div className="finance-number">+ 184 500 <small>FCFA</small></div>
        <div className="finance-bars"><i /><i /><i /><i /><i /><i /></div>
        <div className="finance-caption"><span>Revenus</span><span>Dépenses · 72 000 FCFA</span></div>
      </div>
    </section>
  );
}
