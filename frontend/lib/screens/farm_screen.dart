import 'package:flutter/material.dart';
import 'package:mbaymi/widgets/empty_state.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/edit_farm_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';

class FarmTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;

  const FarmTab({Key? key, this.isDarkMode = false, this.userId}) : super(key: key);

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return buildEmptyState(
        icon: Icons.agriculture_outlined,
        title: 'Gestion des fermes',
        description: 'Créez et gérez vos parcelles agricoles',
        buttonLabel: 'Ajouter une ferme',
        color: const Color(0xFF6B8E23),
        isDarkMode: widget.isDarkMode,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateFarmScreen()),
          );
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ferme enregistrée')));
          }
        },
      );
    }
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getUserFarms(widget.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final farms = snapshot.data ?? [];
        if (farms.isEmpty) {
          return buildEmptyState(
            icon: Icons.agriculture_outlined,
            title: 'Aucune ferme',
            description: 'Vous n\'avez pas encore de ferme enregistrée',
            buttonLabel: 'Ajouter une ferme',
            color: const Color(0xFF6B8E23),
            isDarkMode: widget.isDarkMode,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateFarmScreen(userId: widget.userId)),
              );
              if (result != null) setState(() {});
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: farms.length,
          itemBuilder: (context, index) {
            final farm = farms[index] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    leading: (farm['photos'] != null && (farm['photos'] as List).isNotEmpty)
                        ? (() {
                            final first = (farm['photos'] as List).first;
                            final url = first is String ? first : (first['image_url'] ?? first['imageUrl']);
                            if (url == null) {
                              return const CircleAvatar(
                                backgroundColor: Color(0xFF6B8E23),
                                child: Icon(Icons.agriculture, color: Colors.white),
                              );
                            }
                            return CircleAvatar(
                              backgroundImage: NetworkImage(url),
                              backgroundColor: Colors.transparent,
                            );
                          })()
                        : ((farm['image_url'] != null && (farm['image_url'] as String).isNotEmpty) ||
                                (farm['imageUrl'] != null && (farm['imageUrl'] as String).isNotEmpty))
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(farm['image_url'] ?? farm['imageUrl']),
                                backgroundColor: Colors.transparent,
                              )
                            : CircleAvatar(
                                backgroundColor: const Color(0xFF6B8E23),
                                child: const Icon(Icons.agriculture, color: Colors.white),
                              ),
                    title: Text(farm['name'] ?? 'Ferme'),
                    subtitle: Text(farm['location'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParcelScreen(farmId: farm['id'] as int, userId: widget.userId!),
                              ),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditFarmScreen(farm: farm, userId: widget.userId)),
                              );
                              if (result != null && mounted) setState(() {});
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: const Text('Supprimer cette ferme ? Cette action est irréversible.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  await ApiService.deleteFarm(farm['id'] as int);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ferme supprimée')));
                                  setState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Éditer')),
                            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Gallery row
                  if (farm['photos'] != null && (farm['photos'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        height: 64,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: (farm['photos'] as List).map<Widget>((p) {
                            final url = p is String ? p : (p['image_url'] ?? p['imageUrl']);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 96, height: 64, fit: BoxFit.cover)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
