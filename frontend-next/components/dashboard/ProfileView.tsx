import { ArrowLeft, UserRound } from "lucide-react";
import type { UserProfile } from "@/lib/api";

type Session = {
  name?: string;
  currency?: string;
};

type ProfileViewProps = {
  session: Session | null;
  userProfile: UserProfile | null;
  onBack: () => void;
  onLogout: () => void;
};

export default function ProfileView({
  session,
  userProfile,
  onBack,
  onLogout,
}: Readonly<ProfileViewProps>) {
  const profileName = userProfile?.name || session?.name || "Producteur";
  const profileEmail = userProfile?.email || "Email non renseigné";
  const profilePhone = userProfile?.phone || "Téléphone non renseigné";

  return (
    <div className="profile-view">
      <button className="back-action" onClick={onBack}>
        <ArrowLeft size={15} aria-hidden="true" /> Retour à l&apos;accueil
      </button>
      <div className="section-page-heading">
        <div>
          <p className="eyebrow">ESPACE PERSONNEL</p>
          <h2>Mon profil</h2>
          <p>Gérez vos informations et votre session Mbaymi.</p>
        </div>
      </div>
      <article className="profile-card">
        <div className="profile-card-header">
          <div className="profile-large-avatar">
            {userProfile?.profile_image ? (
              <img src={userProfile.profile_image} alt={`Photo de ${profileName}`} />
            ) : (
              <UserRound size={34} aria-hidden="true" />
            )}
          </div>
          <div>
            <span className="metric-label">PRODUCTEUR</span>
            <h3>{profileName}</h3>
            <p>Votre espace agricole personnel</p>
          </div>
        </div>
        <div className="profile-details">
          <div><span>Email</span><strong>{profileEmail}</strong></div>
          <div><span>Téléphone</span><strong>{profilePhone}</strong></div>
          <div><span>Devise</span><strong>{userProfile?.currency || session?.currency || "FCFA"}</strong></div>
        </div>
        <button className="profile-logout" onClick={onLogout}>Se déconnecter</button>
      </article>
    </div>
  );
}
