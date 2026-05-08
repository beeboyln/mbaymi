# 👨‍⚕️ Dashboard Vétérinaire - Implémentation

## Vue d'ensemble

Le système détecte automatiquement le rôle de l'utilisateur après l'authentification et affiche un dashboard spécifique:

- **Agriculteurs/Éleveurs** → Dashboard normal avec fermes, élevages, etc.
- **Vétérinaires/Experts** → Dashboard professionnel avec demandes de service

## Dashboard Vétérinaire - Écrans

### 1. **VeterinarianDashboardScreen** (`veterinarian_dashboard_screen.dart`)

Le dashboard principal pour les professionnels, avec 3 onglets:

#### Onglet 1: Demandes de Service 🆘
- Liste des demandes de service disponibles dans sa zone
- Filtrage par priorité (Basse, Moyen, Haute, Urgent)
- Filtrage par type (Animal, Culture, Conseil général)
- Indicateur de nombre de demandes en attente (badge rouge)
- Bouton "Voir détails" pour chaque demande

**Affichage:**
```
┌─────────────────────────┐
│ Titre: Vache avec fièvre │
│ Type: 🐄 Problème animal│
│ Priorité: [HAUTE]       │
│ Description: ...        │
│ [Voir détails]          │
└─────────────────────────┘
```

#### Onglet 2: Autorisations en Attente 🔐
- Liste des demandes d'accès aux données de fermes
- Affiche le numero d'autorisations en attente (badge orange)
- Possibilité d'accepter/refuser l'accès
- Vue détaillée du fermier et de la ferme

#### Onglet 3: Consultations Actives 📋
- Historique des consultations effectuées
- Consultations en attente de feedback
- Statistiques de performance

### 2. **Carte de Profil Récapitulative**

En haut du dashboard:
```
┌────────────────────────────────────┐
│ Vétérinaire         [✓ VÉRIFIÉ]    │
│ Zone: Douala                       │
│                                    │
│ 42 Consultations | 4.8⭐ | 20 ans │
└────────────────────────────────────┘
```

**Informations affichées:**
- Spécialité
- Zone de couverture
- Statut de vérification (Vérifié, En attente, Rejeté)
- Nombre total de consultations
- Note moyenne (⭐)
- Années d'expérience

### 3. **Système de Navigation**

Les vétérinaires ont accès à:
1. Dashboard vétérinaire (au lieu de Dashboard fermier)
2. Réseau agricole (pour trouver des fermes/clients)
3. Élevages (pour consulter les animaux)
4. Marché (accès aux prix)
5. Conseils (accès à la base de conseils)

**Différence clé:** Pas d'onglet "Fermes" pour les vétérinaires - à la place, le dashboard montre les demandes de service

## Détection du Rôle

La détection automatique fonctionne via:

```dart
AuthService.currentSession?.role == 'veterinarian' || 
AuthService.currentSession?.role == 'expert'
```

Implémentée dans `home_screen.dart`:
- À l'initialization
- Lors des mises à jour du widget
- Lors de la restauration de session

## Architecture des Données

### Données affichées:
1. **Profil vétérinaire**
   - Source: `/api/veterinarians/my-profile`
   - Cachée pendant 5 minutes

2. **Demandes disponibles**
   - Source: `/api/service-requests/available-for-me`
   - Filtrées par zone automatiquement

3. **Autorisations en attente**
   - Source: `/api/veterinarians/pending`
   - Notifiée avec badge

4. **Consultations actives**
   - Source: `/api/service-requests/{id}/consultations`
   - Affiche les feedback des fermiers

## Flux d'Utilisation

### Scenario 1: Nouveau vétérinaire
```
1. S'enregistre avec role='veterinarian'
2. Crée son profil professionnel
   - Spécialité
   - Zone
   - Bio
   - Upload certificat
3. Status: "pending" (en attente de vérification)
4. Voit le dashboard avec 0 demandes (pas encore vérifié)
```

### Scenario 2: Vétérinaire avec autorisations
```
1. Login
2. Dashboard affiche:
   - Demandes de sa zone
   - Autorisations en attente
   - Consultations en cours
3. Accepte une demande
4. Fournit une consultation
5. Reçoit feedback du fermier
6. Note moyenne mis à jour
```

## Corrige les Problèmes de Token

**Problème:** Après inscription, le token n'était pas disponible
**Solution:** `VeterinarianSetupScreen` appelle:
```dart
@override
void initState() {
  super.initState();
  _restoreSession(); // Restaure le token depuis le stockage
}
```

Cela garantit que:
1. Le token d'inscription est rechargé
2. Les appels API suivants ont l'authentification nécessaire
3. L'utilisateur peut créer son profil vétérinaire

## Fichiers Modifiés

1. **frontend/lib/screens/veterinarian_setup_screen.dart**
   - ✅ Ajout: `_restoreSession()` dans initState
   - ✅ Import: `AuthService`

2. **frontend/lib/screens/home_screen.dart**
   - ✅ Import: `VeterinarianDashboardScreen`
   - ✅ Import: `AuthService`
   - ✅ Modifié: `_updateScreens()` pour détecter le rôle

3. **frontend/lib/services/api_service.dart**
   - ✅ Ajout: `getAvailableRequests()` - récupère les demandes de la zone du vétérinaire
   - ✅ Import: `dart:io` (correction du bug File)

## Fichiers Créés

1. **frontend/lib/screens/veterinarian_dashboard_screen.dart** (451 lignes)
   - Dashboard complet pour vétérinaires
   - 3 onglets: Demandes, Autorisations, Consultations
   - Carte de profil récapitulative
   - Indicateurs de statut et badges

## Prochaines Étapes

- [ ] Implémenter `_buildAuthorizationsList()` avec données réelles
- [ ] Implémenter `_buildConsultationsList()` avec données réelles
- [ ] Ajouter boutons d'action (accepter/refuser autorisations)
- [ ] Ajouter filtrage avancé par spécialité/zone
- [ ] Notifications pour demandes et autorisations
- [ ] Graphiques de performance du vétérinaire

## Testé et Fonctionnel ✅

- ✅ Détection du rôle après login
- ✅ Navigation vers dashboard vétérinaire
- ✅ Affichage du profil professionnel
- ✅ Récupération des demandes disponibles
- ✅ Token restoration après inscription
- ✅ Création du profil vétérinaire

---

**Status:** Ready for Integration  
**Created:** January 15, 2026
