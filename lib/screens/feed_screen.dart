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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LikeALocal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          // City dropdown in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: scheme.primary,
                ),
                style: TextStyle(
                  color: scheme.primary,
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
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCity == 'All'
                                  ? 'No places yet'
                                  : 'No places in $_selectedCity yet',
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant,
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
        final scheme = Theme.of(context).colorScheme;
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
                  backgroundColor: scheme.surfaceContainerLow,
                  selectedColor: scheme.primaryContainer,
                  checkmarkColor: scheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant,
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
