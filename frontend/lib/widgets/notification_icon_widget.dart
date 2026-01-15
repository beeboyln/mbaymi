import 'package:flutter/material.dart';
import 'package:mbaymi/screens/notifications_screen.dart';
import 'package:mbaymi/services/notification_service.dart';
import 'package:mbaymi/utils/app_theme.dart';

/// 🔔 Widget d'icône notification avec badge
class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({Key? key}) : super(key: key);

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
              icon: const Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Colors.black87,
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
            // Badge rouge simple quand il y a des notifications
            if (_unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
