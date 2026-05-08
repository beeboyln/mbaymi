# 🖼️ Guide d'intégration des écrans

Comment mettre à jour les écrans Flutter pour utiliser le `NotebookApiProvider`

---

## 1. Configuration du main.dart

**Avant:**
```dart
void main() {
  runApp(const MyApp());
}
```

**Après:**
```dart
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'lib/services/notebook_api_service.dart';
import 'lib/services/notebook_api_provider.dart';
import 'lib/services/notebook_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les services de cahier
  final notebookService = NotebookService();
  final notebookApiService = NotebookApiService(
    baseUrl: 'http://localhost:8000', // Adapter à votre environnement
  );

  runApp(
    MultiProvider(
      providers: [
        // ... autres providers...
        
        ChangeNotifierProvider(
          create: (context) => NotebookApiProvider(
            apiService: notebookApiService,
            localService: notebookService,
          )..initialize(), // Auto-initialiser les cahiers
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 2. Mettre à jour project_notebook_list_screen.dart

**Avant:**
```dart
class ProjectNotebookListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cahiers')),
      body: const Center(child: Text('Cahiers ici')),
    );
  }
}
```

**Après:**
```dart
import 'package:provider/provider.dart';
import '../services/notebook_api_provider.dart';

class ProjectNotebookListScreen extends StatefulWidget {
  const ProjectNotebookListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectNotebookListScreen> createState() =>
      _ProjectNotebookListScreenState();
}

class _ProjectNotebookListScreenState extends State<ProjectNotebookListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Charger les cahiers au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotebookApiProvider>().loadNotebooks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cahiers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotebookApiProvider>().syncWithServer();
            },
          ),
        ],
      ),
      body: Consumer<NotebookApiProvider>(
        builder: (context, provider, _) {
          // État de chargement
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Message d'erreur
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.syncWithServer(),
                    child: const Text('Synchroniser'),
                  ),
                ],
              ),
            );
          }

          final notebooks = provider.filteredNotebooks;

          // Liste vide
          if (notebooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cahier',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showCreateNotebookDialog(context),
                    child: const Text('Créer un cahier'),
                  ),
                ],
              ),
            );
          }

          // Liste des cahiers
          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Chercher un cahier...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (query) {
                    setState(() => _searchQuery = query);
                    if (query.isNotEmpty) {
                      context.read<NotebookApiProvider>().search(query);
                    } else {
                      context.read<NotebookApiProvider>().loadNotebooks();
                    }
                  },
                ),
              ),
              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = notebooks[index];
                    return NotebookCard(
                      notebook: notebook,
                      onTap: () {
                        context.read<NotebookApiProvider>()
                            .getNotebook(notebook.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotebookEditorScreen(notebook: notebook),
                          ),
                        );
                      },
                      onDelete: () => _deleteNotebook(context, notebook.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateNotebookDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateNotebookDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => _CreateNotebookDialog(
        onCreate: (title, description) async {
          await context.read<NotebookApiProvider>().createNotebook(
            title: title,
            description: description,
            farmId: 1, // À récupérer du contexte utilisateur
            category: 'general',
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteNotebook(BuildContext context, int id) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cahier?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotebookApiProvider>().deleteNotebook(id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Widget de dialogue de création
class _CreateNotebookDialog extends StatefulWidget {
  final Function(String, String) onCreate;

  const _CreateNotebookDialog({required this.onCreate});

  @override
  State<_CreateNotebookDialog> createState() => _CreateNotebookDialogState();
}

class _CreateNotebookDialogState extends State<_CreateNotebookDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau cahier'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Cahier de culture 2024',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Description du cahier',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onCreate(
                _titleController.text,
                _descriptionController.text,
              );
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
```

---

## 3. Mettre à jour notebook_editor_screen.dart

**Highlight des modifications clés:**

```dart
class NotebookEditorScreen extends StatefulWidget {
  final ProjectNotebook notebook;

  const NotebookEditorScreen({
    Key? key,
    required this.notebook,
  }) : super(key: key);

  @override
  State<NotebookEditorScreen> createState() => _NotebookEditorScreenState();
}

class _NotebookEditorScreenState extends State<NotebookEditorScreen> {
  late ProjectNotebook _editingNotebook;

  @override
  void initState() {
    super.initState();
    _editingNotebook = widget.notebook;
  }

  Future<void> _saveNotebook() async {
    try {
      // Sauvegarder via l'API
      await context.read<NotebookApiProvider>().updateNotebook(
        _editingNotebook,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cahier sauvegardé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _createVersion() async {
    await context.read<NotebookApiProvider>().createVersion(
      _editingNotebook.id,
      'Enregistrement à ${DateTime.now()}',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version créée')),
      );
    }
  }

  Future<void> _addComment(String text) async {
    await context.read<NotebookApiProvider>().addComment(
      _editingNotebook.id,
      text,
    );
    
    if (mounted) {
      // Les commentaires se mettent à jour automatiquement via Provider
      setState(() {
        _editingNotebook = context.read<NotebookApiProvider>().selectedNotebook!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingNotebook.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNotebook,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showVersionHistory,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Contenu'),
                Tab(text: 'Commentaires'),
                Tab(text: 'Versions'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Onglet Contenu
                  _buildContentTab(),
                  
                  // Onglet Commentaires
                  _buildCommentsTab(),
                  
                  // Onglet Versions
                  _buildVersionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: TextEditingController(text: _editingNotebook.title),
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Titre du cahier',
            ),
            onChanged: (value) {
              _editingNotebook = _editingNotebook.copy(title: value);
            },
          ),
          const SizedBox(height: 24),
          // Widget QuillController ou éditeur de texte riche
          Text(_editingNotebook.description),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Consumer<NotebookApiProvider>(
      builder: (context, provider, _) {
        final comments = provider.selectedNotebook?.comments ?? [];
        
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentCard(
                    comment: comment,
                    onDelete: () {
                      context.read<NotebookApiProvider>().deleteComment(
                        _editingNotebook.id,
                        comment.id,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: _addComment,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVersionsTab() {
    return FutureBuilder<List<NoteVersion>>(
      future: context.read<NotebookApiProvider>()
          .getVersionHistory(_editingNotebook.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune version'));
        }

        final versions = snapshot.data!;
        return ListView.builder(
          itemCount: versions.length,
          itemBuilder: (context, index) {
            final version = versions[index];
            return ListTile(
              title: Text('Version ${version.id}: ${version.changeDescription}'),
              subtitle: Text(version.createdAt.toString()),
              trailing: ElevatedButton(
                onPressed: () async {
                  await context.read<NotebookApiProvider>()
                      .restoreVersion(_editingNotebook.id, version.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Version restaurée')),
                    );
                  }
                },
                child: const Text('Restaurer'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showShareDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager le cahier'),
        content: const Text('Partager avec d\'autres utilisateurs'),
        // Implémenter la logique de partage
      ),
    );
  }

  Future<void> _showVersionHistory() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des versions'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildVersionsTab(),
        ),
      ),
    );
  }
}
```

---

## 4. Exemple NotebookCard complet

```dart
class NotebookCard extends StatelessWidget {
  final ProjectNotebook notebook;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotebookCard({
    Key? key,
    required this.notebook,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notebook.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notebook.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Supprimer'),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(notebook.category)),
                  if (notebook.tags.isNotEmpty)
                    ...notebook.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  if (notebook.isPublic)
                    const Chip(
                      label: Text('Public'),
                      backgroundColor: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notebook.sections.length} sections',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${notebook.comments.length} commentaires',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 5. Checklist d'intégration

- [ ] Ajouter `http` package dans pubspec.yaml
- [ ] Créer NotebookApiService
- [ ] Créer NotebookApiProvider
- [ ] Mettre à jour main.dart avec MultiProvider
- [ ] Mettre à jour project_notebook_list_screen.dart
- [ ] Mettre à jour notebook_editor_screen.dart
- [ ] Tester la création de cahier
- [ ] Tester la synchronisation
- [ ] Tester en mode offline
- [ ] Déployer

---

**Statut:** ✅ Prêt pour l'intégration
