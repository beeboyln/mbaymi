# 📡 API Cahier Référence complète

**Prefix:** `/api/notebooks`  
**Authentication:** JWT Token (Bearer)  
**Base URL:** `http://localhost:8000`

---

## 📋 Table des matières

- [CRUD](#crud-operations)
- [Commentaires](#commentaires)
- [Partage](#partage)
- [Versioning](#versioning)
- [Recherche](#recherche)
- [Erreurs](#codes-derreur)

---

## CRUD Operations

### POST /api/notebooks
**Créer un nouveau cahier**

```
POST /api/notebooks
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Mon cahier",
  "description": "Description complète",
  "farm_id": 1,
  "category": "crops",
  "tags": ["bio", "été"],
  "is_public": false
}
```

**Réponse (201 Created):**
```json
{
  "id": 1,
  "title": "Mon cahier",
  "description": "Description complète",
  "farm_id": 1,
  "created_by": 2,
  "category": "crops",
  "tags": ["bio", "été"],
  "is_public": false,
  "sections": [],
  "comments": [],
  "shares": [],
  "versions": [],
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:30:00"
}
```

---

### GET /api/notebooks
**Récupérer tous les cahiers (avec filtres)**

```
GET /api/notebooks?farm_id=1&category=crops&is_public=false
Authorization: Bearer {token}
```

**Query Parameters:**
| Paramètre | Type | Description |
|-----------|------|-------------|
| `farm_id` | int | Filtrer par ferme |
| `category` | string | Filtrer par catégorie |
| `is_public` | boolean | Filtrer publics/privés |

**Réponse (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Cahier 1",
    "description": "...",
    "farm_id": 1,
    "created_by": 2,
    "category": "crops",
    "tags": [],
    "is_public": false,
    "created_at": "2024-01-15T10:30:00",
    "updated_at": "2024-01-15T10:30:00",
    "sections": [],
    "comments": [],
    "versions": []
  },
  ...
]
```

---

### GET /api/notebooks/farm/{farm_id}
**Récupérer les cahiers d'une ferme**

```
GET /api/notebooks/farm/1
Authorization: Bearer {token}
```

**Réponse (200 OK):**
```json
[
  { /* cahier objects */ },
  ...
]
```

---

### GET /api/notebooks/{notebook_id}
**Récupérer un cahier spécifique**

```
GET /api/notebooks/1
Authorization: Bearer {token}
```

**Réponse (200 OK):**
```json
{
  "id": 1,
  "title": "Mon cahier",
  "description": "...",
  "farm_id": 1,
  "created_by": 2,
  "category": "crops",
  "tags": ["bio"],
  "is_public": false,
  "sections": [
    {
      "id": 1,
      "title": "Introduction",
      "order": 1,
      "contents": [
        {
          "type": "text",
          "content": "Contenu...",
          "metadata": {}
        }
      ]
    }
  ],
  "comments": [
    {
      "id": 1,
      "user_id": 3,
      "user_name": "John",
      "text": "Commentaire...",
      "created_at": "2024-01-15T11:00:00"
    }
  ],
  "shared_with": [{"user_id": 3, "username": "john"}],
  "versions": [
    {
      "id": 1,
      "version_number": 1,
      "change_description": "Création",
      "created_by": 2,
      "created_at": "2024-01-15T10:30:00"
    }
  ],
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:30:00"
}
```

---

### PUT /api/notebooks/{notebook_id}
**Mettre à jour un cahier**

```
PUT /api/notebooks/1
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Titre modifié",
  "description": "Nouvelle description",
  "category": "plants",
  "tags": ["nouveau"],
  "sections": [
    {
      "title": "Section 1",
      "order": 1,
      "contents": [
        {"type": "text", "content": "..."}
      ]
    }
  ],
  "is_public": true
}
```

**Réponse (200 OK):** Objet cahier mis à jour

**Erreurs:**
- `403 Forbidden` - Seulement le créateur peut modifier
- `404 Not Found` - Cahier introuvable

---

### DELETE /api/notebooks/{notebook_id}
**Supprimer un cahier**

```
DELETE /api/notebooks/1
Authorization: Bearer {token}
```

**Réponse (204 No Content)** - Cahier supprimé

**Erreurs:**
- `403 Forbidden` - Seulement le créateur peut supprimer
- `404 Not Found` - Cahier introuvable

---

## Commentaires

### POST /api/notebooks/{notebook_id}/comments
**Ajouter un commentaire**

```
POST /api/notebooks/1/comments
Authorization: Bearer {token}
Content-Type: application/json

{
  "text": "Mon commentaire"
}
```

**Réponse (201 Created):**
```json
{
  "id": 5,
  "user_id": 2,
  "user_name": "Marie",
  "text": "Mon commentaire",
  "created_at": "2024-01-15T11:45:00"
}
```

---

### DELETE /api/notebooks/{notebook_id}/comments/{comment_id}
**Supprimer un commentaire**

```
DELETE /api/notebooks/1/comments/5
Authorization: Bearer {token}
```

**Réponse (204 No Content)**

**Erreurs:**
- `403 Forbidden` - Seulement auteur ou créateur du cahier
- `404 Not Found` - Commentaire introuvable

---

## Partage

### POST /api/notebooks/{notebook_id}/share
**Partager avec des utilisateurs**

```
POST /api/notebooks/1/share
Authorization: Bearer {token}
Content-Type: application/json

{
  "user_ids": [3, 4, 5]
}
```

**Réponse (200 OK):**
```json
{
  "message": "Cahier partagé avec 3 utilisateurs"
}
```

---

### DELETE /api/notebooks/{notebook_id}/share/{user_id}
**Arrêter le partage**

```
DELETE /api/notebooks/1/share/3
Authorization: Bearer {token}
```

**Réponse (204 No Content)**

**Erreurs:**
- `403 Forbidden` - Seulement le créateur peut gérer le partage

---

## Versioning

### POST /api/notebooks/{notebook_id}/versions
**Créer une version**

```
POST /api/notebooks/1/versions
Authorization: Bearer {token}
Content-Type: application/json

{
  "change_description": "Ajout des photos"
}
```

**Réponse (201 Created):**
```json
{
  "id": 2,
  "notebook_id": 1,
  "version_number": 2,
  "title": "Mon cahier",
  "change_description": "Ajout des photos",
  "created_by": 2,
  "created_at": "2024-01-15T12:00:00"
}
```

---

### GET /api/notebooks/{notebook_id}/versions
**Récupérer l'historique**

```
GET /api/notebooks/1/versions
Authorization: Bearer {token}
```

**Réponse (200 OK):**
```json
[
  {
    "id": 1,
    "notebook_id": 1,
    "version_number": 1,
    "title": "Mon cahier",
    "change_description": "Création",
    "created_by": 2,
    "created_at": "2024-01-15T10:30:00"
  },
  {
    "id": 2,
    "notebook_id": 1,
    "version_number": 2,
    "title": "Mon cahier",
    "change_description": "Ajout des photos",
    "created_by": 2,
    "created_at": "2024-01-15T12:00:00"
  }
]
```

---

### POST /api/notebooks/{notebook_id}/versions/{version_id}/restore
**Restaurer une version**

```
POST /api/notebooks/1/versions/1/restore
Authorization: Bearer {token}
```

**Réponse (200 OK):**
```json
{
  "message": "Version 1 restaurée",
  "notebook": { /* objet cahier complet */ }
}
```

**Erreurs:**
- `403 Forbidden` - Seulement le créateur
- `404 Not Found` - Version introuvable

---

## Recherche

### GET /api/notebooks/search
**Recherche full-text**

```
GET /api/notebooks/search?query=bio
Authorization: Bearer {token}
```

**Query Parameters:**
| Paramètre | Type | Description |
|-----------|------|-------------|
| `query` | string | Terme de recherche (titre, description) |

**Réponse (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Agriculture bio",
    "description": "Cahier de culture biologique",
    ...
  },
  ...
]
```

---

## Codes d'erreur

### 400 Bad Request
Données invalides

```json
{
  "detail": "farm_id doit être un entier positif"
}
```

### 401 Unauthorized
Token absent ou invalide

```json
{
  "detail": "Token invalide ou expiré"
}
```

### 403 Forbidden
Pas de permission

```json
{
  "detail": "Seul le créateur peut modifier ce cahier"
}
```

### 404 Not Found
Ressource non trouvée

```json
{
  "detail": "Cahier avec ID 999 non trouvé"
}
```

### 500 Internal Server Error
Erreur serveur

```json
{
  "detail": "Erreur serveur interne"
}
```

---

## 🔒 Règles de permission

| Action | Créateur | Partagé | Public | Lecture |
|--------|----------|---------|--------|---------|
| Lire | ✅ | ✅ | ✅ | ✅ |
| Modifier | ✅ | ❌ | ❌ | ❌ |
| Supprimer | ✅ | ❌ | ❌ | ❌ |
| Commenter | ✅ | ✅ | ✅ | ✅ |
| Partager | ✅ | ❌ | ❌ | ❌ |
| Versioning | ✅ | ✅ | ❌ | ❌ |

---

## 📝 Exemples curl

### Créer un cahier

```bash
curl -X POST http://localhost:8000/api/notebooks \
  -H "Authorization: Bearer eyJhbg..." \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test",
    "description": "Test cahier",
    "farm_id": 1,
    "category": "general",
    "tags": []
  }'
```

### Lister les cahiers

```bash
curl http://localhost:8000/api/notebooks \
  -H "Authorization: Bearer eyJhbg..."
```

### Ajouter un commentaire

```bash
curl -X POST http://localhost:8000/api/notebooks/1/comments \
  -H "Authorization: Bearer eyJhbg..." \
  -H "Content-Type: application/json" \
  -d '{"text": "Bon travail!"}'
```

### Rechercher

```bash
curl "http://localhost:8000/api/notebooks/search?query=agriculture" \
  -H "Authorization: Bearer eyJhbg..."
```

---

## 🧪 Tester avec Postman

1. Importer la collection (JSON):
```json
{
  "info": {"name": "Cahier API"},
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}"}]},
  "item": [
    {"name": "POST criar", "request": {"method": "POST", "url": "{{baseUrl}}/api/notebooks", ...}},
    {"name": "GET list", "request": {"method": "GET", "url": "{{baseUrl}}/api/notebooks", ...}},
    ...
  ]
}
```

2. Définir les variables:
   - `baseUrl` = `http://localhost:8000`
   - `token` = Votre JWT token

3. Tester chaque endpoint

---

**Version:** 1.0  
**Dernière mise à jour:** 2024  
**Status:** Production-ready ✅
