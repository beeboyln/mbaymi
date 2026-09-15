import Link from "next/link";

export default function TermsPage() {
  return (
    <main className="legal-page">
      <Link className="legal-back" href="/dashboard">Retour à Mbaymi</Link>
      <p className="eyebrow">INFORMATIONS LÉGALES</p>
      <h1>Conditions d'utilisation</h1>
      <p className="legal-lead">L'utilisation de Mbaymi implique l'acceptation de ces règles simples pour préserver un espace fiable pour tous les producteurs.</p>
      <section className="legal-content">
        <h2>Votre compte</h2>
        <p>Vous êtes responsable de l'exactitude des informations de votre compte et de la confidentialité de vos accès.</p>
        <h2>Vos contenus</h2>
        <p>Vous conservez vos contenus et vous vous engagez à publier uniquement des informations que vous êtes autorisé à partager.</p>
        <h2>Utilisation responsable</h2>
        <p>Les fonctionnalités de Mbaymi doivent être utilisées dans le respect des autres utilisateurs et des lois applicables.</p>
      </section>
    </main>
  );
}