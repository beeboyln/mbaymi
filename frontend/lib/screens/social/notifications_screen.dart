import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/models/notification_model.dart';
import 'package:mbaymi/services/notification_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/screens/social/profile_detail_screen.dart';

/// 🔔 Page des notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

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
      return 'À L\'INSTANT';
    } else if (difference.inMinutes < 60) {
      return 'IL Y A ${difference.inMinutes}M';
    } else if (difference.inHours < 24) {
      return 'IL Y A ${difference.inHours}H';
    } else if (difference.inDays < 7) {
      return 'IL Y A ${difference.inDays}J';
    } else {
      return DateFormat('d MMM', 'fr_FR').format(dateTime).toUpperCase();
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_outlined;
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.favorite_border;
      case 'share':
        return Icons.share_outlined;
      case 'message':
        return Icons.mail_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFBF5);
        final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
        final subtleColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF757575);
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: bgColor,
            title: Text(
              'NOTIFICATIONS',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 2.5,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 18, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'TOUT MARQUER',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 0.5,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              ),
            ),
          ),
          body: FutureBuilder<List<NotificationModel>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(isDark, subtleColor);
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), isDark, textColor, subtleColor);
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return _buildEmptyState(isDark, textColor, subtleColor);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadNotifications();
                  });
                  await _notificationsFuture;
                },
                color: isDark ? Colors.white : Colors.black,
                backgroundColor: bgColor,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildNotificationCard(notification, isDark, textColor, subtleColor),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark, Color subtleColor) {
    return Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark, Color textColor, Color subtleColor) {
    final isAuthError = error.contains('not authenticated') || 
                       error.contains('No access token') ||
                       error.contains('Token expired');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAuthError ? Icons.lock_outline : Icons.error_outline,
            size: 48,
            color: subtleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            isAuthError ? 'CONNEXION REQUISE' : 'ERREUR DE CHARGEMENT',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isAuthError 
                  ? 'Connectez-vous pour voir vos notifications'
                  : 'Une erreur s\'est produite',
              style: TextStyle(
                color: subtleColor,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
              setState(() {
                _loadNotifications();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                  width: 1,
                ),
              ),
              child: Text(
                'RÉESSAYER',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color subtleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: subtleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'AUCUNE NOTIFICATION',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour',
            style: TextStyle(
              color: subtleColor,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    bool isDark,
    Color textColor,
    Color subtleColor,
  ) {
    final icon = _getNotificationIcon(notification.type);
    
    return InkWell(
      onTap: () {
        print('🔔 Notification tapped: ${notification.title}');
        print('🎯 actorId: ${notification.actorId}');
        print('👤 actorName: ${notification.actorName}');
        _markAsRead(notification);
        
        if (notification.actorId != null) {
          print('➡️ Navigating to ProfileDetailScreen with userId=${notification.actorId}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailScreen(
                userId: notification.actorId!,
                isDarkMode: isDark,
              ),
            ),
          );
        } else {
          print('❌ actorId is null!');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: notification.isRead
                ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0))
                : (isDark ? const Color(0xFF404040) : const Color(0xFF1A1A1A)),
            width: notification.isRead ? 1 : 1.5,
          ),
          color: notification.isRead
              ? Colors.transparent
              : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar ou icône
            _buildAvatar(notification, icon, isDark, subtleColor),
            const SizedBox(width: 16),
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    notification.title.toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    notification.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 13,
                      letterSpacing: 0.3,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Temps écoulé
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: subtleColor.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Menu actions
            _buildActionsMenu(notification, isDark, subtleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    NotificationModel notification,
    IconData icon,
    bool isDark,
    Color subtleColor,
  ) {
    const size = 52.0;
    
    if (notification.actorImage != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: CachedNetworkImage(
          imageUrl: notification.actorImage!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            child: Center(
              child: Icon(icon, color: subtleColor, size: 20),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            child: Center(
              child: Icon(icon, color: subtleColor, size: 20),
            ),
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
          width: 1,
        ),
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      ),
      child: Center(
        child: Icon(icon, color: subtleColor, size: 20),
      ),
    );
  }

  Widget _buildActionsMenu(
    NotificationModel notification,
    bool isDark,
    Color subtleColor,
  ) {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 'delete') {
          _deleteNotification(notification);
        } else if (value == 'mark_read' && !notification.isRead) {
          _markAsRead(notification);
        }
      },
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      itemBuilder: (context) => [
        if (!notification.isRead)
          PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 12),
                Text(
                  'Marquer comme lu',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(width: 12),
              Text(
                'Supprimer',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.more_vert,
          size: 16,
          color: subtleColor,
        ),
      ),
    );
  }
}