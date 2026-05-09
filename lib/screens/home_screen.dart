import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/place_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // load places once when the screen is first built
      Provider.of<AppProvider>(context, listen: false).loadPlaces();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/bookmarks'),
            icon: const Icon(Icons.bookmark),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final places = app.filteredPlaces;
          if (app.isLoading) return const Center(child: CircularProgressIndicator());
          if (places.isEmpty) {
            return RefreshIndicator(
              onRefresh: app.refreshPlaces,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Center(child: Padding(padding: EdgeInsets.only(top: 80), child: Text('No places yet')))],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: app.refreshPlaces,
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (ctx, i) => PlaceCard(place: places[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/add-place'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
