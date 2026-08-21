import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_notebook_model.dart';
import '../services/notebook_provider.dart';
import 'package:mbaymi/screens/notebook/project_notebook_list_screen.dart';

/// Widget de présentation rapide des cahiers sur le dashboard
/// À ajouter dans dashboard_tab.dart ou home_screen.dart
class NotebookDashboardWidget extends StatefulWidget {
  final String farmId;
  final String userId;

  const NotebookDashboardWidget({
    required this.farmId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<NotebookDashboardWidget> createState() =>
      _NotebookDashboardWidgetState();
}

class _NotebookDashboardWidgetState extends State<NotebookDashboardWidget> {
  @override
  void initState() {
    super.initState();
    // Charger les cahiers au premier chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotebookProvider>(context, listen: false)
          .loadNotebooksByFarm(widget.farmId)
          .catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cahiers de Projet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectNotebookListScreen(
                            farmId: widget.farmId,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Voir tout'),
                  ),
                ],
              ),
            ),

            // Contenu
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (provider.notebooks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green[50],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun cahier créé',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez un cahier pour planifier vos projets agricoles',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectNotebookListScreen(
                                farmId: widget.farmId,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                        ),
                        child: const Text('Créer un cahier'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: provider.notebooks.take(5).length,
                  itemBuilder: (context, index) {
                    final notebook = provider.notebooks[index];
                    return _buildNotebookCard(context, notebook);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotebookCard(BuildContext context, ProjectNotebook notebook) {
    return GestureDetector(
      onTap: () {
        Provider.of<NotebookProvider>(context, listen: false)
            .selectNotebook(notebook.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[50]!,
                Colors.green[100]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône et catégorie
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notebook.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Titre et description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notebook.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notebook.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              // Statistiques
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${notebook.sections.length} sections',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
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

// ========== EXEMPLE D'UTILISATION DANS LE DASHBOARD ==========
/*
// Dans dashboard_tab.dart ou home_screen.dart
SingleChildScrollView(
  child: Column(
    children: [
      // ... autres widgets du dashboard ...
      
      NotebookDashboardWidget(
        farmId: currentFarm.id,
        userId: currentUser.id,
      ),
      
      // ... autres widgets ...
    ],
  ),
)
*/

// ========== WIDGET DE CARTE RAPIDE POUR ACTIONS RAPIDES ==========
class NotebookQuickAction extends StatelessWidget {
  final String farmId;
  final String userId;

  const NotebookQuickAction({
    required this.farmId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectNotebookListScreen(
              farmId: farmId,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_note,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cahiers de Projet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Planifiez vos projets',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========== SHORTCUT POUR HOME SCREEN QUICK ACTIONS ==========
// À ajouter à HOME_SCREEN_QUICK_ACTIONS.md
/*
## 9. Cahiers de Projet
{
  "id": "notebooks",
  "title": "Cahiers de Projet",
  "icon": "description",
  "color": "green",
  "navigation": ProjectNotebookListScreen(farmId, userId),
}
*/
