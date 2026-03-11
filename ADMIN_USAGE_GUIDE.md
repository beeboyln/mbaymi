# 📚 GUIDE D'UTILISATION - SYSTÈME ADMIN MBAYMI

**Date:** 6 Mars 2026  
**Pour:** Administrateurs de plateforme Mbaymi  

---

## 🎯 GUIDE RAPIDE: 3 MINUTES

### Accès au Tableau de Bord

```
1. Ouvrir l'app Mbaymi
2. Aller dans: Paramètres ⚙️
3. Chercher: "👨‍💼 ADMINISTRATION" (bas de la page)
4. Cliquer: "Tableau de Bord Admin"
5. Voir 5 onglets en haut
```

---

## 📊 ONGLET 1: TABLEAU DE BORD

### Comprendre les chiffres

```
VÉTÉRINAIRES               AUTORISATIONS
├─ En attente: 5          ├─ En attente: 3
├─ Vérifiés: 12           └─ Actives: 8
└─ Rejetés: 2
```

**Que faire:**
- ✅ Si en attente > 0 → Vérifier les demandes (Tab 2)
- ✅ Si rejetés augmente → Vérifier les raisons
- ✅ Si autorisations actives → Monitorer problèmes

---

## ⏳ ONGLET 2: VÉTÉRINAIRES EN ATTENTE

### Scénario 1: Vétérinaire avec bons papiers

```
Vous voyez:
├─ Nom: Dr. Jean Pierre
├─ Email: jean@example.com
├─ Spécialité: Élevage bovin
├─ Expérience: 5 ans
└─ Certificat: 📄 Diploma_2023.pdf

Action 1:
1. Cliquer "Vérifier" (vert)
2. Confirmer
✅ Status: PENDING → VERIFIED

Résultat:
- Dr. Jean Pierre peut voir des demandes d'accès
- Peut accepter des autorisations
- Peut fournir des consultations
```

### Scénario 2: Certificat douteux

```
Vous voyez:
├─ Nom: Unknown Vet
├─ Certificat: 📄 Fake_Diploma.pdf (nom suspect)
└─ Expérience: 0 ans (pas de expérience)

Action:
1. Cliquer "Rejeter" (rouge)
2. Dialog apparaît
3. Entrer raison: "Certificat invalide"
4. Confirmer
✅ Status: PENDING → REJECTED

Résultat:
- Vétérinaire reçoit notification
- Ne peut pas accéder à la plateforme
- Peut repostuler après correction
```

### Scénario 3: Douter d'un certificat

```
Vous voyez un certificat avec domaine bizarr:
- Certificat de "Université A" qui n'existe pas

Action:
1. Cliquer "Rejeter"
2. Raison: "Université non reconnue - veuillez repostuler avec l'accréditation"
3. Confirmer

Résultat:
- Email personnalisé envoyé au vétérinaire
- Raison spécifique fournie
```

---

## ✅ ONGLET 3: VÉTÉRINAIRES VÉRIFIÉS

### Monitoring des vétérinaires approuvés

```
Vous voyez:
├─ Dr. Jean Pierre ✅
│  ├─ Spécialité: Élevage bovin
│  ├─ Consultations: 15
│  ├─ Note moyenne: 4.8 ⭐
│  └─ Vérifié le: 15/02/2026

Interprétation:
- 15 consultations = actif ✅
- 4.8 étoiles = bonne qualité ✅
- Si < 3 étoiles → Vérifier les avis clients
```

### Actions recommandées
- Aucune action - Lecture seule
- Pour problèmes: Allez à Tab 5 pour révoquer si problème majeur

---

## ⏳ ONGLET 4: DEMANDES D'AUTORISATION EN ATTENTE

### Vue complète des demandes

```
Vous voyez:
├─ Farmer Mohamed ➜ Dr. Jean Pierre
│  ├─ Ferme: "Ferme Mohamed Douala"
│  ├─ Permissions:
│  │  ├─ 📊 Voir les données
│  │  ├─ 💡 Donner des conseils
│  │  └─ 🏠 Faire une visite
│  │
│  ├─ Raison: "Ma vache n'a pas d'appétit"
│  └─ Animaux: 1 animal autorisé
```

### Interpréter les demandes

| Permission | Signification |
|-----------|---------------|
| 📊 Données | Voir les détails animaux |
| 💡 Conseils | Peut donner des recommandations |
| 🏠 Visite | Peut venir voir l'animal |

### Votre rôle en tant qu'admin

- ✅ Lecture seule (monitoring)
- ✅ Vérifier que les demandes sont légitimes
- ❌ Les vétérinaires acceptent/rejettent (pas vous)
- ❌ Les fermiers envoient les demandes (pas vous)

### Signaux d'alerte

```
🚨 Si vous voyez:
- Même vét avec 50+ demandes → Peut être spam
- Demandes avec "raison" bizarr → Tracer si légitime
- Farmier avec demandes hourly → Comportement suspect

Action: Peut révoquer (Tab 5) si vraiment problème
```

---

## ✅ ONGLET 5: AUTORISATIONS ACTIVES

### Management des accès accordés

```
Vous voyez:
├─ Farmer Islamic ➜ Dr. Ahmed
│  ├─ Ferme: "Ferme Islamic Yaoundé"
│  ├─ Permissions: 📊 💡 🏠
│  └─ [Révoquer]  ← Bouton rouge

Status = ACCEPTED = Accès en cours
```

### Quand révoquer une autorisation?

#### ✅ Bonnes raisons
- Vétérinaire se comporte mal
- Fermier se plaint de mauvaise qualité
- Vétérinaire partage données inappropriée
- Contrat terminé entre les parties
- Vétérinaire fraudulent détecté

#### ❌ Mauvaises raisons
- Juste parce que la relation a changé
- Sans cause justifiée
- C'est au fermier de décider, pas vous

### Comment révoquer

```
1. Voir l'autorisation active
2. Cliquer "Révoquer" (rouge)
3. (Optionnel) Entrer raison: "Vétérinaire se comporte mal"
4. Confirmer

Résultat:
- Status: ACCEPTED → REVOKED
- Accès immédiatement coupé
- Vétérinaire notifié
- Fermier notifié (optionnel)
```

---

## 🔐 RESPONSABILITÉS IMPORTANTES

### Ne JAMAIS (Important!)
```
❌ Rejeter un vétérinaire juste parce que vous aimez pas
❌ Révoquer une autorisation sans bonne raison
❌ Partager les raisons de rejet publiquement
❌ Modifier les demandes des utilisateurs
```

### TOUJOURS (Important!)
```
✅ Donner des raisons claires aux rejets
✅ Maintenir logs de toutes les actions
✅ Être juste et impartial
✅ Répondre aux questions clientes
```

---

## 🎯 CASOS D'UTILISATION RÉELS

### Cas 1: Spécialiste agloméré

```
La situation:
- Dr. Chen envoie 30 demandes de vérification par jour
- Certificat valide, info vérifié
- Mais trop de demandes par jour

Que faire:
1. NE PAS rejeter directement
2. Vérifier dans logs si normal
3. Si spam bot: Rejeter avec raison "Comportement bot"
4. Si vrai: Vérifier et accepter

Leçon: Être sceptique mais juste
```

### Cas 2: Vétérinaire malfaisant

```
La situation:
- Dr. Abdi a une autorisation active
- Fermier Mohamed se plaint: "Il a pris une photo de ma ferme et l'a postée secrètement"
- Violation de données

Que faire:
1. Tab 5 → Trouver autorisation Dr. Abdi / Mohamed
2. Cliquer "Révoquer"
3. Raison: "Partage data non autorisé - violation"
4. Confirmer
5. Notifier les parties

Résultat:
- Dr. Abdi perd accès IMMÉDIATEMENT
- Fermier protégé
- Log gardé pour futur audit
```

### Cas 3: Certificat valide mais vétérinaire inexpérimenté

```
La situation:
- Dr. Lisa a diplôme valide
- Mais aucune expérience (0 ans)
- Email: "je suis étudiante"

Que faire:
1. Tab 2 → Voir Dr. Lisa
2. Cliquer "Rejeter"
3. Raison: "Pas d'expérience professionnelle - vérifié. Repostulez après 2+ ans d'expérience"
4. Confirmer

Raison: Protéger les fermiers des conseils d'étudiants
```

---

## 📞 FAQ ADMIN

### Q: Combien de temps pour vérifier?
```
A: Objectif = 24-48h max
   - Queue long = Vérifier plus vite
   - Queue vide = Vérifier quand demandé
```

### Q: Comment éviter les faux certificats?
```
A: 
1. Vérifier le hash du certificat (si diponible)
2. Appeler l'université directement
3. Si doute = Rejeter et demander relance
4. Farcir des dossiers = Bloquer le compte
```

### Q: Puis-je donner feedback au vétérinaire?
```
A: OUI!
- Rejet: Donnez raison claire
- Approbation: Donnez bienvenue message
- Support: Consultez si besoin spécial
```

### Q: Que faire si fermier/vet se plaint du rejet?
```
A:
1. Écouter leur appel
2. Vérifier si raison était juste
3. Si malentendu: Considérer re-appel
4. Si légitime: Réexpliquer avec exemple
```

---

## 💡 TIPS PRO

### Tip 1: Vérifier en batch
```
- Mettre 30 minutes par jour pour vérifier
- Faire X au lieu de scattering tout le jour
- Plus efficace et moins erreurs
```

### Tip 2: Noter les patterns
```
- Si beaucoup certifs de "Université X" = suspect
- Si beaucoup vét de zone "Douala" = normal (population)
- Si beaucoup "expert" = suspect (peu d'experts vrais)
```

### Tip 3: Protéger les fermiers
```
C'est votre JOB:
- Ne laissez pas arnaqueurs passer
- Mais aussi ne rejetez pas innocents
- Balance is key
```

---

## 🎓 POINTS CLÉS À RETENIR

1. **Vous êtes gatekeeper** - Décisions importantes
2. **Être juste & clair** - Donnez raisons
3. **Logs gardés** - Actions tracées
4. **Protéger fermiers** - Ils font confiance
5. **Vérifier vét légit** - Ils risquent leur reputation

---

## 📊 MONITORING RECOMMANDÉ

### Chaque jour
- [ ] Vérifier Tab 1: Statistiques
- [ ] Vérifier Tab 2: Demandes en attente

### Chaque semaine
- [ ] Vérifier Tab 3: Performances vét
- [ ] Vérifier Tab 4: Patterns demandes
- [ ] Vérifier Tab 5: Problèmes actifs

### Chaque mois
- [ ] Report complet des actions
- [ ] Audit des rejets
- [ ] Feedback du système

---

## 🆘 BESOIN D'AIDE?

```
Contactez:
- Support: support@mbaymi.com
- Manager: +221 78 466 69 12 (WhatsApp)
- Slack: #admin-system
```

---

**Bon administration! Merci d'être le gardien de Mbaymi! 🌍**

Prochainement: Formation vidéo prévue
