import { Bell, CalendarDays, Home, Menu, Search, Sprout, Sun, UserRound, Users } from "lucide-react";
import styles from "./HeroSection.module.css";

export default function HeroSection() {
  return (
    <section id="accueil" className={`${styles.hero} public-hero`}>
      <div className={`${styles.copy} public-hero-copy`}>
        <p className="eyebrow">L&apos;agriculture au quotidien</p>
        <h1>Votre terrain.<br /><em>Votre rythme.</em></h1>
      </div>
      <div className={styles.phone} aria-label="Aperçu du tableau de bord Mbaymi">
        <div className={styles.phoneSpeaker} />
        <div className={styles.phoneScreen}>
          <div className={styles.appTopbar}>
            <UserRound size={12} />
            <div className={styles.appTopbarActions}>
              <Search size={12} />
              <Bell size={12} />
              <Menu size={13} />
            </div>
          </div>
          <div className={styles.appDate}>
            <span>Mercredi 16 septembre 2026</span>
            <b><Sun size={7} /> SAISON SÈCHE</b>
          </div>
          <div className={styles.appGreeting}>
            <span>Bonjour,</span>
            <strong>Bienvenue</strong>
          </div>
          <div className={styles.appLandscape}>
            <span>VOTRE TERRAIN</span>
            <i />
            <i />
            <i />
          </div>
          <div className={styles.appMessage}>
            <span><CalendarDays size={9} /></span>
            <div><small>UN MESSAGE POUR VOUS</small><strong>Appuyez pour découvrir</strong></div>
            <b>›</b>
          </div>
          <div className={styles.appWeather}>
            <div><small>MÉTÉO</small><strong>32<em>°C</em></strong><span>↓26° ↑32°</span></div>
            <div className={styles.appAdvice}><small>CONSEIL</small><strong>Forte chaleur prévue</strong><span>14 km/h vent</span></div>
          </div>
          <div className={styles.appBottomNav}>
            <span className={styles.active}><Home size={11} /><small>Accueil</small></span>
            <span><Sprout size={11} /><small>Fermes</small></span>
            <b>+</b>
            <span><Users size={11} /><small>Réseau</small></span>
            <span><Menu size={11} /><small>Marché</small></span>
          </div>
        </div>
      </div>
    </section>
  );
}
