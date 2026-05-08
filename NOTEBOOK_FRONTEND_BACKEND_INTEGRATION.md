# 🔗 Notebook Editor - Frontend Backend Integration

## Architecture Hybride

Le système fonctionne en **mode offline-first**:
- ✅ Données sauvegardées localement (SharedPreferences)
- ✅ Synchronisation automatique avec le backend quand en ligne
- ✅ Fonctionne sans internet
- ✅ Sync quand la connexion revient

```
┌─────────────────────┐
│  Flutter Frontend   │
│  (Tablet/Mobile)    │
└──────────┬──────────┘
           │
      ┌────▼─────┐
      │  Offline  │
      │   Local   │ ◄─── SharedPreferences
      │  Storage  │     (Default: tout local)
      └────┬─────┘
           │
      ┌────▼──────────┐
      │  Connectivity │
      │   Service     │ ◄─── Écoute changements réseau
      └────┬──────────┘
           │
      ┌────▼─────────────────────┐
      │  HybridNotebookProvider   │
      │                           │
      │  • Online? → Sync API     │
      │  • Offline? → Utiliser   │
      │    local storage         │
      └────┬─────────────────────┘
           │
      ┌────▼──────────────┐
      │  NotebookApiService
      │  (HTTP REST)       │
      └────┬──────────────┘
           │ API_URL (from .env)
      ┌────▼──────────────────────────┐
      │   FastAPI Backend              │
      │   (api/notebooks endpoints)    │
      └────┬──────────────────────────┘
           │
      ┌────▼──────────────┐
      │  PostgreSQL        │
      │  Database          │
      └───────────────────┘
```

## ⚡ Setup Rapide

### Frontend (.env)
```bash
API_URL=http://YOUR_BACKEND_URL
```

### main.dart
```dart
import 'services/hybrid_notebook_provider.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider<HybridNotebookProvider>(
      create: (_) {
        final provider = HybridNotebookProvider();
        provider.initialize(prefs, apiUrl);
        return provider;
      },
    ),
  ],
)
```

### Usage
```dart
final provider = Provider.of<HybridNotebookProvider>(context);
await provider.loadNotebooksByFarm(farmId);
```

---

## Services Créés

| Service | Rôle |
|---------|------|
| `notebook_service.dart` | ✅ Logique locale (SharedPreferences) |
| `notebook_api_service.dart` | ✅ Connexion API HTTP |
| `hybrid_notebook_provider.dart` | ✅ Provider offline-first (nouveau!) |
  );

  runApp(
    MultiProvider(
      providers: [
        // ... autres providers ...
        
        ChangeNotifierProvider(
          create: (context) => NotebookApiProvider(
            apiService: notebookApiService,
            localService: notebookService,
          )..initialize(),  // Auto-initialiser
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

## 🎯 Utilisation dans les écrans

### Charger les cahiers

```dart
class ProjectNotebookListScreen extends StatefulWidget {
  @override
  State<ProjectNotebookListScreen> createState() =>
      _ProjectNotebookListScreenState();
}

class _ProjectNotebookListScreenState extends State<ProjectNotebookListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les cahiers au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotebookApiProvider>().loadNotebooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookApiProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${provider.errorMessage}'),
                ElevatedButton(
                  onPressed: () => provider.syncWithServer(),
                  child: const Text('Réessayer'),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.filteredNotebooks.length,
          itemBuilder: (context, index) {
            final notebook = provider.filteredNotebooks[index];
            return NotebookCard(notebook: notebook);
          },
        );
      },
    );
  }
}
```

### Créer un nouveau cahier

```dart
void _showCreateDialog() {
  showDialog(
    context: context,
    builder: (context) {
      String title = '';
      String description = '';

      return AlertDialog(
        title: const Text('Nouveau cahier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Titre'),
              onChanged: (value) => title = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => description = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<NotebookApiProvider>().createNotebook(
                title: title,
                description: description,
                farmId: 1,  // À récupérer depuis le contexte
                category: 'general',
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      );
    },
  );
}
```

### Éditer un cahier

```dart
Future<void> _saveNotebook() async {
  await context.read<NotebookApiProvider>().updateNotebook(
    _editingNotebook,
  );

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cahier sauvegardé')),
    );
  }
}
```

### Ajouter des commentaires

```dart
void _addComment() {
  showDialog(
    context: context,
    builder: (context) {
      String commentText = '';

      return AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Votre commentaire...'),
          onChanged: (value) => commentText = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<NotebookApiProvider>().addComment(
                selectedNotebook!.id,
                commentText,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Commenter'),
          ),
        ],
      );
    },
  );
}
```

### Rechercher des cahiers

```dart
void _search(String query) {
  context.read<NotebookApiProvider>().search(query);
}

// Dans la barre d'appli
SearchBar(
  onChanged: _search,
  hintText: 'Chercher un cahier...',
)
```

### Versioning

```dart
// Créer une version
Future<void> _createVersion() async {
  await context.read<NotebookApiProvider>().createVersion(
    selectedNotebook!.id,
    'Sauvegarde avant modification',
  );
}

// Voir l'historique
Future<void> _showVersionHistory() async {
  final versions = await context.read<NotebookApiProvider>()
    .getVersionHistory(selectedNotebook!.id);

  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Historique'),
      content: ListView.builder(
        itemCount: versions.length,
        itemBuilder: (context, index) {
          final version = versions[index];
          return ListTile(
            title: Text(version.changeDescription),
            subtitle: Text(version.createdAt.toString()),
            trailing: ElevatedButton(
              onPressed: () async {
                await context.read<NotebookApiProvider>()
                  .restoreVersion(
                    selectedNotebook!.id,
                    version.id,
                  );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Restaurer'),
            ),
          );
        },
      ),
    ),
  );
}
```

## 🌐 Configuration du Backend

### Configuration minimale

L'URL du backend doit être définie lors de la création du `NotebookApiService` :

```dart
// Pour développement local
const baseUrl = 'http://localhost:8000';

// Pour Flutter Web (CORS à activer)
const baseUrl = 'http://votre-domaine.com';

// Pour Flutter Mobile avec emulateur Android
const baseUrl = 'http://10.0.2.2:8000';
```

### Configuration CORS (fastapi)

Si vous avez une erreur CORS, assurez-vous que le backend accepte les requêtes :

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🔒 Authentification

L'API service utilise le token stocké dans SharedPreferences :

```dart
// Lors de la connexion
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', jwtToken);

// L'initialisation du service le récupère automatiquement
await notebookApiService.initialize();
```

## 📊 Modes de synchronisation

### Mode en ligne
- Toutes les requêtes vont au serveur
- Les données locales sont mises à jour
- Affiche les erreurs en cas de problème

### Mode hors ligne
Le provider détecte automatiquement si l'API est indisponible et :
- Utilise les données locales
- Affiche un message "Mode hors ligne"
- Permet une synchronisation ultérieure via `syncWithServer()`

## 🔄 Synchronisation manuelle

```dart
// Synchroniser avec le serveur
await context.read<NotebookApiProvider>().syncWithServer();

// Charger les cahiers d'une ferme
await context.read<NotebookApiProvider>().loadNotebooksByFarm(farmId);

// Filtrer par catégorie
context.read<NotebookApiProvider>().setCategory('plants');

// Filtrer par ferme
context.read<NotebookApiProvider>().setFarm(1);
```

## 🐛 Débogage

Activez le logging HTTP :

```dart
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client inner;

  LoggingHttpClient(this.inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('${request.method} ${request.url}');
    final response = await inner.send(request);
    print('Status: ${response.statusCode}');
    return response;
  }
}
```

Utilisez-le ainsi :

```dart
final notebookApiService = NotebookApiService(
  baseUrl: baseUrl,
)..httpClient = LoggingHttpClient(http.Client());
```

## ⚠️ Points importants

1. **Token d'authentification** - Doit être défini avant d'utiliser le service
2. **URL du backend** - À adapter à votre environnement
3. **Mode hors ligne** - Fonctionne automatiquement si l'API est indisponible
4. **Erreurs réseau** - Affichées à l'utilisateur, non lancées en exception
5. **Performance** - Charge les cahiers une seule fois au démarrage par défaut

## 🚀 Prochaines étapes

1. Exécuter les migrations de base de données
   ```bash
   alembic upgrade head
   ```

2. Tester les endpoints avec Postman
3. Ajouter des tests unitaires
4. Déployer le backend
5. Configurer les URLs de production

## 📚 Références

- [NotebookApiService](lib/services/notebook_api_service.dart) - Couche HTTP
- [NotebookApiProvider](lib/services/notebook_api_provider.dart) - Gestion d'état
- [NotebookService](lib/services/notebook_service.dart) - Stockage local
- [Backend Routes](backend/app/routes/notebooks.py) - API complète
