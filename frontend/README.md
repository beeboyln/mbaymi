# 📱 Mbaymi Flutter Frontend

Application Flutter pour la plateforme Mbaymi d'agriculture et d'élevage.

## 🚀 Setup

### 1. Prérequis

- Flutter SDK >= 3.0
- Android Studio / Xcode
- Emulator ou device

### 2. Installation

```bash
flutter pub get
```

### 3. Configuration API

Mettre à jour le `baseUrl` dans `lib/services/api_service.dart` :

```dart
static const String baseUrl = 'http://your-api-url:8000/api';
```

Pour émulateur Android :
```
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

### 4. Lancer l'app

```bash
flutter run
```

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── models/                      # Modèles de données
│   ├── user_model.dart
│   ├── farm_model.dart
│   ├── livestock_model.dart
│   └── market_model.dart
├── screens/                     # Écrans
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── home_screen.dart
├── services/                    # Services API
│   └── api_service.dart
└── widgets/                     # Composants réutilisables
    └── dashboard_card.dart
```

## 🎨 Screens

- **LoginScreen** : Connexion utilisateur
- **RegisterScreen** : Inscription (agriculteur, éleveur, acheteur, vendeur)
- **HomeScreen** : Tableau de bord avec onglets
  - Dashboard : Vue d'ensemble
  - Fermes : Gestion des cultures
  - Élevage : Gestion du bétail
  - Marché : Prix et demandes
  - Conseils : Conseils agricoles/élevage

## 🔗 Intégration Backend

L'app communique avec FastAPI via REST API :

```dart
// Exemple: Obtenir un conseil
final advice = await ApiService.getAdvice(
  type: 'crop',
  topic: 'maïs',
  region: 'Dakar',
);
```

## 📝 Fonctionnalités MVP

- [x] Authentification (login/register)
- [x] Gestion des utilisateurs
- [x] Gestion des fermes et cultures
- [x] Gestion du bétail
- [x] Consultations des prix du marché
- [x] Conseils automatiques
- [ ] Chat entre utilisateurs
- [ ] Notifications
- [ ] Téléchargement de photos
- [ ] Synchronisation offline

## 🚀 Prochaines étapes

1. Implémenter la gestion d'état (Provider)
2. Ajouter la persistance locale (Hive/SQLite)
3. Intégrer les notifications Push
4. Ajouter la géolocalisation
5. Fonctionnalités multi-langue
