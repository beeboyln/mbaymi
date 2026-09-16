import type { FormEvent } from "react";
import { X } from "lucide-react";
import styles from "./LoginModal.module.css";

type RegisterModalProps = {
  name: string;
  email: string;
  phone: string;
  region: string;
  village: string;
  role: string;
  password: string;
  error: string;
  loading: boolean;
  onNameChange: (value: string) => void;
  onEmailChange: (value: string) => void;
  onPhoneChange: (value: string) => void;
  onRegionChange: (value: string) => void;
  onVillageChange: (value: string) => void;
  onRoleChange: (value: string) => void;
  onPasswordChange: (value: string) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onClose: () => void;
  onSwitchToLogin: () => void;
};

export default function RegisterModal({
  name,
  email,
  phone,
  region,
  village,
  role,
  password,
  error,
  loading,
  onNameChange,
  onEmailChange,
  onPhoneChange,
  onRegionChange,
  onVillageChange,
  onRoleChange,
  onPasswordChange,
  onSubmit,
  onClose,
  onSwitchToLogin,
}: RegisterModalProps) {
  return (
    <div className={`${styles.backdrop} login-modal-backdrop`} role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <section className={`${styles.modal} login-modal register-modal`} role="dialog" aria-modal="true" aria-labelledby="register-title">
        <button type="button" className={`${styles.close} modal-close`} onClick={onClose} aria-label="Fermer"><X size={20} aria-hidden="true" /></button>
        <p className="eyebrow">Nouvel espace producteur</p>
        <h2 id="register-title">Créer votre compte.</h2>
        <p className="auth-card-intro">Quelques informations suffisent pour commencer à suivre votre activité.</p>
        <form className={styles.form} onSubmit={onSubmit}>
          <div className="field"><label htmlFor="register-name">Nom complet</label><input id="register-name" required value={name} onChange={(event) => onNameChange(event.target.value)} autoComplete="name" /></div>
          <div className="field"><label htmlFor="register-email">Email</label><input id="register-email" type="email" value={email} onChange={(event) => onEmailChange(event.target.value)} autoComplete="email" /></div>
          <div className="field"><label htmlFor="register-phone">Téléphone</label><input id="register-phone" type="tel" value={phone} onChange={(event) => onPhoneChange(event.target.value)} autoComplete="tel" /></div>
          <p className="field-hint">Indiquez un email ou un téléphone.</p>
          <div className="form-row">
            <div className="field"><label htmlFor="register-region">Région</label><input id="register-region" required value={region} onChange={(event) => onRegionChange(event.target.value)} /></div>
            <div className="field"><label htmlFor="register-village">Village</label><input id="register-village" value={village} onChange={(event) => onVillageChange(event.target.value)} /></div>
          </div>
          <div className="field"><label htmlFor="register-role">Profil</label><select id="register-role" value={role} onChange={(event) => onRoleChange(event.target.value)}><option value="farmer">Producteur</option><option value="veterinarian">Vétérinaire</option><option value="agriculteur">Agriculteur</option></select></div>
          <div className="field"><label htmlFor="register-password">Mot de passe</label><input id="register-password" required minLength={6} type="password" value={password} onChange={(event) => onPasswordChange(event.target.value)} autoComplete="new-password" /></div>
          {error && <p className="error-message" role="alert">{error}</p>}
          <button className="submit-button" type="submit" disabled={loading}>{loading ? "Création..." : "Créer mon compte"}</button>
        </form>
        <button className={styles.switch} type="button" onClick={onSwitchToLogin}>J&apos;ai déjà un compte</button>
      </section>
    </div>
  );
}
