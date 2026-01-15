import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/notification_model.dart';
import 'package:mbaymi/services/notification_service.dart';
import 'package:mbaymi/utils/app_theme.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';

/// 🔔 Page des notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = NotificationService.getNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      _loadNotifications();
    }
  }

  void _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    _loadNotifications();
  }

  void _deleteNotification(NotificationModel notification) async {
    await NotificationService.deleteNotification(notification.id);
    _loadNotifications();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('d MMM', 'fr_FR').format(dateTime);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'comment':
        return Icons.chat_bubble;
      case 'like':
        return Icons.favorite;
      case 'share':
        return Icons.share;
      case 'message':
        return Icons.mail;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'comment':
        return Colors.orange;
      case 'like':
        return Colors.red;
      case 'share':
        return Colors.purple;
      case 'message':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marquer tout',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            final isAuthError = errorMessage.contains('not authenticated') || 
                               errorMessage.contains('No access token') ||
                               errorMessage.contains('Token expired');
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAuthError ? Icons.lock_outline : Icons.error_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthError ? 'Connectez-vous pour voir vos notifications' : 'Erreur de chargement',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadNotifications();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pas de notifications',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadNotifications();
              });
              await _notificationsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final iconColor = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? Colors.grey[200]! 
              : AppTheme.primaryColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('🔔 Notification tapped: ${notification.title}');
            print('🎯 actorId: ${notification.actorId}');
            print('👤 actorName: ${notification.actorName}');
            _markAsRead(notification);
            // Naviguer vers la page détail du profil de l'utilisateur
            if (notification.actorId != null) {
              print('➡️ Navigating to ProfileDetailScreen with userId=${notification.actorId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileDetailScreen(
                    userId: notification.actorId!,
                    isDarkMode: false,
                  ),
                ),
              );
            } else {
              print('❌ actorId is null!');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar ou icône
                if (notification.actorImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: notification.actorImage!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                  ),
                const SizedBox(width: 12),
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre avec indicateur non-lu
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        notification.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Temps écoulé
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton supprimer - clickable sans interferer avec le tap
                GestureDetector(
                  onTap: (notification.actorId ?? 0) > 0 ? null : null, // Ne rien faire sur le tap du bouton
                  child: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNotification(notification);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 12),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
