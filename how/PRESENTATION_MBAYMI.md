# Mbaymi - Présentation de l'application

## 1. Présentation simple

Mbaymi est une application agricole conçue pour aider les producteurs à gérer leur activité depuis un seul espace.

Elle réunit dans une même application :

- la gestion des fermes et des parcelles ;
- le suivi des cultures et du bétail ;
- la gestion des intrants et des dépenses ;
- le suivi financier de chaque parcelle ;
- un marché pour publier et consulter des offres ;
- un réseau pour échanger avec d'autres acteurs agricoles ;
- des conseils, la météo et des actualités agricoles.

L'objectif est de transformer des informations souvent dispersées dans des cahiers, des messages ou des fichiers en données organisées, accessibles et utiles pour prendre de meilleures décisions.

## 2. Discours court pour une présentation

> Mbaymi est une plateforme numérique dédiée au monde agricole. Elle permet à un producteur de gérer ses fermes, ses parcelles, ses cultures et son élevage depuis une seule application. Il peut suivre ses dépenses, ses intrants et ses revenus, consulter le marché, publier ses produits et échanger avec sa communauté. L'application apporte également des informations pratiques comme la météo et les actualités agricoles. Notre ambition est de rendre la gestion agricole plus simple, plus traçable et plus utile à la décision, tout en connectant les différents acteurs de la chaîne de valeur.

## 3. La page d'accueil

### Explication simple

La page d'accueil est le tableau de bord de l'utilisateur. Elle donne une vision rapide de ce qui est important au quotidien :

1. un message d'accueil personnalisé ;
2. la météo du jour ;
3. un conseil agricole ;
4. un aperçu des fermes de l'utilisateur ;
5. les actualités agricoles ;
6. des accès rapides vers les autres espaces de l'application.

Elle évite à l'utilisateur de chercher l'information dans plusieurs menus. Dès l'ouverture, il voit les éléments qui peuvent influencer son travail agricole.

### Explication technique

La page est portée par `DashboardTab`, appelée à l'index `0` de `HomeScreen` pour les utilisateurs classiques. Elle utilise des `FutureBuilder` Flutter pour afficher progressivement les données : l'interface peut apparaître immédiatement, puis les cartes se remplissent lorsque les réponses arrivent.

La page est responsive :

- sur ordinateur, les informations sont organisées en deux colonnes ;
- sur mobile, elles sont présentées verticalement.

Un rafraîchissement manuel vide les caches météo et actualités, recharge les fermes et rejoue l'animation d'entrée.

### Pourquoi les vagues du design ?

#### Explication simple pour la présentation

Les vagues représentent le mouvement et le lien avec le monde agricole : les sillons d'un champ, le relief d'un paysage et le mouvement naturel de l'environnement. Elles donnent à l'accueil une identité visuelle vivante sans utiliser une image lourde ou une décoration sans rapport avec l'agriculture.

Elles sont discrètes pour que le contenu reste prioritaire. Leur mouvement lent apporte une sensation de vie et de continuité, tout en conservant une interface professionnelle.

Tu peux le dire ainsi :

> Les vagues de la page d'accueil ne sont pas un élément décoratif choisi au hasard. Elles évoquent les lignes d'un champ et le mouvement naturel du monde agricole. Elles permettent de donner une identité à l'application tout en restant légères et en laissant les informations importantes au premier plan.

#### Explication technique

Les vagues sont générées directement en Flutter par la classe `_WavePainter`, qui hérite de `CustomPainter`. Il ne s'agit pas d'une image importée ni d'un visuel généré automatiquement.

Le painter construit un `Path` :

1. il part du bas de la zone ;
2. il parcourt la largeur par petits intervalles ;
3. il calcule la hauteur de chaque point avec plusieurs fonctions sinus et cosinus ;
4. il ferme la forme jusqu'au bas de l'écran ;
5. il remplit la surface avec une couleur semi-transparente.

La forme utilise trois oscillations superposées. La première donne le mouvement principal, la deuxième ajoute une variation plus fine et la troisième évite que la ligne paraisse artificiellement régulière. C'est cette combinaison qui produit une vague douce et organique.

Un `AnimationController` de neuf secondes fait varier progressivement la variable `phase`. Le painter est alors redessiné et la vague se déplace lentement. Deux vagues légèrement décalées sont superposées dans le hero, avec des opacités différentes, afin de créer une profondeur visuelle.

Le même principe est réutilisé avec une autre position et une autre phase sur le bandeau de ferme. Le résultat est donc cohérent dans toute la page tout en restant léger pour les performances : Flutter dessine les formes localement, sans téléchargement d'image.

## 4. Météo

### Explication simple

La météo aide le producteur à adapter ses activités : irrigation, protection des cultures et organisation des travaux.

La carte affiche notamment la température maximale et minimale, l'état du ciel, le vent et un conseil comme :

- `Ciel dégagé` ;
- `Forte chaleur prévue` ;
- `Pluies prévues`.

### Explication technique

La météo utilise l'API publique **Open-Meteo** :

```text
https://api.open-meteo.com/v1/forecast
```

Aucune clé API n'est nécessaire.

La position configurée par défaut est Dakar : latitude `14.6667`, longitude `-17.0382`, fuseau `Africa/Dakar`. Le dashboard appelle actuellement le service sans activer le GPS. Le service contient toutefois un mode GPS optionnel avec `geolocator` et un reverse geocoding Nominatim.

Les données demandées sont la température actuelle, la température ressentie, les températures minimale et maximale du jour et les codes météo. Les conseils sont ensuite calculés localement dans l'application.

En cas d'erreur réseau, des valeurs de secours sont utilisées pour que la page reste exploitable.

## 5. Actualités agricoles

### Explication simple

La rubrique actualités permet de rester informé sur l'agriculture, l'élevage, le Sénégal et les sujets internationaux. L'utilisateur peut filtrer les articles par catégorie et ouvrir le détail d'une actualité.

### Explication technique

Le mobile appelle le backend Mbaymi, et non Google directement :

```text
Flutter -> Backend Mbaymi -> Google News RSS -> Backend -> Flutter
```

Le backend expose :

```text
GET /api/news/agricultural
```

Il interroge quatre flux RSS Google News :

- agriculture ;
- élevage et bétail ;
- agriculture au Sénégal ;
- agriculture internationale.

Le backend lit le XML RSS, nettoie les balises HTML, extrait les titres, descriptions, dates, sources et liens, puis renvoie un JSON uniforme à l'application. Il conserve jusqu'à trois articles par flux.

Si les flux ne répondent pas, le backend et le frontend disposent chacun d'une liste d'articles de secours.

## 6. Fermes et parcelles

### Explication simple

L'espace Fermes permet de créer et gérer les exploitations de l'utilisateur. Une ferme peut contenir des parcelles, des cultures, des photos, des informations de localisation et des données de production.

L'utilisateur peut consulter une ferme, modifier ses informations, gérer ses parcelles et accéder aux finances et aux intrants de chaque culture.

### Explication technique

Les données sont chargées depuis le backend avec des endpoints protégés par authentification. Le frontend passe généralement par `DataRepository`, qui centralise les accès aux fermes, cultures et animaux.

Le cache utilise des clés liées à l'utilisateur et à la ferme :

- fermes d'un utilisateur : TTL de deux minutes ;
- cultures d'une ferme : TTL de deux minutes ;
- élevage d'un utilisateur : TTL de deux minutes.

Après une création, modification ou suppression, les caches concernés sont invalidés et un événement de changement est émis. Un rafraîchissement recharge uniquement les données nécessaires.

## 7. Réseau agricole

### Explication simple

Le Réseau est l'espace social de Mbaymi. Il permet aux utilisateurs de publier des photos ou des informations sur leurs activités, de découvrir les publications d'autres agriculteurs et d'interagir avec la communauté.

Il favorise le partage d'expérience et la visibilité des producteurs.

### Explication technique

L'écran `FarmNetworkScreen` délègue l'affichage à `SocialFeedScreen`. Les publications, profils, abonnements et interactions sont gérés par le backend social.

Le fil est une donnée dynamique : son cache doit être plus court que celui des fermes. L'architecture prévoit un TTL d'environ trente secondes pour les publications, ainsi qu'une invalidation lorsqu'une publication ou un abonnement est créé ou modifié.

## 8. Marché

### Explication simple

Le Marché met en relation les producteurs et les acheteurs. Un utilisateur peut consulter les offres, rechercher un produit, filtrer par catégorie ou localisation, consulter les prix et publier ses propres annonces.

Le module peut également gérer un panier et afficher le détail d'une offre.

### Explication technique

Le marché utilise les services API pour :

- charger les annonces ;
- charger les annonces de l'utilisateur ;
- charger les prix du marché ;
- créer, modifier ou supprimer une offre.

Les annonces sont conservées dans un cache global côté frontend avec un TTL d'une minute. Les prix disposent d'un cache séparé. Lors d'un pull-to-refresh ou après une modification, les caches du marché sont vidés et les listes sont rechargées.

Cette durée courte est adaptée au marché, car les annonces et les prix évoluent plus rapidement que les informations descriptives d'une ferme.

## 9. Finances

### Explication simple

La gestion financière permet de suivre les revenus et les dépenses liés à une culture ou à une parcelle. L'utilisateur peut enregistrer une transaction, consulter le résumé financier et mesurer la rentabilité de son activité.

Cela permet de répondre à des questions concrètes : combien a coûté cette culture, combien a-t-elle rapporté et quel est le résultat net ?

### Explication technique

Les finances sont rattachées à une culture précise dans une parcelle. L'écran charge :

- la liste des transactions ;
- le résumé financier de la culture.

Les appels principaux sont effectués par `ApiService.listTransactionsForCrop()` et `ApiService.getFinanceSummaryForCrop()`.

Les données peuvent être filtrées par type et période, puis exportées dans un document de traçabilité. Le calcul et la conservation des données sont réalisés côté backend ; le frontend se charge de les afficher et de les présenter.

## 10. Intrants

### Explication simple

Le module Intrants permet de suivre ce qui est utilisé sur une parcelle : semences, engrais, pesticides, eau, outils ou autres équipements.

Pour chaque intrant, l'utilisateur peut conserver des informations comme le type, la quantité, l'unité et le coût. Cette traçabilité aide à mieux contrôler les dépenses et à comprendre les résultats d'une culture.

### Explication technique

Les intrants sont liés à l'identifiant de la culture. L'écran appelle `ApiService.listInputsForCrop()` pour charger la liste et utilise les endpoints de création, modification et suppression pour maintenir les données.

Les types d'intrants sont distingués visuellement dans l'application. Les données peuvent également être exportées dans un rapport de traçabilité.

Les intrants et les finances sont volontairement liés à la parcelle : une dépense ou un produit utilisé doit pouvoir être attribué à une culture précise.

## 11. Élevage

### Explication simple

Le module Élevage permet de suivre les animaux de l'exploitation : identification, espèce, race, poids, état de santé, traitements, vaccinations, reproduction et production.

L'objectif est de remplacer un suivi dispersé par une fiche complète pour chaque animal.

### Explication technique

Les animaux sont gérés par des endpoints dédiés. Les fiches peuvent inclure les dossiers de santé, les rappels, la reproduction et la production comme le lait, les oeufs ou la viande.

Le frontend met en cache la liste d'élevage pendant environ deux minutes. Après une modification, les événements de changement et l'invalidation des caches permettent aux autres écrans de retrouver les données à jour.

## 12. Synchronisation générale des données

### Au démarrage

1. Flutter démarre l'interface.
2. La session est restaurée depuis le stockage local sécurisé.
3. Le backend est réveillé de manière asynchrone si nécessaire.
4. La météo peut être préchargée en arrière-plan.
5. Les écrans chargent leurs données lorsqu'ils sont utilisés.

### Lors d'une lecture

```text
Écran
  -> DataRepository ou ApiService
  -> Vérification du cache
  -> Si cache valide : données locales
  -> Sinon : requête backend
  -> Réponse JSON
  -> Mise à jour de l'écran et du cache
```

### Lors d'une modification

```text
Création ou modification
  -> Requête POST, PUT ou DELETE
  -> Backend valide et enregistre
  -> Frontend invalide le cache concerné
  -> Événement de changement
  -> Les écrans concernés rechargent leurs données
```

### Durées de cache principales

| Domaine | Durée indicative | Raisonnement |
|---|---:|---|
| Fermes, cultures, élevage | 2 minutes | Données relativement stables |
| Marché et prix | 1 minute | Données plus dynamiques |
| Réseau social | environ 30 secondes | Publications fréquentes |
| Statistiques et résumés | jusqu'à 5 minutes | Calculs plus lourds |
| Météo | Cache de session et rechargement manuel | Information externe et évolutive |

Le bouton de rafraîchissement permet toujours de forcer une nouvelle lecture. Le cache ne remplace donc pas la synchronisation : il réduit les requêtes inutiles tout en permettant une mise à jour contrôlée.

## 13. Architecture technique en une phrase

Mbaymi est une application Flutter connectée à un backend FastAPI, avec authentification par jeton, base de données centralisée, services API par domaine, cache frontend à durée limitée, invalidation ciblée et intégration de services externes comme Open-Meteo et Google News RSS.

## 14. Conclusion pour l'entreprise

Mbaymi ne se limite pas à une application de saisie. Elle constitue un espace de gestion et de connexion pour l'activité agricole : les données de terrain sont structurées, les dépenses et intrants sont associés aux cultures, les producteurs peuvent accéder au marché et au réseau, et les informations externes comme la météo et les actualités sont intégrées dans le même parcours.

La valeur principale est la centralisation : l'utilisateur dispose d'une vision plus claire de son exploitation et peut prendre des décisions plus rapidement, avec des données mieux organisées et progressivement traçables.

## Références techniques du projet

- Page d'accueil : `frontend/lib/screens/dashboard_tab.dart`
- Navigation principale : `frontend/lib/screens/home_screen.dart`
- Service météo : `frontend/lib/services/weather_service.dart`
- Service API frontend : `frontend/lib/services/api_service.dart`
- Route actualités backend : `backend/app/routes/news.py`
- Accès centralisé et cache : `frontend/lib/services/data_repository.dart`
- Architecture de cache et pagination : `ARCHITECTURE_CACHE_PAGINATION.md`