"use client";

import { FormEvent, useEffect, useState } from "react";
import {
  createActivity,
  createInput,
  createProblem,
  createReminder,
  createSale,
  createTransaction,
  getCropActivities,
  getCropInputs,
  getCropProblems,
  getCropReminders,
  getCropTransactions,
} from "@/lib/api";

type Mode = "activity" | "finance" | "problems" | "reminders";
type Props = { mode: Mode; farmId: number; cropId: number; onClose: () => void };

export default function ParcelActionModal({ mode, farmId, cropId, onClose }: Props) {
  const [token, setToken] = useState<string>();
  const [rows, setRows] = useState<Array<Record<string, unknown>>>([]);
  const [tab, setTab] = useState<"input" | "sale" | "transaction">("input");
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    const raw = window.localStorage.getItem("mbaymi_session");
    const session = raw ? JSON.parse(raw) as { access_token?: string } : null;
    setToken(session?.access_token);
  }, []);

  async function reload(accessToken = token) {
    if (!accessToken) return;
    const result = mode === "activity"
      ? await getCropActivities(cropId, accessToken)
      : mode === "finance"
        ? await getCropTransactions(cropId, accessToken)
        : mode === "problems"
          ? await getCropProblems(cropId, accessToken)
          : await getCropReminders(cropId, accessToken);
    setRows(result as Array<Record<string, unknown>>);
  }

  useEffect(() => { if (token) void reload(token); }, [token, mode, cropId]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    try {
      if (mode === "activity") {
        await createActivity({ farm_id: farmId, crop_id: cropId, activity_type: form.get("activity_type"), activity_date: form.get("activity_date") || undefined, notes: form.get("notes"), finance_type: form.get("finance_type") || undefined, finance_amount: form.get("finance_amount") ? Number(form.get("finance_amount")) : undefined }, token);
        setNotice("Activite enregistree.");
      } else if (mode === "problems") {
        const session = JSON.parse(window.localStorage.getItem("mbaymi_session") || "{}");
        await createProblem({ farm_id: farmId, crop_id: cropId, user_id: session.id, problem_type: form.get("problem_type"), severity: form.get("severity"), description: form.get("description") }, token);
        setNotice("Probleme signale.");
      } else if (mode === "reminders") {
        await createReminder({ farm_id: farmId, crop_id: cropId, title: form.get("title"), description: form.get("description"), remind_at: form.get("remind_at"), repeat_rule: form.get("repeat_rule") }, token);
        setNotice("Rappel cree.");
      } else if (tab === "input") {
        await createInput({ farm_id: farmId, crop_id: cropId, input_type: form.get("input_type"), name: form.get("name"), quantity: Number(form.get("quantity") || 0), unit: form.get("unit"), cost: Number(form.get("cost") || 0), notes: form.get("notes") }, token);
        setNotice("Intrant ajoute.");
      } else if (tab === "sale") {
        const session = JSON.parse(window.localStorage.getItem("mbaymi_session") || "{}");
        await createSale({ farm_id: farmId, crop_id: cropId, user_id: session.id, product_name: form.get("product_name"), quantity: Number(form.get("quantity") || 0), unit: form.get("unit"), price_per_unit: Number(form.get("price_per_unit") || 0), category: "Cultures", currency: "CFA", delivery_location: form.get("delivery_location"), contact: form.get("contact"), description: form.get("description") }, token);
        setNotice("Vente publiee.");
      } else {
        await createTransaction({ farm_id: farmId, crop_id: cropId, transaction_type: form.get("transaction_type"), category: form.get("category"), amount: Number(form.get("amount") || 0), notes: form.get("notes") }, token);
        setNotice("Transaction enregistree.");
      }
      formElement.reset();
      await reload(token);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Action impossible.");
    }
  }

  const title = mode === "activity" ? "Activites" : mode === "finance" ? "Finance, intrants et vente" : mode === "problems" ? "Problemes de culture" : "Rappels";
  return <div className="action-modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}><section className="action-modal" role="dialog" aria-modal="true" aria-labelledby="action-modal-title"><header className="action-modal-header"><div><p className="eyebrow">PARCELLE {cropId}</p><h2 id="action-modal-title">{title}</h2></div><button className="modal-close" onClick={onClose} aria-label="Fermer">×</button></header>{notice && <p className="action-notice" role="status">{notice}</p>}{error && <p className="error-message" role="alert">{error}</p>}
    {mode === "finance" && <nav className="modal-tabs"><button className={tab === "input" ? "selected" : ""} onClick={() => setTab("input")}>Intrants</button><button className={tab === "sale" ? "selected" : ""} onClick={() => setTab("sale")}>Vendre</button><button className={tab === "transaction" ? "selected" : ""} onClick={() => setTab("transaction")}>Transaction</button></nav>}
    <form className="modal-form" onSubmit={submit}>{mode === "activity" && <><input name="activity_type" required placeholder="Type d'activite: Semis, Arrosage..." /><input name="activity_date" type="date" /><input name="finance_amount" type="number" min="0" placeholder="Montant optionnel" /><select name="finance_type" defaultValue=""><option value="">Sans finance</option><option value="expense">Depense</option><option value="income">Revenu</option></select><textarea name="notes" placeholder="Notes terrain" /></>}{mode === "problems" && <><input name="problem_type" required placeholder="Maladie ou ravageur" /><select name="severity" defaultValue="medium"><option value="low">Faible</option><option value="medium">Moyenne</option><option value="high">Elevee</option></select><textarea name="description" required placeholder="Description du probleme" /></>}{mode === "reminders" && <><input name="title" required placeholder="Titre du rappel" /><textarea name="description" placeholder="Description" /><input name="remind_at" required type="datetime-local" /><select name="repeat_rule" defaultValue="none"><option value="none">Une fois</option><option value="daily">Quotidien</option><option value="weekly">Hebdomadaire</option></select></>}{mode === "finance" && tab === "input" && <><input name="input_type" required placeholder="Type: engrais, semence..." /><input name="name" required placeholder="Nom de l'intrant" /><div className="form-row"><input name="quantity" type="number" min="0" placeholder="Quantite" /><input name="unit" placeholder="Unite" /></div><input name="cost" type="number" min="0" placeholder="Cout FCFA" /><textarea name="notes" placeholder="Notes" /></>}{mode === "finance" && tab === "sale" && <><input name="product_name" required placeholder="Produit a vendre" /><div className="form-row"><input name="quantity" type="number" min="0" required placeholder="Quantite" /><input name="unit" defaultValue="kg" placeholder="Unite" /></div><input name="price_per_unit" type="number" min="0" required placeholder="Prix unitaire FCFA" /><input name="delivery_location" required placeholder="Lieu de livraison" /><input name="contact" required placeholder="Contact" /><textarea name="description" placeholder="Description de l'annonce" /></>}{mode === "finance" && tab === "transaction" && <><div className="form-row"><select name="transaction_type" defaultValue="expense"><option value="expense">Depense</option><option value="income">Revenu</option></select><input name="category" required placeholder="Categorie" /></div><input name="amount" type="number" min="0" required placeholder="Montant FCFA" /><textarea name="notes" placeholder="Notes" /></>}<button className="primary-action">Enregistrer</button></form><div className="modal-data"><h3>Donnees recentes</h3>{rows.length ? rows.slice(0, 6).map((row, index) => <div className="data-row" key={String(row.id ?? index)}><div><strong>{String(row.activity_type ?? row.name ?? row.title ?? row.category ?? row.problem_type ?? "Element")}</strong><span>{String(row.notes ?? row.description ?? row.input_type ?? row.status ?? "")}</span></div><b>{row.amount ? `${row.amount} FCFA` : String(row.activity_date ?? row.remind_at ?? "")}</b></div>) : <p className="detail-empty">Aucune donnee pour le moment.</p>}</div></section></div>;
}
