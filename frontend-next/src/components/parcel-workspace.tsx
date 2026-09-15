"use client";

import { FormEvent, useEffect, useState } from "react";
import {
  createActivity,
  createInput,
  createReminder,
  createSale,
  createTransaction,
  getCropActivities,
  getCropInputs,
  getCropProblems,
  getCropReminders,
  getCropTransactions,
  type FarmActivity,
  type FarmInput,
  type FinanceTransaction,
} from "@/lib/api";

type Mode = "activity" | "finance" | "problems" | "reminders";
type Item = Record<string, unknown>;

type Props = { mode: Mode; farmId: number; cropId: number };

function money(value: unknown) {
  const amount = typeof value === "number" ? value : Number(value ?? 0);
  return `${new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(amount)} FCFA`;
}

function date(value: unknown) {
  if (!value) return "Date non renseignee";
  const parsed = new Date(String(value));
  return Number.isNaN(parsed.getTime()) ? "Date non renseignee" : new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" }).format(parsed);
}

export default function ParcelWorkspace({ mode, farmId, cropId }: Props) {
  const [token, setToken] = useState<string>();
  const [items, setItems] = useState<Array<FarmActivity | FarmInput | FinanceTransaction | Item>>([]);
  const [financeInputs, setFinanceInputs] = useState<FarmInput[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  useEffect(() => {
    const raw = window.localStorage.getItem("mbaymi_session");
    const session = raw ? JSON.parse(raw) as { access_token?: string } : null;
    if (!session?.access_token) {
      window.location.assign("/");
      return;
    }
    setToken(session.access_token);
  }, []);

  async function load(accessToken = token) {
    if (!accessToken) return;
    setLoading(true);
    setError("");
    try {
      if (mode === "finance") {
        const [transactions, inputList] = await Promise.all([getCropTransactions(cropId, accessToken), getCropInputs(cropId, accessToken)]);
        setItems(transactions);
        setFinanceInputs(inputList);
        return;
      }
      const result = mode === "activity"
        ? await getCropActivities(cropId, accessToken)
        : mode === "problems"
          ? await getCropProblems(cropId, accessToken)
          : await getCropReminders(cropId, accessToken);
      setItems(result);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Chargement impossible.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { if (token) void load(token); }, [token, mode, cropId]);

  async function submitActivity(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await createActivity({ farm_id: farmId, crop_id: cropId, activity_type: form.get("activity_type"), activity_date: form.get("activity_date") || undefined, notes: form.get("notes"), finance_type: form.get("finance_type") || undefined, finance_amount: form.get("finance_amount") ? Number(form.get("finance_amount")) : undefined }, token);
    formElement.reset(); setNotice("Activite enregistree."); await load(token);
  }

  async function submitInput(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await createInput({ farm_id: farmId, crop_id: cropId, input_type: form.get("input_type"), name: form.get("name"), quantity: Number(form.get("quantity") || 0), unit: form.get("unit"), cost: Number(form.get("cost") || 0), notes: form.get("notes") }, token);
    formElement.reset(); setNotice("Intrant ajoute et finance associe mis a jour."); await loadFinance(token);
  }

  async function submitSale(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await createSale({ farm_id: farmId, crop_id: cropId, product_name: form.get("product_name"), quantity: Number(form.get("quantity") || 0), unit: form.get("unit"), price_per_unit: Number(form.get("price_per_unit") || 0), category: "Cultures", currency: "CFA", delivery_location: form.get("delivery_location"), contact: form.get("contact"), description: form.get("description"), user_id: JSON.parse(window.localStorage.getItem("mbaymi_session") || "{}").id }, token);
    formElement.reset(); setNotice("Annonce de vente creee."); await loadFinance(token);
  }

  async function submitTransaction(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await createTransaction({ farm_id: farmId, crop_id: cropId, transaction_type: form.get("transaction_type"), category: form.get("category"), amount: Number(form.get("amount") || 0), transaction_date: form.get("transaction_date") || undefined, notes: form.get("notes") }, token);
    formElement.reset(); setNotice("Transaction enregistree."); await loadFinance(token);
  }

  async function submitReminder(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await createReminder({ farm_id: farmId, crop_id: cropId, title: form.get("title"), description: form.get("description"), remind_at: form.get("remind_at"), repeat_rule: form.get("repeat_rule") }, token);
    formElement.reset(); setNotice("Rappel cree."); await load(token);
  }

  async function submitProblem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    await fetch(`${process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://burning-yetty-bigboyme-428f3176.koyeb.app/api"}/crop-problems/`, { method: "POST", headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` }, body: JSON.stringify({ farm_id: farmId, crop_id: cropId, user_id: JSON.parse(window.localStorage.getItem("mbaymi_session") || "{}").id, problem_type: form.get("problem_type"), severity: form.get("severity"), description: form.get("description") }) });
    formElement.reset(); setNotice("Probleme signale."); await load(token);
  }

  async function loadFinance(accessToken: string) {
    const [transactions, inputList] = await Promise.all([getCropTransactions(cropId, accessToken), getCropInputs(cropId, accessToken)]);
    setItems(transactions);
    setFinanceInputs(inputList);
  }

  const title = mode === "activity" ? "Activites" : mode === "finance" ? "Finance" : mode === "problems" ? "Problemes" : "Rappels";
  const back = `/dashboard?farm=${farmId}&crop=${cropId}`;

  return <main className="workspace-page"><header className="workspace-header"><button className="back-action" onClick={() => window.location.assign(back)}>← Retour a la parcelle</button><p className="eyebrow">PARCELLE {cropId} · FERME {farmId}</p><h1>{title}</h1><p>Une page metier dediee, avec donnees et actions.</p></header>
    {notice && <p className="action-notice" role="status">{notice}</p>}
    {error && <p className="error-message" role="alert">{error}</p>}
    {mode === "activity" && <><form className="workspace-form" onSubmit={submitActivity}><h2>Nouvelle activite</h2><input name="activity_type" required placeholder="Type: Semis, Arrosage, Recolte..." /><input name="activity_date" type="date" /><input name="finance_amount" type="number" min="0" placeholder="Montant associe (optionnel)" /><select name="finance_type" defaultValue=""><option value="">Sans finance</option><option value="expense">Depense</option><option value="income">Revenu</option></select><textarea name="notes" placeholder="Notes terrain" /><button className="primary-action">Enregistrer l'activite</button></form><DataList items={items} kind="activity" /> </>}
    {mode === "finance" && <><div className="finance-workspace-grid"><form className="workspace-form" onSubmit={submitInput}><h2>Ajouter un intrant</h2><input name="input_type" required placeholder="Type: engrais, semence..." /><input name="name" required placeholder="Nom de l'intrant" /><div className="form-row"><input name="quantity" type="number" min="0" placeholder="Quantite" /><input name="unit" placeholder="Unite" /></div><input name="cost" type="number" min="0" placeholder="Cout FCFA" /><textarea name="notes" placeholder="Notes" /><button className="primary-action">Ajouter l'intrant</button></form><form className="workspace-form" onSubmit={submitSale}><h2>Vendre une production</h2><input name="product_name" required placeholder="Produit a vendre" /><div className="form-row"><input name="quantity" type="number" min="0" required placeholder="Quantite" /><input name="unit" defaultValue="kg" placeholder="Unite" /></div><input name="price_per_unit" type="number" min="0" required placeholder="Prix unitaire FCFA" /><input name="delivery_location" required placeholder="Lieu de livraison" /><input name="contact" required placeholder="Contact" /><textarea name="description" placeholder="Description de l'annonce" /><button className="primary-action">Publier la vente</button></form></div><form className="workspace-form" onSubmit={submitTransaction}><h2>Transaction financiere</h2><div className="form-row"><select name="transaction_type" defaultValue="expense"><option value="expense">Depense</option><option value="income">Revenu</option></select><input name="category" required placeholder="Categorie" /><input name="amount" type="number" min="0" required placeholder="Montant FCFA" /></div><textarea name="notes" placeholder="Notes" /><button className="outline-action">Ajouter la transaction</button></form><DataList items={financeInputs} kind="input" /><DataList items={items} kind="finance" /></>}
    {mode === "problems" && <><form className="workspace-form" onSubmit={submitProblem}><h2>Signaler un probleme</h2><input name="problem_type" required placeholder="Maladie, ravageur, jaunissement..." /><select name="severity" defaultValue="medium"><option value="low">Faible</option><option value="medium">Moyenne</option><option value="high">Elevee</option></select><textarea name="description" required placeholder="Description et traitement tente" /><button className="primary-action">Signaler</button></form><DataList items={items} kind="problem" /></>}
    {mode === "reminders" && <><form className="workspace-form" onSubmit={submitReminder}><h2>Creer un rappel</h2><input name="title" required placeholder="Titre du rappel" /><textarea name="description" placeholder="Description" /><input name="remind_at" required type="datetime-local" /><select name="repeat_rule" defaultValue="none"><option value="none">Une fois</option><option value="daily">Quotidien</option><option value="weekly">Hebdomadaire</option></select><button className="primary-action">Creer le rappel</button></form><DataList items={items} kind="reminder" /></>}
    {loading && <p className="detail-empty">Chargement...</p>}
  </main>;
}

function DataList({ items, kind }: { items: Array<FarmActivity | FarmInput | FinanceTransaction | Item>; kind: string }) {
  if (!items.length) return <p className="detail-empty">Aucune donnee enregistree.</p>;
  return <section className="workspace-list">{items.map((item, index) => { const row = item as Item; return <article className="workspace-item" key={String(row.id ?? index)}><div><strong>{String(row.activity_type ?? row.name ?? row.title ?? row.category ?? row.problem_type ?? "Element")}</strong><span>{String(row.notes ?? row.description ?? row.input_type ?? "")}</span></div><b>{row.amount ? money(row.amount) : String(row.activity_date ?? row.remind_at ?? row.status ?? "")}</b></article>; })}</section>;
}
