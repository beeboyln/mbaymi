/// The `FarmCard` class in Dart is a widget that represents a farm with interactive pins displaying
/// crop information and allows for editing and deleting farm details.
/// 
/// Args:
///   crop (Map<String, dynamic>): The `crop` parameter in the code represents a map containing
/// information about a crop, such as its name, image URL, health status, problems, and other related
/// details. This information is used to determine the color representation of the crop based on its
/// health status and problems. The `_statusColor`
/// 
/// Returns:
///   The code provided is a Flutter widget called `FarmCard` that represents a card displaying
/// information about a farm. The card includes details such as the farm name, location, image, owner
/// status, and crop information. It also allows for interactions like editing, deleting, viewing
/// parcels, and tapping on crop pins for more details.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mbaymi/utils/app_colors.dart';
import 'farm_tab_components.dart';
import 'parcel_overlay.dart';



// ─────────────────────────────────────────────────────────────────────────────
// FARM CARD PRINCIPALE
// ─────────────────────────────────────────────────────────────────────────────
class FarmCard extends StatefulWidget {
  final Map<String, dynamic> farm;
  final int farmId;
  final String name;
  final String location;
  final String? image;
  final bool isOwner;
  final bool dark;
  final Future<List<dynamic>> cropsFuture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onParcelles;
  final void Function(int parcelId) onParcelTap;
  final void Function(BuildContext, String, String) onPhotoTap;

  const FarmCard({
    super.key,
    required this.farm,
    required this.farmId,
    required this.name,
    required this.location,
    required this.image,
    required this.isOwner,
    required this.dark,
    required this.cropsFuture,
    required this.onEdit,
    required this.onDelete,
    required this.onParcelles,
    required this.onParcelTap,
    required this.onPhotoTap,
  });

  @override
  State<FarmCard> createState() => _FarmCardState();
}

class _FarmCardState extends State<FarmCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _placeholder() => Container(
        color: widget.dark ? AppColors.darkCardBg : AppColors.lightCardBg,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 36,
            color: (widget.dark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRect(
        child: Stack(children: [
          // Image + pins
          Positioned.fill(
            child: Stack(fit: StackFit.expand, children: [
              widget.image != null && widget.image!.isNotEmpty
                  ? Image.network(widget.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),

              // Gradients
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.30, 0.62, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.40),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.22)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Parcelles overlay
              FutureBuilder<List<dynamic>>(
                future: widget.cropsFuture,
                builder: (ctx, snap) {
                  if ((snap.data ?? []).isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final crops = snap.data!;
                  final parcels = crops
                      .map((c) => {
                            'id': c['id'] ?? 0,
                            'name': c['crop_name'] ?? 'Parcelle',
                            'parcel_name': c['crop_name'] ?? 'Parcelle',
                            'image_url': c['image_url'] ?? c['photo_url'] ?? c['photo'] ?? '',
                            'status': c['status'] ?? 'growing',
                            'problems': c['problems'] ?? [],
                          })
                      .toList();

                  return ParcelOverlay(
                    farmId: widget.farmId,
                    parcels: parcels,
                    dark: widget.dark,
                    farmImage: widget.image,
                    onParcelTap: widget.onParcelTap,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  );
                },
              ),
            ]),
          ),

          // Overlays fixes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.90)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nom + lieu + bouton
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 2.5,
                                color: Colors.white),
                          ),
                          if (widget.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.place_outlined,
                                  size: 10, color: Colors.white54),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.4,
                                      color: Colors.white54),
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onParcelles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 0.5)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PARCELLES',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.2,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS & ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────
