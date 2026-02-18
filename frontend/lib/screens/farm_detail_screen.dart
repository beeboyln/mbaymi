import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/activity_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF7F6F4);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF888888);
  static const faint = Color(0xFFE8E6E1);
  static const cardBg = Color(0xFFFFFFFF);
  static const accent = Color(0xFF4A7C59); // Vert nature

  // Statuts parcelles — sobres
  static const statusPrep = Color(0xFF8B6914);
  static const statusSown = Color(0xFF4A7C59);
  static const statusGrow = Color(0xFF3A6B8B);
  static const statusHarv = Color(0xFF6B4A7C);
}
// ─────────────────────────────────────────────────────────────────────────────

class FarmDetailScreen extends StatefulWidget {
  final int farmId;
  final Map<String, dynamic> farmData;
  final bool isDarkMode;
  final bool readOnly;

  const FarmDetailScreen({
    super.key,
    required this.farmId,
    required this.farmData,
    this.isDarkMode = false,
    this.readOnly = false,
  });

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _farmDetailsFuture;
  int _userId = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _farmDetailsFuture = _getFarmDetails(widget.farmId);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getFarmDetails(int farmId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/farm-network/details/$farmId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load farm details');
  }

  Future<void> _refresh() async {
    setState(() => _farmDetailsFuture = _getFarmDetails(widget.farmId));
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Semé': return _Z.statusSown;
      case 'En croissance': return _Z.statusGrow;
      case 'Récolté': return _Z.statusHarv;
      default: return _Z.statusPrep;
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final farmName = widget.farmData['farm_name'] ??
        widget.farmData['name'] ??
        widget.farmData['title'] ??
        'Ferme';
    final farmerName = widget.farmData['farmer_name'] ??
        widget.farmData['user_name'] ??
        widget.farmData['owner_name'] ??
        widget.farmData['owner'] ??
        'Agriculteur';
    final farmDesc =
        widget.farmData['description'] ?? widget.farmData['bio'] ?? '';

    return Scaffold(
      backgroundColor: _Z.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _Z.ink,
          backgroundColor: _Z.bg,
          child: CustomScrollView(
            slivers: [
              // ── Hero image ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: _Z.bg,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: _Z.bg.withOpacity(0.85),
                      child: const Icon(Icons.arrow_back,
                          size: 18, color: _Z.ink),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: FutureBuilder<Map<String, dynamic>>(
                    future: _farmDetailsFuture,
                    builder: (context, snap) {
                      final photos =
                          (snap.data?['photos'] as List?) ?? [];
                      final photoUrl = photos.isNotEmpty
                          ? (photos.first
                              as Map<String, dynamic>)['image_url']
                          : null;
                      final profileImg = widget.farmData['profile_image'] ??
                          widget.farmData['image_url'] ??
                          widget.farmData['profile_image_farm'] ??
                          widget.farmData['image'];
                      final imageUrl = photoUrl ??
                          (profileImg is String && profileImg.isNotEmpty
                              ? profileImg
                              : null);

                      if (imageUrl != null) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholder()),
                            // Subtle bottom fade
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      _Z.bg.withOpacity(0.6),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _placeholder();
                    },
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farm name + farmer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: _Z.ink,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Farmer chip
                          Row(
                            children: [
                              Container(
                                width: 1,
                                height: 28,
                                color: _Z.accent,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(farmerName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _Z.ink,
                                          letterSpacing: 0.3)),
                                  const Text('PROPRIÉTAIRE',
                                      style: TextStyle(
                                          fontSize: 9,
                                          letterSpacing: 2.5,
                                          color: _Z.muted,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),

                          if (farmDesc.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              farmDesc,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: _Z.muted,
                                  height: 1.7,
                                  letterSpacing: 0.2),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Parcelles section ─────────────────────────────────
                    _buildParcelsSection(),

                    const SizedBox(height: 36),

                    // ── Divider ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Text('PUBLICATIONS',
                              style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w500,
                                  color: _Z.muted)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Container(height: 1, color: _Z.faint)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Posts ─────────────────────────────────────────────
                    FarmPostsWidget(
                      farmId: widget.farmId,
                      farmName: farmName,
                      isOwner: !widget.readOnly &&
                          (_toInt(widget.farmData['user_id']) == _userId ||
                              _toInt(widget.farmData['owner_id']) ==
                                  _userId),
                      livestockId: null,
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PLACEHOLDER ─────────────────────────────────────────────────────────
  Widget _placeholder() {
    return Container(
      color: _Z.faint,
      child: const Center(
        child: Icon(Icons.agriculture_outlined, size: 64, color: _Z.muted),
      ),
    );
  }

  // ─── PARCELS ─────────────────────────────────────────────────────────────
  Widget _buildParcelsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _farmDetailsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SkeletonPageLoader(
            isDarkMode: widget.isDarkMode,
            includeAppBar: false,
            cardCount: 3,
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: _Z.faint)),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: _Z.muted),
                  SizedBox(width: 12),
                  Text('Erreur de chargement',
                      style: TextStyle(fontSize: 13, color: _Z.muted)),
                ],
              ),
            ),
          );
        }

        final crops = (snap.data?['crops'] as List?) ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  const Text('PARCELLES',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                          color: _Z.muted)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Container(height: 1, color: _Z.faint)),
                  const SizedBox(width: 12),
                  Text('${crops.length}',
                      style: const TextStyle(
                          fontSize: 9, letterSpacing: 1, color: _Z.muted)),
                ],
              ),

              const SizedBox(height: 16),

              if (crops.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              border: Border.all(color: _Z.faint)),
                          child: const Icon(Icons.landscape_outlined,
                              size: 28, color: _Z.muted),
                        ),
                        const SizedBox(height: 16),
                        const Text('AUCUNE PARCELLE',
                            style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 3,
                                color: _Z.muted)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crops.length,
                  separatorBuilder: (_, __) =>
                      Container(height: 1, color: _Z.faint),
                  itemBuilder: (context, i) =>
                      _ParcelRow(
                        crop: crops[i] as Map<String, dynamic>,
                        statusColor: _statusColor(
                            crops[i]['status'] ?? 'En préparation'),
                        onTap: () => _showActivitiesSheet(
                            crops[i] as Map<String, dynamic>),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── ACTIVITIES SHEET ─────────────────────────────────────────────────────
  void _showActivitiesSheet(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        color: _Z.bg,
        child: Column(
          children: [
            // Handle
            Container(
                width: 32,
                height: 2,
                color: _Z.faint,
                margin: const EdgeInsets.only(top: 24, bottom: 20)),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (crop['crop_name'] ?? 'Parcelle')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                            color: _Z.ink),
                      ),
                      const Text('ACTIVITÉS',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 3,
                              color: _Z.muted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 18, color: _Z.muted),
                  ),
                ],
              ),
            ),

            Container(
                height: 1,
                color: _Z.faint,
                margin: const EdgeInsets.symmetric(vertical: 16)),

            Expanded(
              child: ActivityScreen(
                farmId: widget.farmId,
                cropId: _toInt(crop['id']) ?? 0,
                userId: _userId,
                readOnly: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PARCEL ROW ───────────────────────────────────────────────────────────────
class _ParcelRow extends StatelessWidget {
  final Map<String, dynamic> crop;
  final Color statusColor;
  final VoidCallback onTap;

  const _ParcelRow({
    required this.crop,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = crop['status'] ?? 'En préparation';
    final cropType = crop['crop_type'] ?? '';
    final plantedDate = crop['planted_date'] ?? '';
    final imageUrl = crop['image_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 72,
              height: 72,
              color: _Z.faint,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.landscape_outlined,
                          size: 24, color: _Z.muted))
                  : const Icon(Icons.landscape_outlined,
                      size: 24, color: _Z.muted),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (crop['crop_name'] ?? 'Parcelle')
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                              color: _Z.ink),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: _Z.muted),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    color: statusColor.withOpacity(0.1),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Meta
                  Row(
                    children: [
                      if (cropType.isNotEmpty) ...[
                        Text(cropType,
                            style: const TextStyle(
                                fontSize: 11, color: _Z.muted)),
                        if (plantedDate.isNotEmpty)
                          const Text(' · ',
                              style:
                                  TextStyle(fontSize: 11, color: _Z.muted)),
                      ],
                      if (plantedDate.isNotEmpty)
                        Text(plantedDate,
                            style: const TextStyle(
                                fontSize: 11, color: _Z.muted)),
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