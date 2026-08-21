import 'package:flutter/material.dart';
import 'package:mbaymi/models/veterinarian_model.dart';

// ────────────────────────────────────────────────────────────────────
// PROFILE HEADER
// ────────────────────────────────────────────────────────────────────

class VetProfileHeader extends StatelessWidget {
  final VeterinarianProfile profile;
  final VoidCallback onEditProfile;

  const VetProfileHeader({
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
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
                    profile.specialty,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.zone,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: profile.verificationStatus),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: const Text('Éditer le profil'),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'verified':
        return '✓ Vérifié';
      case 'pending':
        return '⏳ En attente';
      case 'rejected':
        return '✗ Rejeté';
      default:
        return 'Inconnu';
    }
  }
}

// ────────────────────────────────────────────────────────────────────
// STATS ROW
// ────────────────────────────────────────────────────────────────────

class VetStatsRow extends StatelessWidget {
  final VeterinarianProfile profile;

  const VetStatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.onSurface.withOpacity(0.1);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          _StatItem(
            value: '${profile.consultationCount ?? 0}',
            label: 'Consultations',
          ),
          VerticalDivider(color: dividerColor, thickness: 1, width: 32),
          _StatItem(
            value: profile.rating?.toStringAsFixed(1) ?? 'N/A',
            label: 'Note',
          ),
          VerticalDivider(color: dividerColor, thickness: 1, width: 32),
          _StatItem(
            value: '${profile.experienceYears} ans',
            label: 'Expérience',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// REQUEST ITEM
// ────────────────────────────────────────────────────────────────────

class RequestItem extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const RequestItem({
    required this.request,
    required this.onTap,
  });

  String _extractDiagnosisSummary(String reason) {
    final regex = RegExp(r'À diagnostiquer:\s*(.+?)(?:\n|$)', caseSensitive: false);
    final match = regex.firstMatch(reason);
    return match?.group(1)?.trim() ?? '';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inHours < 1) {
        return 'Il y a ${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays}j';
      }
      return dateStr;
    } catch (e) {
      return 'Récemment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farm = request['farm'] as Map<String, dynamic>?;
    final farmer = request['farmer'] as Map<String, dynamic>?;
    final livestocks = (farm?['livestocks'] as List?) ?? [];
    final isFarmAuthorization = farm != null && farm['id'] != null;
    
    String displayTitle;
    if (isFarmAuthorization) {
      displayTitle = farm['name'] ?? 'Ferme sans nom';
    } else if (livestocks.isNotEmpty) {
      final livestock = livestocks[0];
      displayTitle = '${livestock['animal_type']} - ${livestock['breed'] ?? 'Race'}';
    } else {
      displayTitle = 'Autorisation';
    }
    
    final farmerName = farmer?['name'] ?? 'Agriculteur';
    final reason = request['authorization_reason'] ?? 'Pas de raison spécifiée';
    final createdAt = request['created_at'] ?? '';
    final diagnosisSummary = _extractDiagnosisSummary(reason);
    
    final photos = (farm?['photos'] as List?) ?? [];
    dynamic firstPhotoSource;
    if (photos.isNotEmpty) {
      firstPhotoSource = photos[0];
    } else if (livestocks.isNotEmpty) {
      firstPhotoSource = livestocks[0];
    }
    final firstPhotoUrl = firstPhotoSource?['image_url'] as String?;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstPhotoUrl != null)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 30),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'En attente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farmerName,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (diagnosisSummary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              diagnosisSummary,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Détails →',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ────────────────────────────────────────────────────────────────────

class EmptyTabContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyTabContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// DETAIL ROW
// ────────────────────────────────────────────────────────────────────

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
