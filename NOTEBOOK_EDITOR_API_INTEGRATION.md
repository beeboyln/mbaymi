# 🔗 Notebook Editor - API Integration Guide

## Backend Integration (Optional)

Si vous avez un backend API, voici comment intégrer le notebook editor:

### API Endpoints Recommandés

```
POST   /api/notebooks                 - Créer un cahier
GET    /api/notebooks                 - Lister tous les cahiers
GET    /api/notebooks/:id             - Récupérer un cahier
PUT    /api/notebooks/:id             - Mettre à jour un cahier
DELETE /api/notebooks/:id             - Supprimer un cahier

GET    /api/notebooks/farm/:farmId    - Cahiers par ferme
GET    /api/notebooks/user/:userId    - Cahiers par utilisateur
GET    /api/notebooks/search          - Rechercher

POST   /api/notebooks/:id/sections    - Ajouter une section
PUT    /api/notebooks/:id/sections/:sectionId - Mettre à jour section
DELETE /api/notebooks/:id/sections/:sectionId - Supprimer section

POST   /api/notebooks/:id/comments    - Ajouter commentaire
DELETE /api/notebooks/:id/comments/:commentId - Supprimer commentaire

POST   /api/notebooks/:id/share       - Partager
DELETE /api/notebooks/:id/share/:userId - Arrêter le partage
PUT    /api/notebooks/:id/public      - Rendre public/privé

POST   /api/notebooks/:id/versions    - Créer une version
GET    /api/notebooks/:id/versions    - Lister les versions
PUT    /api/notebooks/:id/versions/:versionId/restore - Restaurer
```

---

## Service API Enhanced

Créer `lib/services/notebook_api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/project_notebook_model.dart';

class NotebookApiService {
  final String baseUrl;
  final String token;

  NotebookApiService({
    required this.baseUrl,
    required this.token,
  });

  Future<ProjectNotebook> createNotebook(ProjectNotebook notebook) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notebooks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(notebook.toJson()),
    );

    if (response.statusCode == 201) {
      return ProjectNotebook.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create notebook: ${response.body}');
    }
  }

  Future<List<ProjectNotebook>> getNotebooksByFarm(String farmId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notebooks/farm/$farmId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ProjectNotebook.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load notebooks');
    }
  }

  Future<void> updateNotebook(ProjectNotebook notebook) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notebooks/${notebook.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(notebook.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update notebook');
    }
  }

  Future<void> deleteNotebook(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notebooks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete notebook');
    }
  }

  // ... autres méthodes
}
```

---

## Database Schema (PostgreSQL Example)

```sql
-- Table principale des cahiers
CREATE TABLE notebooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id),
  category VARCHAR(50) DEFAULT 'general',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Sections
CREATE TABLE notebook_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id) ON DELETE CASCADE,
  title VARCHAR(255),
  "order" INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Contenu
CREATE TABLE note_contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID REFERENCES notebook_sections(id) ON DELETE CASCADE,
  type VARCHAR(50),
  content TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Commentaires
CREATE TABLE note_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  text TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Partage
CREATE TABLE notebook_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(notebook_id, user_id)
);

-- Tags
CREATE TABLE notebook_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id) ON DELETE CASCADE,
  tag VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(notebook_id, tag)
);

-- Versions
CREATE TABLE note_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id) ON DELETE CASCADE,
  title VARCHAR(255),
  change_description TEXT,
  created_by UUID REFERENCES users(id),
  sections_snapshot JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notebooks_farm_id ON notebooks(farm_id);
CREATE INDEX idx_notebooks_created_by ON notebooks(created_by);
CREATE INDEX idx_notebook_sections_notebook_id ON notebook_sections(notebook_id);
CREATE INDEX idx_note_comments_notebook_id ON note_comments(notebook_id);
CREATE INDEX idx_notebook_shares_notebook_id ON notebook_shares(notebook_id);
CREATE INDEX idx_note_versions_notebook_id ON note_versions(notebook_id);
```

---

## Synchronization Strategy

### Offline-First Pattern

```dart
// Service hybride: Local + API
class HybridNotebookService {
  final NotebookService localService;
  final NotebookApiService apiService;

  Future<void> saveNotebook(ProjectNotebook notebook) async {
    // Toujours sauvegarder localement d'abord
    await localService.saveNotebook(notebook);

    // Puis synchroniser avec l'API
    try {
      await apiService.updateNotebook(notebook);
    } catch (e) {
      // Marquer comme "pending sync"
      // Réessayer plus tard
    }
  }

  // Sync périodique
  Future<void> syncAll() async {
    final local = await localService.getAllNotebooks();
    
    for (final notebook in local) {
      try {
        await apiService.updateNotebook(notebook);
      } catch (e) {
        // Gérer les erreurs
      }
    }
  }
}
```

---

## Real-time Collaboration (WebSocket)

```dart
// Pour les mises à jour en temps réel
class NotebookWebSocketService {
  final String wsUrl;
  WebSocket? _ws;

  Future<void> connect(String notebookId) async {
    _ws = await WebSocket.connect(
      '$wsUrl/notebooks/$notebookId',
    );

    _ws?.listen((event) {
      final update = NotebookUpdate.fromJson(jsonDecode(event));
      _handleUpdate(update);
    });
  }

  void _handleUpdate(NotebookUpdate update) {
    // Mettre à jour l'UI en temps réel
    // Merger les changements
  }

  Future<void> sendUpdate(NotebookUpdate update) async {
    _ws?.add(jsonEncode(update.toJson()));
  }
}
```

---

## Authentication & Authorization

```dart
// Vérifier les permissions
bool canEditNotebook(ProjectNotebook notebook, String userId) {
  return notebook.createdBy == userId || 
         notebook.sharedWith.contains(userId);
}

bool canShareNotebook(ProjectNotebook notebook, String userId) {
  return notebook.createdBy == userId;
}

bool canViewNotebook(ProjectNotebook notebook, String userId) {
  return notebook.createdBy == userId ||
         notebook.sharedWith.contains(userId) ||
         notebook.isPublic;
}
```

---

## Audit & Activity Log

```sql
CREATE TABLE notebook_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id UUID REFERENCES notebooks(id),
  user_id UUID REFERENCES users(id),
  action VARCHAR(50),  -- 'created', 'edited', 'commented', 'shared'
  description TEXT,
  changes JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Index for filtering
CREATE INDEX idx_notebook_activities_notebook_id 
  ON notebook_activities(notebook_id, created_at DESC);
```

---

## Migration Path

Si vous avez des données existantes à importer:

```dart
// Importer depuis format CSV/JSON
Future<void> importNotebooksFromJson(List<Map<String, dynamic>> data) async {
  for (final item in data) {
    final notebook = ProjectNotebook.fromJson(item);
    await notebookService.saveNotebook(notebook);
  }
}

// Exporter tout en backup
Future<void> backupAllNotebooks() async {
  final notebooks = await notebookService.getAllNotebooks();
  final json = jsonEncode(
    notebooks.map((n) => n.toJson()).toList(),
  );
  // Sauvegarder en fichier
}
```

---

## Security Considerations

- ✅ Valider tous les inputs côté serveur
- ✅ Implémenter row-level security (RLS) en PostgreSQL
- ✅ Rate limiting sur les endpoints API
- ✅ Chiffrer les données sensibles
- ✅ Auditer tous les accès
- ✅ CORS configuration
- ✅ SQL injection prevention (prepared statements)

---

## Performance Optimization

- Cache local avec SharedPreferences
- Lazy loading des sections
- Pagination des commentaires
- Compression des fichiers PDF
- CDN pour images
- Database query optimization

---

## Testing

```dart
// Unit tests
test('Create notebook', () async {
  final notebook = await service.createNotebook(...);
  expect(notebook.id, isNotNull);
});

// Integration tests
testWidgets('Load and display notebooks', (tester) async {
  // Test l'écran complet
});
```

---

## Deployment Checklist

- [ ] API endpoints testés
- [ ] Database migrations exécutées
- [ ] Auth tokens générés
- [ ] Error handling implémenté
- [ ] Logging activé
- [ ] Backup en place
- [ ] Rate limiting configuré
- [ ] Tests passés 100%

---

**Pour questions sur l'intégration:** Consulter l'équipe backend
