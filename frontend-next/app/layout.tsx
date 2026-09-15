import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Mbaymi Web",
  description: "Gestion agricole Mbaymi",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr">
      <body>
        {children}
        <footer className="site-footer">
          <div className="site-footer-brand">
            <strong>mbaymi</strong>
            <span>Votre activité agricole, au même endroit.</span>
          </div>
          <nav className="site-footer-links" aria-label="Liens du pied de page">
            <a href="/confidentialite">Confidentialité</a>
            <a href="/conditions">Conditions</a>
            <a href="mailto:contact@mbaymi.com">Contact</a>
          </nav>
          <small className="site-footer-copy">© 2026 Mbaymi</small>
        </footer>
      </body>
    </html>
  );
}