import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'dart:async';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final bool showAddressField;
  final Function(LatLng location, String? address)? onLocationSelected;
  final bool enableSearch;
  final bool enableCurrentLocation;
  final double initialZoom;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.showAddressField = true,
    this.onLocationSelected,
    this.enableSearch = true,
    this.enableCurrentLocation = true,
    this.initialZoom = 13.0,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final TextEditingController _searchController;
  late final TextEditingController _addressController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _locationName;
  String? _customAddress;
  bool _isDragging = false;
  Timer? _debounceTimer;
  
  // Résultats de recherche
  List<Map<String, dynamic>> _searchResults = [];
  
  // Historique et suggestions
  List<String> _searchHistory = [];
  static const int maxHistoryItems = 10;
  
  final List<Map<String, dynamic>> _quickSuggestions = const [
    {'name': 'Dakar', 'type': 'Capitale', 'lat': 14.6928, 'lon': -17.0467, 'icon': Icons.location_city},
    {'name': 'Thiès', 'type': 'Région', 'lat': 14.7912, 'lon': -16.9359, 'icon': Icons.location_city},
    {'name': 'Kaolack', 'type': 'Région', 'lat': 14.1652, 'lon': -16.0726, 'icon': Icons.location_city},
    {'name': 'Saint-Louis', 'type': 'Région', 'lat': 16.0179, 'lon': -16.4896, 'icon': Icons.location_city},
    {'name': 'Ziguinchor', 'type': 'Région', 'lat': 12.5642, 'lon': -16.2718, 'icon': Icons.location_city},
  ];

  // Types de cartes disponibles
  final List<Map<String, dynamic>> _mapLayers = [
    {'name': 'Standard', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 'icon': Icons.map},
    {'name': 'Satellite', 'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', 'icon': Icons.satellite},
    {'name': 'Transport', 'url': 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=your_api_key', 'icon': Icons.directions_bus},
  ];
  
  int _selectedLayerIndex = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController(text: widget.initialAddress);
    _addressController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _initializeMap();
    _loadSearchHistory();
    _animationController.forward();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.initialLocation != null) {
        _selectedLocation = widget.initialLocation;
        _locationName = widget.initialAddress ?? await _reverseGeocode(widget.initialLocation!);
        _mapController.move(_selectedLocation!, widget.initialZoom);
      } else if (widget.enableCurrentLocation) {
        final position = await _getCurrentLocation();
        if (position != null && mounted) {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _locationName = await _reverseGeocode(_selectedLocation!);
          _mapController.move(_selectedLocation!, widget.initialZoom);
        }
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      _selectedLocation = const LatLng(14.6928, -17.0467); // Dakar par défaut
      _locationName = 'Dakar, Sénégal';
      _mapController.move(_selectedLocation!, widget.initialZoom);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${location.latitude}&lon=${location.longitude}'
        '&format=json&addressdetails=1'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('{"error": "timeout"}', 500),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? '${location.latitude}, ${location.longitude}';
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPermanentlyDeniedDialog();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service de localisation désactivé'),
        content: const Text('Veuillez activer la localisation pour utiliser cette fonctionnalité.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text('La permission de localisation est nécessaire pour cette fonctionnalité.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission bloquée'),
        content: const Text('La permission de localisation a été définitivement refusée. Veuillez l\'activer dans les paramètres.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _loadSearchHistory() {
    // TODO: Charger depuis SharedPreferences ou base de données
    _searchHistory = [];
  }

  void _saveToHistory(String location) {
    if (!_searchHistory.contains(location)) {
      setState(() {
        _searchHistory.insert(0, location);
        if (_searchHistory.length > maxHistoryItems) {
          _searchHistory.removeLast();
        }
      });
      // TODO: Sauvegarder dans SharedPreferences
    }
  }

  void _onMapTap(LatLng latlng) async {
    setState(() {
      _selectedLocation = latlng;
      _isDragging = false;
    });
    
    final address = await _reverseGeocode(latlng);
    if (mounted) {
      setState(() => _locationName = address);
    }
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture && mounted) {
      setState(() => _isDragging = true);
    }
  }

  void _useLocation() {
    if (_selectedLocation == null) {
      _showErrorSnackBar('Veuillez sélectionner une localisation sur la carte');
      return;
    }
    
    final address = _customAddress ?? _locationName;
    if (address != null) {
      _saveToHistory(address);
    }
    
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(_selectedLocation!, address);
    } else {
      final lat = _selectedLocation!.latitude.toString();
      final lng = _selectedLocation!.longitude.toString();
      Navigator.pop(context, address != null ? '$address|$lat,$lng' : '$lat,$lng');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _searchLocalities(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=10'
        '&countrycodes=sn'
        '&addressdetails=1'
        '&extratags=1'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mbaymi/1.0',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('{"error": "timeout"}', 500),
      );

      if (response.statusCode == 200) {
        final results = (jsonDecode(response.body) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (mounted) {
          setState(() => _searchResults = results);
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() => _searchResults = []);
        _showErrorSnackBar('Erreur de recherche');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResultLocation(Map<String, dynamic> result) {
    try {
      final lat = double.parse(result['lat'].toString());
      final lng = double.parse(result['lon'].toString());
      final location = LatLng(lat, lng);
      final displayName = result['display_name'] ?? 'Localisation sélectionnée';
      
      setState(() {
        _selectedLocation = location;
        _locationName = displayName;
        _searchResults = [];
        _searchController.text = displayName;
      });

      _saveToHistory(displayName);
      
      final zoom = _getZoomForType(result['type'] ?? '');
      _mapController.move(location, zoom);
      
      _showSuccessSnackBar('Localisation trouvée');
    } catch (e) {
      debugPrint('Selection error: $e');
      _showErrorSnackBar('Erreur de sélection');
    }
  }

  double _getZoomForType(String type) {
    switch (type.toLowerCase()) {
      case 'country': return 6.0;
      case 'state': case 'region': return 8.0;
      case 'county': case 'district': return 10.0;
      case 'city': case 'town': return 13.0;
      case 'village': return 14.0;
      default: return 12.0;
    }
  }

  void _selectQuickSuggestion(Map<String, dynamic> suggestion) {
    final location = LatLng(suggestion['lat'], suggestion['lon']);
    final displayName = '${suggestion['name']}, Sénégal';

    setState(() {
      _selectedLocation = location;
      _locationName = displayName;
      _searchResults = [];
      _searchController.text = displayName;
    });

    _saveToHistory(displayName);
    _mapController.move(location, 11.0);
  }

  Future<void> _recenterOnUserLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await _getCurrentLocation();
      if (position != null && mounted) {
        final location = LatLng(position.latitude, position.longitude);
        final address = await _reverseGeocode(location);
        
        setState(() {
          _selectedLocation = location;
          _locationName = address;
          _searchController.text = address ?? '';
        });
        
        _mapController.move(location, 14.0);
        _showSuccessSnackBar('Position actuelle trouvée');
      }
    } catch (e) {
      _showErrorSnackBar('Impossible d\'obtenir votre position');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMapLayer(int index) {
    setState(() => _selectedLayerIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor.withAlpha((0.9 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: textColor),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Sélecteur de couche de carte
          PopupMenuButton<int>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor.withAlpha((0.9 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(_mapLayers[_selectedLayerIndex]['icon'], color: AppColors.primary),
            ),
            onSelected: _changeMapLayer,
            itemBuilder: (context) => List.generate(
              _mapLayers.length,
              (index) => PopupMenuItem(
                value: index,
                child: Row(
                  children: [
                    Icon(_mapLayers[index]['icon'], size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(_mapLayers[index]['name']),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(14.6928, -17.0467),
              initialZoom: widget.initialZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
              onTap: (_, latlng) => _onMapTap(latlng),
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _mapLayers[_selectedLayerIndex]['url'],
                userAgentPackageName: 'com.mbaymi.app',
                maxZoom: 19.0,
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
                                    blurRadius: 10,
                                    spreadRadius: _isDragging ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: _isDragging ? 26 : 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha((0.3 * 255).toInt()),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Barre de recherche (si activée)
          if (widget.enableSearch)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSearchBar(surfaceColor, textColor),
              ),
            ),

          // Bouton de localisation (si activé)
          if (widget.enableCurrentLocation)
            Positioned(
              bottom: 240,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _isLoading ? null : _recenterOnUserLocation,
                backgroundColor: surfaceColor,
                child: Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                ),
              ),
            ),

          // Panneau d'information en bas
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPanel(surfaceColor, textColor),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color surfaceColor, Color textColor) {
    return Column(
      children: [
        // Champ de recherche
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                _searchLocalities(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un lieu...',
              hintStyle: TextStyle(color: textColor.withAlpha((0.5 * 255).toInt())),
              prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textColor, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),

        // Résultats de recherche (scrollable)
        if (_searchResults.isNotEmpty || _searchHistory.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _searchResults.isNotEmpty
                ? _buildSearchResults(textColor)
                : _buildSuggestions(textColor),
          ),
      ],
    );
  }

  Widget _buildSearchResults(Color textColor) {
    return SingleChildScrollView(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withAlpha((0.1 * 255).toInt())),
        itemBuilder: (_, idx) {
          final result = _searchResults[idx];
          final type = result['type'] ?? 'lieu';
          final importance = (result['importance'] ?? 0.0) as num;
          
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withAlpha((0.08 * 255).toInt()),
              child: Icon(
                _getIconForType(type),
                color: AppColors.primary,
                size: 18,
              ),
            ),
            title: Text(
              result['name'] ?? result['display_name']?.split(',').first ?? 'Lieu',
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
            ),
            subtitle: Text(
              result['display_name'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withAlpha((0.5 * 255).toInt()),
              ),
            ),
            trailing: importance > 0.5
                ? Icon(Icons.star, color: Colors.amber.shade600, size: 14)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            onTap: () => _selectResultLocation(result),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions(Color textColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: AppColors.primary.withAlpha((0.6 * 255).toInt())),
                  const SizedBox(width: 8),
                  Text(
                    'Récent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor.withAlpha((0.5 * 255).toInt()),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            ..._searchHistory.map((history) => ListTile(
              leading: Icon(Icons.history, color: AppColors.primary.withAlpha((0.4 * 255).toInt()), size: 16),
              title: Text(history, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              onTap: () {
                _searchController.text = history;
                _searchLocalities(history);
              },
            )),
            Divider(height: 8, color: textColor.withAlpha((0.08 * 255).toInt())),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: AppColors.primary.withAlpha((0.6 * 255).toInt())),
                const SizedBox(width: 8),
                Text(
                  'Régions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor.withAlpha((0.5 * 255).toInt()),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ..._quickSuggestions.map((suggestion) => ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withAlpha((0.08 * 255).toInt()),
              child: Icon(suggestion['icon'], color: AppColors.primary, size: 14),
            ),
            title: Text(suggestion['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            subtitle: Text(suggestion['type'], style: TextStyle(fontSize: 11, color: textColor.withAlpha((0.5 * 255).toInt()))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            onTap: () => _selectQuickSuggestion(suggestion),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(Color surfaceColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 4,
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: textColor.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: textColor.withAlpha((0.5 * 255).toInt()),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _locationName ?? 'Chargement...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha((0.06 * 255).toInt()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: AppColors.primary),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '${_selectedLocation!.latitude},${_selectedLocation!.longitude}'),
                        );
                        _showSuccessSnackBar('Coordonnées copiées');
                      },
                      tooltip: 'Copier',
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                if (widget.showAddressField) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Adresse personnalisée (optionnel)',
                      hintStyle: TextStyle(fontSize: 13, color: textColor.withAlpha((0.4 * 255).toInt())),
                      prefixIcon: Icon(Icons.edit_location_alt, color: AppColors.primary, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: textColor.withAlpha((0.15 * 255).toInt())),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: textColor.withAlpha((0.15 * 255).toInt())),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (value) => _customAddress = value,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _useLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Confirmer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
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

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
        return Icons.location_city;
      case 'village':
        return Icons.location_city;
      case 'road':
        return Icons.directions;
      case 'restaurant':
        return Icons.restaurant;
      case 'school':
        return Icons.school;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.place;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}