import Link from "next/link";

export default function PrivacyPage() {
  return (
    <main className="legal-page">
      <Link className="legal-back" href="/dashboard">Retour à Mbaymi</Link>
      <p className="eyebrow">INFORMATIONS LÉGALES</p>
      <h1>Politique de confidentialité</h1>
      <p className="legal-lead">Mbaymi utilise vos informations uniquement pour vous permettre de gérer vos fermes, vos cultures et vos activités.</p>
      <section className="legal-content">
        <h2>Les informations collectées</h2>
        <p>Nous pouvons traiter votre nom, vos coordonnées, votre profil et les informations que vous saisissez au sujet de vos exploitations.</p>
        <h2>Vos données</h2>
        <p>Vos données restent liées à votre compte et ne sont pas vendues. Vous pouvez demander leur consultation ou leur suppression en contactant l'équipe Mbaymi.</p>
        <h2>Nous contacter</h2>
        <p>Pour toute question relative à vos données personnelles, utilisez le contact habituel de votre équipe Mbaymi.</p>
      </section>
    </main>
  );
}