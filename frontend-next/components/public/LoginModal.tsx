import type { FormEvent } from "react";
import { ArrowRight, LockKeyhole, Phone, X } from "lucide-react";
import styles from "./LoginModal.module.css";

type LoginModalProps = {
  identifier: string;
  password: string;
  error: string;
  loading: boolean;
  onIdentifierChange: (value: string) => void;
  onPasswordChange: (value: string) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onClose: () => void;
  onSwitchToRegister: () => void;
};

export default function LoginModal({
  identifier,
  password,
  error,
  loading,
  onIdentifierChange,
  onPasswordChange,
  onSubmit,
  onClose,
  onSwitchToRegister,
}: LoginModalProps) {
  const handleBackdropClick = (
    event: React.MouseEvent<HTMLDivElement>,
  ) => {
    if (event.target === event.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className={`${styles.backdrop} login-modal-backdrop`}
      role="presentation"
      onMouseDown={handleBackdropClick}
    >
      <section
        className={`${styles.modal} login-modal`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="login-title"
      >
        <button
          type="button"
          className={`${styles.close} modal-close`}
          onClick={onClose}
          aria-label="Fermer"
        >
          <X
            size={20}
            strokeWidth={1.8}
            aria-hidden="true"
          />
        </button>

        <div className={styles.header}>
          <div className="auth-modal-icon">
            <LockKeyhole
              size={20}
              strokeWidth={1.8}
              aria-hidden="true"
            />
          </div>

          <p className="eyebrow">
            Espace producteur
          </p>

          <h2 id="login-title">
            Content de vous revoir.
          </h2>

          <p className="auth-card-intro">
            Connectez-vous pour retrouver vos
            informations et gérer vos fermes.
          </p>
        </div>

        <form
          className={styles.form}
          onSubmit={onSubmit}
        >
          <div className="field">
            <label htmlFor="identifier">
              Email ou numéro de téléphone
            </label>

            <div className={styles.inputWrapper}>
              <Phone
                className={styles.inputIcon}
                size={18}
                strokeWidth={1.8}
                aria-hidden="true"
              />

              <input
                id="identifier"
                name="identifier"
                type="text"
                required
                value={identifier}
                onChange={(event) =>
                  onIdentifierChange(
                    event.target.value,
                  )
                }
                autoComplete="username"
                placeholder="Email ou numéro"
              />
            </div>
          </div>

          <div className="field">
            <div className={styles.fieldLabelRow}>
              <label htmlFor="password">
                Mot de passe
              </label>

              <button
                type="button"
                className={styles.forgotPassword}
              >
                Mot de passe oublié ?
              </button>
            </div>

            <div className={styles.inputWrapper}>
              <LockKeyhole
                className={styles.inputIcon}
                size={18}
                strokeWidth={1.8}
                aria-hidden="true"
              />

              <input
                id="password"
                name="password"
                type="password"
                required
                value={password}
                onChange={(event) =>
                  onPasswordChange(
                    event.target.value,
                  )
                }
                autoComplete="current-password"
                placeholder="Votre mot de passe"
              />
            </div>
          </div>

          {error && (
            <div
              className="error-message"
              role="alert"
            >
              <span>{error}</span>
            </div>
          )}

          <button
            className="submit-button"
            type="submit"
            disabled={loading}
          >
            <span>
              {loading
                ? "Connexion..."
                : "Se connecter"}
            </span>

            {!loading && (
              <ArrowRight
                size={18}
                strokeWidth={2}
                aria-hidden="true"
              />
            )}
          </button>
        </form>

        <div className={styles.divider}>
          <span>Pas encore de compte ?</span>
        </div>

        <button
          className={styles.switch}
          type="button"
          onClick={onSwitchToRegister}
        >
          Créer un compte
          <ArrowRight
            size={16}
            strokeWidth={2}
            aria-hidden="true"
          />
        </button>
      </section>
    </div>
  );
}