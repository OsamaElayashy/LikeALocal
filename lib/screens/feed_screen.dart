import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/place_model.dart';
import '../widgets/place_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _initialized = false;
  String _selectedCity = 'All';

  // All cities + 'All' option at top
  final List<String> _cities = ['All', ...kSupportedCities];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Defer loading until after build is complete to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).loadPlaces();
        }
      });
      _initialized = true;
    }
  }

  // Called when user picks a city from dropdown
  void _onCityChanged(String? city) {
    if (city == null) return;
    setState(() => _selectedCity = city);
    Provider.of<AppProvider>(context, listen: false)
        .setCity(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LikeALocal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          // City dropdown in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF2563EB)),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: _onCityChanged,
                items: _cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),

      // Category filter chips below app bar
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, app, _) {
                if (app.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final places = app.filteredPlaces;
                if (places.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: app.refreshPlaces,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(children: [
                            Icon(Icons.explore_off_outlined,
                                size: 48,
                                color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCity == 'All'
                                  ? 'No places yet'
                                  : 'No places in $_selectedCity yet',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: app.refreshPlaces,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: places.length,
                    itemBuilder: (ctx, i) =>
                        PlaceCard(place: places[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal scrollable category chips
  Widget _buildCategoryChips() {
    const categories = [
      'All',
      'Restaurant',
      'Cafe',
      'Hidden Gem',
      'Park',
      'Museum',
      'Experience',
    ];

    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final selected = app.selectedCategory == categories[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(categories[i]),
                  selected: selected,
                  onSelected: (_) =>
                      app.setCategory(categories[i]),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF6B7280),
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE5E7EB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}