"use client";

import { useEffect, useState } from "react";
import { login, register } from "@/lib/api";
import ActivitiesSection from "../components/public/ActivitiesSection";
import FeaturesSection from "../components/public/FeaturesSection";
import FieldLifeSection, { type ActiveFieldScene } from "../components/public/FieldLifeSection";
import FinalSection from "../components/public/FinalSection";
import FinanceSection from "../components/public/FinanceSection";
import FarmSection from "../components/public/FarmSection";
import HeroSection from "../components/public/HeroSection";
import IntroSection from "../components/public/IntroSection";
import LoginModal from "../components/public/LoginModal";
import PublicHeader from "../components/public/PublicHeader";
import RegisterModal from "../components/public/RegisterModal";

type FormSubmitEvent = {
  preventDefault: () => void;
};

export default function Home() {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [registerName, setRegisterName] = useState("");
  const [registerEmail, setRegisterEmail] = useState("");
  const [registerPhone, setRegisterPhone] = useState("");
  const [registerRegion, setRegisterRegion] = useState("");
  const [registerVillage, setRegisterVillage] = useState("");
  const [registerRole, setRegisterRole] = useState("farmer");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [loginOpen, setLoginOpen] = useState(false);
  const [registerOpen, setRegisterOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [headerVisible, setHeaderVisible] = useState(true);
  const [activeFieldScene, setActiveFieldScene] = useState<ActiveFieldScene>("cultures");
  const [harvestCount, setHarvestCount] = useState(0);

  useEffect(() => {
    let previousScrollY = window.scrollY;

    function handleScroll() {
      const currentScrollY = window.scrollY;
      if (currentScrollY < 12 || currentScrollY < previousScrollY) {
        setHeaderVisible(true);
      } else if (currentScrollY > previousScrollY) {
        setHeaderVisible(false);
      }
      previousScrollY = currentScrollY;
    }

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  async function handleSubmit(event: FormSubmitEvent) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const session = await login(identifier.trim(), password);
      window.localStorage.setItem("mbaymi_session", JSON.stringify(session));
      window.location.assign("/dashboard");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Connexion impossible.");
    } finally {
      setLoading(false);
    }
  }

  async function handleRegister(event: FormSubmitEvent) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const session = await register({
        name: registerName.trim(),
        email: registerEmail.trim() || undefined,
        phone: registerPhone.trim() || undefined,
        password,
        role: registerRole,
        region: registerRegion.trim(),
        village: registerVillage.trim() || undefined,
      });
      window.localStorage.setItem("mbaymi_session", JSON.stringify(session));
      window.location.assign("/dashboard");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Inscription impossible.");
    } finally {
      setLoading(false);
    }
  }

  function openLogin() {
    setError("");
    setRegisterOpen(false);
    setLoginOpen(true);
  }

  function openRegister() {
    setError("");
    setLoginOpen(false);
    setRegisterOpen(true);
  }

  return (
    <main className="public-home">
      <PublicHeader
        headerVisible={headerVisible}
        menuOpen={menuOpen}
        onMenuToggle={() => setMenuOpen((isOpen) => !isOpen)}
        onMenuClose={() => setMenuOpen(false)}
        onLogin={openLogin}
        onRegister={openRegister}
      />
      <HeroSection />
      <IntroSection />
      <FieldLifeSection
        activeScene={activeFieldScene}
        harvestCount={harvestCount}
        onSceneChange={setActiveFieldScene}
        onHarvest={() => setHarvestCount((count) => count + 1)}
      />
      <FarmSection onOpenLogin={openLogin} />
      <ActivitiesSection onOpenLogin={openLogin} />
      <FinanceSection onOpenLogin={openLogin} />
      <FeaturesSection />
      <FinalSection onOpenLogin={openLogin} />
      {loginOpen && (
        <LoginModal
          identifier={identifier}
          password={password}
          error={error}
          loading={loading}
          onIdentifierChange={setIdentifier}
          onPasswordChange={setPassword}
          onSubmit={handleSubmit}
          onClose={() => setLoginOpen(false)}
          onSwitchToRegister={openRegister}
        />
      )}
      {registerOpen && (
        <RegisterModal
          name={registerName}
          email={registerEmail}
          phone={registerPhone}
          region={registerRegion}
          village={registerVillage}
          role={registerRole}
          password={password}
          error={error}
          loading={loading}
          onNameChange={setRegisterName}
          onEmailChange={setRegisterEmail}
          onPhoneChange={setRegisterPhone}
          onRegionChange={setRegisterRegion}
          onVillageChange={setRegisterVillage}
          onRoleChange={setRegisterRole}
          onPasswordChange={setPassword}
          onSubmit={handleRegister}
          onClose={() => setRegisterOpen(false)}
          onSwitchToLogin={openLogin}
        />
      )}
    </main>
  );
}
