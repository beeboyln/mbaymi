# 🔔 Système de Notifications

## Vue d'ensemble

Le système de notifications permet aux utilisateurs de recevoir et gérer les notifications en temps réel lorsque:
- ✅ Quelqu'un les suit
- ✅ Quelqu'un commente leur post
- ✅ Quelqu'un aime leur contenu
- ✅ (Extensible) Autres événements

## Architecture

### Frontend (Flutter)

#### 1. **Modèle de Notification** (`lib/models/notification_model.dart`)
```dart
class NotificationModel {
  final int id;
  final int userId;
  final String type;  // 'follow', 'comment', 'like', etc.
  final String title;
  final String description;
  final String? actionUrl;
  final String? actorName;
  final String? actorImage;
  final bool isRead;
  final DateTime createdAt;
}
```

#### 2. **Service de Notification** (`lib/services/notification_service.dart`)
```dart
NotificationService.getNotifications()  // Récupérer les notifs
NotificationService.getUnreadCount()    // Compter les non-lues
NotificationService.markAsRead()        // Marquer comme lue
NotificationService.markAllAsRead()     // Marquer toutes comme lues
NotificationService.deleteNotification()// Supprimer une notif
```

#### 3. **Page des Notifications** (`lib/screens/notifications_screen.dart`)
- 📱 UI élégante et légère
- 🎨 Codes couleur par type (follow=bleu, like=rouge, comment=orange)
- ⏱️ Affichage du temps écoulé (Il y a 5m, Il y a 2h, etc.)
- 🔄 Refresh automatique au pull-down
- 🗑️ Suppression individuelle via menu contextuel

#### 4. **Widget Icône Notification** (`lib/widgets/notification_icon_widget.dart`)
- 🔴 Badge rouge avec nombre de notifications non lues
- 📍 Placé dans le header de l'app
- 🔄 Rafraîchit toutes les 30 secondes
- 👆 Mène à la page des notifications au tap

### Backend (FastAPI)

#### 1. **Modèle Notification** (`app/models/notification.py`)
```python
class Notification(Base):
    id: int
    user_id: int          # Destinataire
    type: str             # 'follow', 'like', 'comment', etc.
    title: str
    description: str
    action_url: str       # URL pour action
    actor_name: str       # Qui a déclenché
    actor_image: str      # Photo de qui
    is_read: bool
    created_at: datetime
```

#### 2. **Service Notification** (`app/services/notification_service.py`)
```python
NotificationService.create_notification()  # Créer une notif
NotificationService.get_user_notifications() # Lister
NotificationService.get_unread_count()    # Compter non-lues
NotificationService.mark_as_read()        # Marquer lue
NotificationService.mark_all_as_read()    # Marquer toutes lues
NotificationService.delete_notification() # Supprimer
```

#### 3. **Routes API** (`app/routes/notifications.py`)

```
GET  /users/{user_id}/notifications              # Lister
GET  /users/{user_id}/notifications/unread-count # Compter
PUT  /users/{user_id}/notifications/{id}/read    # Marquer lue
PUT  /users/{user_id}/notifications/read-all     # Marquer toutes
DELETE /users/{user_id}/notifications/{id}       # Supprimer
```

#### 4. **Génération de Notifications**
Exemple: Dans `app/routes/farm_network.py` route `follow_user()`

```python
@router.post("/follow-user/{user_id_to_follow}")
def follow_user(...):
    # ... logique du suivi ...
    
    # 🔔 Créer une notification
    NotificationService.create_notification(
        db=db,
        user_id=user_id_to_follow,  # Destinataire
        notification_type='follow',
        title=f'{follower.name} vous suit',
        description=f'{follower.name} a commencé à vous suivre',
        actor_name=follower.name,
        actor_image=follower.profile_image,
        action_url=f'/user-profile/{user_id}'
    )
```

### Base de Données

Table `notifications` avec indices optimisés:
```sql
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR(50),
    title VARCHAR(255),
    description TEXT,
    action_url VARCHAR(500),
    actor_name VARCHAR(255),
    actor_image VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Index pour perfs
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
```

## Utilisation

### 1. Afficher les notifications
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const NotificationsScreen(),
));
```

### 2. Créer une notification (Backend)
```python
from app.services.notification_service import NotificationService

NotificationService.create_notification(
    db=db,
    user_id=123,
    notification_type='like',
    title='Quelqu\'un aime votre post',
    description='Pierre a aimé votre photo',
    actor_name='Pierre Farmer',
    actor_image='https://...',
    action_url='/post/456'
)
```

## Types de Notifications Supportés

| Type | Couleur | Icône | Exemple |
|------|---------|-------|---------|
| `follow` | Bleu | person_add | "Jean vous suit" |
| `like` | Rouge | favorite | "Marie a aimé votre post" |
| `comment` | Orange | chat_bubble | "Paul a commenté votre photo" |
| `share` | Violet | share | "Sophie a partagé votre contenu" |
| `message` | Teal | mail | "Nouveau message de Thomas" |

## Fonctionnalités

✅ **Récupération paginée** - Charge 20 notifs par défaut  
✅ **Compteur non-lues** - Badge sur l'icône  
✅ **Rafraîchissement automatique** - Toutes les 30s  
✅ **Pull-to-refresh** - Rafraîchir manuellement  
✅ **Suppression** - Menu contextuel  
✅ **Marquer comme lue** - Automatique au clic  
✅ **Marquer toutes lues** - Bouton dans le header  
✅ **Temps formaté** - "Il y a 5m", "Hier", etc.  
✅ **Images des acteurs** - Photos de profil  
✅ **Actions** - Liens pour naviguer  

## Performance

- 🚀 **Indexes DB** - Requêtes O(log n)
- 🎯 **Pagination** - 20 notifs par page
- 🔄 **Rafraîchissement 30s** - Pas de polling constant
- 💾 **Caching images** - CachedNetworkImage
- 🏗️ **Lazy loading** - ListView avec builder

## Sécurité

🔐 **Authentification requise** - `@Depends(get_current_user)`  
🔐 **Vérification ownership** - Chaque user ne voit que ses notifs  
🔐 **Suppression sécurisée** - Vérification user_id  

## Améliorations Futures

- [ ] WebSocket pour notifications en temps réel
- [ ] Push notifications mobiles (Firebase)
- [ ] Notifications par email
- [ ] Groupage de notifications identiques
- [ ] Filtrage par type
- [ ] Archivage automatique après 30 jours
- [ ] Préférences de notification par utilisateur
- [ ] Notification sonore/vibrante

## Exécution de la Migration

```bash
# 1. Exécuter le SQL
psql -U user -d mbaymi -f backend/sql/create_notifications_table.sql

# 2. Ou via Python (migrate.py)
python backend/migrate.py
```

## Déploiement

```bash
# 1. Commit des changements
git add .
git commit -m "Feat: Add comprehensive notification system"

# 2. Push
git push

# 3. Vercel auto-déploie
vercel --prod --yes
```

## Troubleshooting

❌ **Notifs ne s'affichent pas?**
- Vérifier que user_id est correct
- Vérifier la table `notifications` existe
- Vérifier les logs du backend

❌ **Badge ne met à pas à jour?**
- Attendre 30s (refresh automatique)
- Ou pull-to-refresh manuellemént
- Ou recharger l'app

❌ **Erreur 403 Forbidden?**
- Vérifier que vous êtes authentifié
- Vérifier que c'est votre user_id
