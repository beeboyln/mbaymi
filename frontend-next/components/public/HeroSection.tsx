import styles from "./HeroSection.module.css";

export default function HeroSection() {
  return (
    <section id="accueil" className={`${styles.hero} public-hero`}>
      <div className={`${styles.copy} public-hero-copy`}>
        <p className="eyebrow">L&apos;agriculture au quotidien</p>
        <h1>Votre terrain.<br /><em>Votre rythme.</em></h1>
      </div>
    </section>
  );
}
