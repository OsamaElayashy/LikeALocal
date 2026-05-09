import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/place_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final saved = app.savedPlaces;
          if (saved.isEmpty) return const Center(child: Text('No bookmarks yet'));
          return ListView.builder(
            itemCount: saved.length,
            itemBuilder: (ctx, i) => PlaceCard(place: saved[i]),
          );
        },
      ),
    );
  }
}
