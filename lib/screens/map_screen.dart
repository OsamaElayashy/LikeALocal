import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';
import 'place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Place? _selectedPlace;   // currently tapped place (shows popup)
  bool _showingUserLocation = false;

  // City center coordinates
  static const Map<String, LatLng> _cityCenters = {
    'Cairo': LatLng(30.0444, 31.2357),
    'Alexandria': LatLng(31.2001, 29.9187),
    'Giza': LatLng(30.0131, 31.2089),
    'Luxor': LatLng(25.6872, 32.6396),
    'Sharm El Sheikh': LatLng(27.9158, 34.3300),
    'Hurghada': LatLng(27.2579, 33.8116),
  };

  @override
  void initState() {
    super.initState();
    // Load places if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadPlaces();
    });
  }

  // Build markers from places list
  Set<Marker> _buildMarkers(List<Place> places) {
    return places.map((place) {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.latitude, place.longitude),
        // Super user places get a special gold marker
        icon: place.contributorIsSuperUser
            ? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow)
            : BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
        onTap: () {
          setState(() => _selectedPlace = place);
        },
      );
    }).toSet();
  }

  // Move camera to user's GPS location
  Future<void> _goToMyLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );
      setState(() => _showingUserLocation = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not get your location')),
        );
      }
    }
  }

  // Move camera to selected city center
  void _goToCity(String city) {
    final center = _cityCenters[city];
    if (center == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: 13),
      ),
    );
    setState(() => _showingUserLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          // Initial camera — selected city or Cairo default
          final initialCity = app.selectedCity == 'All'
              ? 'Cairo'
              : app.selectedCity;
          final initialTarget =
              _cityCenters[initialCity] ?? _cityCenters['Cairo']!;

          final markers = _buildMarkers(app.places);

          return Stack(
            children: [

              // ── The Map ──────────────────────────────
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) {
                  // Dismiss popup when tapping map background
                  setState(() => _selectedPlace = null);
                },
              ),

              // ── Top bar — city selector ───────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_city_outlined,
                        color: Color(0xFF2563EB), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'View city:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _showingUserLocation
                              ? null
                              : (app.selectedCity == 'All'
                                  ? 'Cairo'
                                  : app.selectedCity),
                          hint: const Text('My location',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600)),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                          items: kSupportedCities
                              .map((city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ))
                              .toList(),
                          onChanged: (city) {
                            if (city != null) _goToCity(city);
                          },
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── My location button ────────────────────
              Positioned(
                bottom: _selectedPlace != null ? 220 : 24,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location,
                      color: Color(0xFF2563EB)),
                ),
              ),

              // ── Place popup card ──────────────────────
              if (_selectedPlace != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _buildPlacePopup(_selectedPlace!),
                ),
            ],
          );
        },
      ),
    );
  }

  // The popup card that appears when a pin is tapped
  Widget _buildPlacePopup(Place place) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Image
          if (place.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: Image.network(
                place.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFFEFF6FF),
                  child: const Icon(Icons.image_outlined,
                      color: Color(0xFF2563EB), size: 40),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      place.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  // Dismiss button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPlace = null),
                    child: const Icon(Icons.close,
                        size: 18, color: Color(0xFF9CA3AF)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      place.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // City
                  Text(
                    place.city,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  // Rating
                  if (place.reviewCount > 0) ...[
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                  // Super user badge
                  if (place.contributorIsSuperUser) ...[
                    const SizedBox(width: 6),
                    const Text('⭐',
                        style: TextStyle(fontSize: 12)),
                  ],
                ]),
                const SizedBox(height: 12),

                // Open detail button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedPlace = null);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) =>
                              PlaceDetailScreen(place: place),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}