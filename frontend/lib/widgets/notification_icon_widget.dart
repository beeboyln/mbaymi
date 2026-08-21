import 'package:flutter/material.dart';
import 'package:mbaymi/screens/social/notifications_screen.dart';
import 'package:mbaymi/services/notification_service.dart';
import 'package:mbaymi/utils/app_theme.dart';

/// 🔔 Widget d'icône notification avec badge
class NotificationIconWidget extends StatefulWidget {
  final Color? iconColor;
  
  const NotificationIconWidget({super.key, this.iconColor});

  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  int _unreadCount = 0;
  late Future<void> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = _loadUnreadCount();
    // Rafraîchir toutes les 30 secondes
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startRefreshTimer();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Silencieusement gérer l'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _unreadFuture,
      builder: (context, snapshot) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            // Bouton notification
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: widget.iconColor ?? (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.getTextColor(true)
                    : AppTheme.getTextColor(false)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ).then((_) {
                  // Rafraîchir le badge quand on revient
                  _loadUnreadCount();
                });
              },
            ),
            // Badge verte (visible en mode sombre)
            if (_unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.45),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.white.withOpacity(0.6),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
