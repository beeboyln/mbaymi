import { ArrowUpRight } from "lucide-react";

export type ActiveFieldScene = "cultures" | "elevage" | "recolte";

type FieldLifeSectionProps = {
  activeScene: ActiveFieldScene;
  harvestCount: number;
  onSceneChange: (scene: ActiveFieldScene) => void;
  onHarvest: () => void;
};

export default function FieldLifeSection({
  activeScene,
  harvestCount,
  onSceneChange,
  onHarvest,
}: FieldLifeSectionProps) {
  return (
    <section className="field-life" aria-labelledby="field-life-title">
      <div className="field-life-heading">
        <div>
          <p className="eyebrow">La vie de la ferme</p>
          <h2 id="field-life-title">Du premier geste<br /><em>jusqu&apos;à la récolte.</em></h2>
        </div>
        <p />
      </div>
      <div className="field-life-progress" aria-label="Progression de la journée">
        <span className={activeScene === "cultures" ? "is-active" : ""}>Cultures</span>
        <i />
        <span className={activeScene === "elevage" ? "is-active" : ""}>Élevage</span>
        <i />
        <span className={activeScene === "recolte" ? "is-active" : ""}>Récolte</span>
      </div>
      <div className="field-life-grid">
        <button type="button" className={`field-life-card ${activeScene === "cultures" ? "is-selected" : ""}`} onClick={() => onSceneChange("cultures")}>
          <img src="https://i.pinimg.com/1200x/da/e0/f7/dae0f77d186a3ccaf9d41d0e51c9e1cb.jpg" alt="Cultures dans un champ" />
          <div><span>CULTURES</span><h3>Planter avec attention.</h3><p>Parcelles, cultures et interventions restent au même endroit.</p></div>
        </button>
        <button type="button" className={`field-life-card ${activeScene === "elevage" ? "is-selected" : ""}`} onClick={() => onSceneChange("elevage")}>
          <img src="https://i.pinimg.com/1200x/c5/fc/18/c5fc181056a06c54220b9a331212b071.jpg" alt="Élevage à la ferme" />
          <div><span>ÉLEVAGE</span><h3>Veiller sur chaque bête.</h3><p>Gardez la mémoire du cheptel, de sa santé et de son évolution.</p></div>
        </button>
        <button type="button" className={`field-life-card ${activeScene === "recolte" ? "is-selected" : ""}`} onClick={() => { onSceneChange("recolte"); onHarvest(); }}>
          <img src="https://i.pinimg.com/736x/f8/85/a7/f885a7823e49117fc291716fff8a358b.jpg" alt="Récolte agricole" />
          <div>
            <span>RÉCOLTE</span>
            <h3>Voir le travail porter ses fruits.</h3>
            <p>Suivez les récoltes, les ventes et les décisions qui viennent ensuite.</p>
            {activeScene === "recolte" && <span className="harvest-action">Récolter maintenant <ArrowUpRight size={15} aria-hidden="true" /></span>}
          </div>
        </button>
      </div>
      {harvestCount > 0 && <output className="harvest-feedback"> </output>}
    </section>
  );
}
