import { ArrowUpRight } from "lucide-react";

type FinalSectionProps = {
  onOpenLogin: () => void;
};

export default function FinalSection({ onOpenLogin }: FinalSectionProps) {
  return (
    <section id="contact" className="public-final">
      <p className="eyebrow">Commencer simplement</p>
      <h2>Votre prochaine décision<br /><em>commence ici.</em></h2>
      <button className="primary-action" onClick={onOpenLogin}>
        Ouvrir mon espace Mbaymi <ArrowUpRight size={16} aria-hidden="true" />
      </button>
    </section>
  );
}
