import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _locationName;
  
  // Résultats de recherche
  List<Map<String, dynamic>> _searchResults = [];
  
  // Débounce pour la recherche
  Future<void>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Demander la localisation de l'utilisateur
      final position = await _getCurrentLocation();
      if (position != null && mounted) {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation!, 13.0);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Défaut: Dakar, Sénégal (point central)
      _selectedLocation = const LatLng(14.6928, -17.0469);
      _mapController.move(_selectedLocation!, 12.0);
      if (mounted) setState(() {});
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error in getCurrentLocation: $e');
      return null;
    }
  }

  void _onMapTap(LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
      _locationName = '${latlng.latitude.toStringAsFixed(6)}, ${latlng.longitude.toStringAsFixed(6)}';
    });
  }

  void _useLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une localisation sur la carte')),
      );
      return;
    }
    
    final lat = _selectedLocation!.latitude.toString();
    final lng = _selectedLocation!.longitude.toString();
    Navigator.pop(context, '$lat,$lng');
  }

  void _recenterOnUserLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await _getCurrentLocation();
      if (position != null && mounted) {
        final location = LatLng(position.latitude, position.longitude);
        _mapController.move(location, 13.0);
        setState(() => _selectedLocation = location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Recherche des localités via Nominatim OpenStreetMap
  Future<void> _searchLocalities(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&limit=8'
        '&countrycodes=sn' // Limiter au Sénégal
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('{"error": "timeout"}', 500),
      );

      if (response.statusCode == 200) {
        final results = (jsonDecode(response.body) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (mounted) {
          setState(() => _searchResults = results);
        }
      } else {
        if (mounted) {
          setState(() => _searchResults = []);
        }
      }
    } catch (e) {
      debugPrint('Error searching localities: $e');
      if (mounted) {
        setState(() => _searchResults = []);
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Sélectionner une localité depuis les résultats
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
        _searchController.clear();
      });

      // Déplacer la carte vers cette localisation
      _mapController.move(location, 13.0);
    } catch (e) {
      debugPrint('Error selecting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.lightBg,
        elevation: 0,
        title: const Text('Sélectionner la localisation'),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Carte FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(14.6928, -17.0469),
              initialZoom: 12.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              onTap: (_, latlng) => _onMapTap(latlng),
            ),
            children: [
              // TileLayer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mbaymi.app',
                maxZoom: 19.0,
              ),
              // Marqueur pour la localisation sélectionnée
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80.0,
                      height: 80.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((0.3 * 255).toInt()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Croix au centre (avant de taper)
          Center(
            child: Icon(
              Icons.add_circle_outline,
              size: 48,
              color: AppColors.primary.withAlpha((0.5 * 255).toInt()),
            ),
          ),
          
          // SEARCH BOX EN HAUT
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Champ de recherche
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.15 * 255).toInt()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Debounce la recherche
                      _searchFuture?.ignore();
                      _searchFuture = Future.delayed(
                        const Duration(milliseconds: 500),
                        () => _searchLocalities(value),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une localité...',
                      hintStyle: TextStyle(color: textColor.withAlpha((0.5 * 255).toInt())),
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                              child: Icon(Icons.close, color: textColor.withAlpha((0.7 * 255).toInt())),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                ),
                
                // Résultats de recherche
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.15 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.1 * 255).toInt()),
                      ),
                      itemBuilder: (_, idx) {
                        final result = _searchResults[idx];
                        final displayName = result['display_name'] ?? 'Localité inconnue';
                        final type = result['type'] ?? '';
                        
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          title: Text(
                            displayName.length > 60 ? '${displayName.substring(0, 60)}...' : displayName,
                            style: TextStyle(fontSize: 12, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            type,
                            style: TextStyle(fontSize: 10, color: textColor.withAlpha((0.6 * 255).toInt())),
                          ),
                          onTap: () => _selectResultLocation(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Info box en bas avec coordonnées
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Localisation sélectionnée',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: textColor.withAlpha((0.7 * 255).toInt())),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _locationName ?? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_copy, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coordonnées copiées')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _useLocation,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmer cette localisation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bouton pour ma localisation (en haut à droite)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _isLoading ? null : _recenterOnUserLocation,
              backgroundColor: AppColors.primary,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
