# 🚀 Notebook Editor - Quick Reference

## Installation & Setup (5 minutes)

### 1. **Dépendances** ✅ (Already added to pubspec.yaml)
```yaml
dependencies:
  flutter_quill: ^9.4.0
  pdf: ^3.10.0
  printing: ^5.11.0
  uuid: ^4.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

### 2. **Ajouter Provider dans main.dart**
```dart
import 'package:provider/provider.dart';
import 'services/notebook_provider.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider<NotebookProvider>(
      create: (_) {
        final provider = NotebookProvider();
        provider.initialize(prefs);
        return provider;
      },
    ),
  ],
  child: MyApp(),
)
```

### 3. **Ajouter widget au Dashboard**
```dart
// Dans votre dashboard ou home screen
NotebookDashboardWidget(
  farmId: farmId,
  userId: userId,
)
```

---

## API Rapide

### Create Notebook
```dart
final notebook = await provider.createNotebook(
  title: 'Mon cahier',
  description: 'Description',
  farmId: 'farm-id',
  userId: 'user-id',
  category: 'culture', // or 'elevage', 'finance', etc.
  tags: ['tag1', 'tag2'],
);
```

### Load Notebooks
```dart
// Charger tous les cahiers d'une ferme
await provider.loadNotebooksByFarm(farmId);

// Accéder aux cahiers
List<ProjectNotebook> notebooks = provider.notebooks;
```

### Add Content
```dart
// Ajouter une section
await provider.addSection(notebookId, 'Section Title');

// Ajouter un commentaire
await provider.addComment(
  notebookId,
  userId,
  'Jean Dupont',
  'Commentaire texte',
);
```

### Share
```dart
// Partager avec utilisateurs
await provider.shareWith(notebookId, ['user1', 'user2']);

// Rendre public
await provider.setPublic(notebookId, true);
```

### Export
```dart
// PDF
NotebookPdfExportService.exportToPdf(notebook);

// JSON
String json = notebookService.generateJson(notebook);

// Plain Text
String text = notebookService.generatePlainText(notebook);
```

### Versioning
```dart
// Créer une snapshot
await provider.createVersion(
  notebookId,
  userId,
  'Changements: ajout plan d\'irrigation',
);

// Lire l'historique
List<NoteVersion> versions = 
  await provider.getVersionHistory(notebookId);
```

### Search & Filter
```dart
// Recherche textuelle
await provider.search('maïs');

// Filtrer par catégorie
provider.filterByCategory('culture');

// Filtrer par tags
await provider.filterByTags(['maïs', '2024']);
```

---

## UI Components

### ProjectNotebookListScreen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProjectNotebookListScreen(
      farmId: farmId,
      userId: userId,
    ),
  ),
);
```

### NotebookDashboardWidget
```dart
NotebookDashboardWidget(
  farmId: farmId,
  userId: userId,
)
```

### Quick Action Card
```dart
NotebookQuickAction(
  farmId: farmId,
  userId: userId,
)
```

---

## Data Models

### ProjectNotebook
| Field | Type | Exemple |
|-------|------|---------|
| id | String | UUID |
| title | String | "Planification maïs" |
| description | String | "Plan 2024" |
| farmId | String | Farm ID |
| createdBy | String | User ID |
| category | String | "culture" |
| tags | List<String> | ["maïs", "2024"] |
| sections | List<NotebookSection> | [...] |
| comments | List<NoteComment> | [...] |
| versions | List<NoteVersion> | [...] |
| sharedWith | List<String> | [user-ids] |
| isPublic | bool | false |

### NotebookSection
| Field | Type |
|-------|------|
| id | String |
| title | String |
| contents | List<NoteContent> |
| order | int |

### NoteContent
| Field | Type | Values |
|-------|------|--------|
| id | String | UUID |
| type | String | text, heading, list, quote, code |
| content | String | Contenu |
| metadata | Map | Styles |

---

## Categories & Tags

### Available Categories
```dart
- 'general'     // Par défaut
- 'culture'     // Cultures agricoles
- 'elevage'     // Élevage d'animaux
- 'finance'     // Gestion financière
- 'maintenance' // Entretien et maintenance
```

### Example Tags
```dart
// Cultures
['maïs', 'blé', 'soja', 'tomates', 'pommes']

// Élevage
['vaches', 'poulets', 'chèvres', 'laitier', 'viande']

// Saisons
['printemps', 'été', 'automne', 'hiver']

// Années
['2023', '2024', '2025']

// Status
['planifié', 'en-cours', 'récolte', 'terminé']
```

---

## Content Types

```dart
NoteContent(
  type: 'text',
  content: 'Paragraphe normal',
)

NoteContent(
  type: 'heading',
  content: 'Grand titre',
)

NoteContent(
  type: 'list',
  content: 'Item 1\nItem 2\nItem 3',
)

NoteContent(
  type: 'quote',
  content: 'Citation importante',
)

NoteContent(
  type: 'code',
  content: 'SELECT * FROM crops;',
)

NoteContent(
  type: 'checklist',
  content: '☐ Tâche 1\n☐ Tâche 2\n☐ Tâche 3',
)
```

---

## Error Handling

```dart
try {
  await provider.createNotebook(...);
} catch (e) {
  print('Error: ${provider.errorMessage}');
  // Afficher un SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

## Storage & Persistence

**Local**: SharedPreferences (JSON encoding)
**Cloud**: Ready for Firebase/Supabase integration

### Sauvegarde locale
```dart
// Automatique lors de chaque modification
await notebookService.saveNotebook(notebook);

// Ou via le provider
await provider.saveNotebook(notebook);
```

---

## Performance Tips

✅ **Cache les cahiers** au premier chargement  
✅ **Utilisez les filtres** plutôt que de charger tout  
✅ **Paginez** si >100 cahiers  
✅ **Compressez** les images avant export PDF  
✅ **Nettoyez** les versions anciennes régulièrement  

---

## Troubleshooting

| Problème | Solution |
|----------|----------|
| NotebookProvider null | Ajouter à MultiProvider dans main.dart |
| Cahiers vides | Vérifier SharedPreferences |
| PDF blank | Vérifier que les sections ont du contenu |
| Slow search | Limit à 1000 cahiers max |
| Tags perdus | Appeler saveNotebook() après modification |

---

## Next Steps

- [ ] Implémenter Firebase sync
- [ ] Ajouter rich text editor (Flutter Quill)
- [ ] Support images & galeries
- [ ] Notifications collaboratives
- [ ] Templates prédéfinis
- [ ] API REST pour mobile

---

**Questions?** Voir `NOTEBOOK_EDITOR_GUIDE.md` pour docs complètes
