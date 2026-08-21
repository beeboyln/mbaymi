import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/fading_images_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS & CONSTANTES
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _lbl({
  double size = 11,
  double spacing = 1.5,
  double opacity = 1,
  FontWeight w = FontWeight.w300,
  Color? color,
}) => TextStyle(
  fontSize: size,
  letterSpacing: spacing,
  fontWeight: w,
  color: color?.withOpacity(opacity),
);

// ─────────────────────────────────────────────────────────────────────────────
// SECTION BAR
// ─────────────────────────────────────────────────────────────────────────────
class SectionBar extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  final bool dark;

  const SectionBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final border = (dark ? Colors.white : Colors.black).withOpacity(0.08);
    final tabs = [
      (icon: Icons.landscape_outlined, label: 'FERMES'),
      (icon: Icons.pets_outlined, label: 'ANIMAUX'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final tab = e.value;
          final sel = selected == i;
          final fg = dark ? Colors.white : Colors.black87;
          final sub = (dark ? Colors.white : Colors.black).withOpacity(0.38);

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? AppColors.accent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: 14, color: sel ? fg : sub),
                    const SizedBox(width: 8),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: sel ? fg : sub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS DOT (pour la légende)
// ─────────────────────────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const StatusDot({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 1.5,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON (pour les états vides)
// ─────────────────────────────────────────────────────────────────────────────
class ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool dark;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: filled
          ? TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                label,
                style: _lbl(size: 10, spacing: 2, color: Colors.white),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                side: BorderSide(
                  color: (dark ? Colors.white : Colors.black).withOpacity(0.2),
                ),
              ),
              child: Text(
                label,
                style: _lbl(
                  size: 10,
                  spacing: 2,
                  color: dark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OWNER BUTTON (pour les cartes de ferme)
// ─────────────────────────────────────────────────────────────────────────────
class OwnerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const OwnerButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          border: Border.all(
            color: danger
                ? Colors.red.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: danger
              ? Colors.red.shade300
              : Colors.white.withOpacity(0.85),
          size: 15,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADER (pour les FutureBuilder)
// ─────────────────────────────────────────────────────────────────────────────
class FarmLoader extends StatelessWidget {
  final bool dark;

  const FarmLoader({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: (dark ? Colors.white : Colors.black).withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final bool isLivestock;
  final bool dark;
  final VoidCallback onCreateFarm;
  final VoidCallback onCreateLivestock;

  const EmptyState({
    super.key,
    required this.isLivestock,
    required this.dark,
    required this.onCreateFarm,
    required this.onCreateLivestock,
  });

  @override
  Widget build(BuildContext context) {
    final fg = (dark ? Colors.white : Colors.black).withOpacity(0.15);

    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLivestock ? Icons.pets_outlined : Icons.landscape_outlined,
              size: 32,
              color: fg,
            ),
            const SizedBox(height: 24),
            Text(
              isLivestock ? 'AUCUN ANIMAL' : 'AUCUNE FERME',
              style: _lbl(
                size: 10,
                spacing: 2.5,
                color: dark ? Colors.white60 : Colors.black38,
              ),
            ),
            const SizedBox(height: 40),
            ActionButton(
              label: 'CRÉER UNE FERME',
              filled: true,
              onTap: onCreateFarm,
            ),
            const SizedBox(height: 12),
            ActionButton(
              label: 'AJOUTER DU BÉTAIL',
              filled: false,
              dark: dark,
              onTap: onCreateLivestock,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME SCREEN (pour utilisateur non connecté)
// ─────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  final bool dark;
  final VoidCallback onLogin;
  final VoidCallback onDiscover;

  const WelcomeScreen({
    super.key,
    required this.dark,
    required this.onLogin,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const FadingImagesWidget(
                imageUrls: [
                  'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769257913/kxbovkugo5ertntwwtgv.jpg',
                  'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769258097/hcrl7a4o7ttp9idaaf4j.jpg',
                  'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259314/lukvpj3povcqtbahoe0f.jpg',
                  'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259315/xmyyggmzlwr1w1lti5w8.jpg',
                  'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259313/ecjpbmfnxdzlmpmk73gy.jpg',
                ],
                height: 240,
                displayDuration: Duration(seconds: 3),
                fadeDuration: Duration(milliseconds: 800),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAVANA',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 9,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Agriculture moderne',
                      style: _lbl(size: 11, spacing: 1.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              ActionButton(
                label: 'SE CONNECTER',
                filled: true,
                onTap: onLogin,
              ),
              const SizedBox(height: 14),
              ActionButton(
                label: 'DÉCOUVRIR',
                filled: false,
                dark: dark,
                onTap: onDiscover,
              ),
              const SizedBox(height: 24),
              Text(
                'Explorez des fermes publiques',
                style: _lbl(
                  size: 11,
                  spacing: 0.5,
                  opacity: 0.38,
                  color: dark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
