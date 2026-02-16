import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

class PublicFarmsScreen extends StatefulWidget {
  const PublicFarmsScreen({super.key});

  @override
  State<PublicFarmsScreen> createState() => _PublicFarmsScreenState();
}

class _PublicFarmsScreenState extends State<PublicFarmsScreen> {
  Future<List<dynamic>>? _farmsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Persistent cache for public farms
  static final Map<String, Future<List<dynamic>>> _globalDataCache = {};
  static final Map<int, Future<List<dynamic>>> _globalCropsCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    _loadPublicFarms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPublicFarms() {
    _farmsFuture = _getPublicFarmsCached();
  }

  /// Get public farms with persistent caching
  Future<List<dynamic>> _getPublicFarmsCached() {
    const cacheKey = 'public_farms';
    if (!_globalDataCache.containsKey(cacheKey)) {
      _globalDataCache[cacheKey] = ApiService.getPublicFarms();
    }
    return _globalDataCache[cacheKey]!;
  }

  /// Get crops with persistent caching by farmId
  Future<List<dynamic>> _getCropsCached(int farmId) {
    if (!_globalCropsCache.containsKey(farmId)) {
      _globalCropsCache[farmId] = ApiService.getPublicFarmCrops(farmId);
    }
    return _globalCropsCache[farmId]!;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'FERMES PUBLIQUES',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_outlined,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        onRefresh: () async {
          const farmsCacheKey = 'public_farms';
          _globalDataCache.remove(farmsCacheKey);
          _farmsFuture = _getPublicFarmsCached();
          _searchController.clear();
          _searchQuery = '';
          _globalCropsCache.clear();
          setState(() {});
          imageCache.clearLiveImages();
          imageCache.clear();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildContent(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.12),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                ),
                const SizedBox(height: 24),
                Text(
                  'ERREUR',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 11,
                    letterSpacing: 2.0,
                    color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                  ),
                ),
              ],
            ),
          );
        }

        final farms = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar minimaliste
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher des fermes',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.0,
                    color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: false,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ),

            if (farms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.agriculture_outlined,
                        size: 32,
                        color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'AUCUNE FERME PUBLIQUE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2.0,
                          color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(builder: (context) {
                final query = _searchQuery.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? farms
                    : farms.where((f) {
                        final name = (f['farm_name'] ?? '').toString().toLowerCase();
                        final location = (f['location'] ?? '').toString().toLowerCase();
                        return name.contains(query) || location.contains(query);
                      }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 32,
                            color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'AUCUN RÉSULTAT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                              color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 768 ? 1 : 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final farm = filtered[index] as Map<String, dynamic>;
                    return _buildPublicFarmCard(farm, isDarkMode);
                  },
                );
              }),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildPublicFarmCard(Map<String, dynamic> farm, bool isDarkMode) {
    final farmName = farm['farm_name'] ?? 'Ferme';
    final farmImage = (farm['profile_image_farm'] ?? farm['image_url']) as String?;
    final farmId = (farm['farm_id'] ?? farm['id']) as int?;
    final farmOwnerId = (farm['user_id']) as int?;  // Get farm owner ID
    final location = farm['location'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBg : AppColors.lightBgAlt,
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image - no edit/delete buttons in public view
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: isDarkMode ? AppColors.darkCardBg : AppColors.lightCardBg,
              child: farmImage != null && farmImage.isNotEmpty
                  ? Image.network(
                      farmImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.landscape_outlined,
                            size: 32,
                            color: isDarkMode ? Colors.white12 : Colors.black12,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.landscape_outlined,
                        size: 32,
                        color: isDarkMode ? Colors.white12 : Colors.black12,
                      ),
                    ),
            ),
          ),
          // Info et parcelles
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  // Parcelles dynamiques (with caching)
                  FutureBuilder<List<dynamic>>(
                    future: _getCropsCached(farmId ?? 0),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                minHeight: 1,
                                color: AppColors.accent.withOpacity(0.5),
                                backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ],
                        );
                      }

                      final parcels = snapshot.data ?? [];

                      if (parcels.isEmpty) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParcelScreen(
                                  farmId: farmId ?? 0,
                                  userId: 0,
                                  farmOwnerId: farmOwnerId,

                                  readOnly: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'VOIR PARCELLES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                                color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.87),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PARCELLES (${parcels.length})',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.0,
                              color: isDarkMode ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: parcels.take(3).map((parcel) {
                              final cropName = parcel['crop_name'] ?? 'N/A';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  cropName.length > 12 ? '${cropName.substring(0, 12)}...' : cropName,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF6B8E23),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (parcels.length > 3) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+${parcels.length - 3} autres',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                                color: isDarkMode ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParcelScreen(
                                    farmId: farmId ?? 0,
                                    userId: 0,
                                    farmOwnerId: farmOwnerId,
                                    readOnly: true,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'VOIR TOUT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF6B8E23),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
