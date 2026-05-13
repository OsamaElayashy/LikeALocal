import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';
import 'map_location_picker_screen.dart';

// Fixed category list — easy to add more later
const List<String> kSupportedCategories = [
  'Restaurant',
  'Cafe',
  'Hidden Gem',
  'Park',
  'Museum',
  'Experience',
  'Beach',
  'Shopping',
  'Other',
];

class AddPlaceScreen extends StatefulWidget {
  final Place? existingPlace;
  const AddPlaceScreen({super.key, this.existingPlace});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _localTipController = TextEditingController();

  String _selectedCity = kSupportedCities.first;
  String _selectedCategory = kSupportedCategories.first;

  // Location picked from map
  LatLng? _pickedLocation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPlace;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _imageController.text = existing.imageUrl;
      _localTipController.text = existing.localTip;
      _selectedCity = existing.city;
      _selectedCategory = existing.category;
      _pickedLocation = LatLng(existing.latitude, existing.longitude);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _localTipController.dispose();
    super.dispose();
  }

  // Opens the map location picker screen
  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (ctx) => MapLocationPickerScreen(
          initialLocation: _pickedLocation ??
              _getCityCenter(_selectedCity),
        ),
      ),
    );
    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  // Returns the center coordinates of each supported city
  LatLng _getCityCenter(String city) {
    switch (city) {
      case 'Cairo':
        return const LatLng(30.0444, 31.2357);
      case 'Alexandria':
        return const LatLng(31.2001, 29.9187);
      case 'Giza':
        return const LatLng(30.0131, 31.2089);
      case 'Luxor':
        return const LatLng(25.6872, 32.6396);
      case 'Sharm El Sheikh':
        return const LatLng(27.9158, 34.3300);
      case 'Hurghada':
        return const LatLng(27.2579, 33.8116);
      default:
        return const LatLng(30.0444, 31.2357); // Cairo fallback
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Location is required
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = provider.currentUser;

      final place = Place(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        city: _selectedCity,
        localTip: _localTipController.text.trim(),
        imageUrl: _imageController.text.trim().isEmpty
            ? 'https://via.placeholder.com/800x400.png?text=No+Image'
            : _imageController.text.trim(),
        latitude: _pickedLocation!.latitude,
        longitude: _pickedLocation!.longitude,
        contributorId: currentUser?.id ?? 'unknown',
        contributorName: currentUser?.name ?? 'Anonymous',
        contributorIsSuperUser: currentUser?.isSuperUser ?? false,
        createdAt: DateTime.now(),
      );

      if (widget.existingPlace != null) {
        final updatedPlace = Place(
          id: widget.existingPlace!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          city: _selectedCity,
          localTip: _localTipController.text.trim(),
          imageUrl: _imageController.text.trim().isEmpty
              ? 'https://via.placeholder.com/800x400.png?text=No+Image'
              : _imageController.text.trim(),
          latitude: _pickedLocation!.latitude,
          longitude: _pickedLocation!.longitude,
          contributorId: widget.existingPlace!.contributorId,
          contributorName: widget.existingPlace!.contributorName,
          contributorIsSuperUser: widget.existingPlace!.contributorIsSuperUser,
          createdAt: widget.existingPlace!.createdAt,
          savedBy: widget.existingPlace!.savedBy,
          reviews: widget.existingPlace!.reviews,
        );
        await provider.updatePlace(updatedPlace);
      } else {
        await provider.addPlace(place);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPlace != null ? 'Place updated successfully!' : 'Place added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding place: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add a Place',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Title ──────────────────────────────────
            _sectionLabel('Place Name *'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. El Fishawi Ahwa',
                prefixIcon: Icon(Icons.place_outlined,
                    color: Color(0xFF6B7280), size: 20),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ────────────────────────────
            _sectionLabel('Description *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What makes this place special?',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_outlined,
                      color: Color(0xFF6B7280), size: 20),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── City + Category row ────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('City *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_city_outlined,
                            color: Color(0xFF6B7280), size: 20),
                      ),
                      items: kSupportedCities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCity = value;
                            // Reset location when city changes
                            _pickedLocation = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Category *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined,
                            color: Color(0xFF6B7280), size: 20),
                      ),
                      items: kSupportedCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Location picker ────────────────────────
            _sectionLabel('Location *'),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                height: _pickedLocation != null ? 180 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _pickedLocation != null
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: _pickedLocation != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(children: [
                          // Mini map preview
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _pickedLocation!,
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('picked'),
                                position: _pickedLocation!,
                              ),
                            },
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                          // Tap to change overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_location_alt_outlined,
                                      size: 14,
                                      color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text('Change',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_location_alt_outlined,
                              color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tap to pick location on map',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Image URL ──────────────────────────────
            _sectionLabel('Image URL (optional)'),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined,
                    color: Color(0xFF6B7280), size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // ── Local Tip ──────────────────────────────
            _sectionLabel('Local Tip (optional)'),
            TextFormField(
              controller: _localTipController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Ask for the secret menu item...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.tips_and_updates_outlined,
                      color: Color(0xFF6B7280), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Add Place',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}