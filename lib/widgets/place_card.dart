import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';
import '../screens/place_detail_screen.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<AppProvider>().isPlaceSaved(place.id);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailScreen(place: place),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                place.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(place.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[600], size: 16),
                            const SizedBox(width: 4),
                            Text('${place.rating} (${place.reviewCount})'),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Text('${place.latitude.toStringAsFixed(3)}, ${place.longitude.toStringAsFixed(3)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<AppProvider>().toggleSavePlace(place),
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: Theme.of(context).primaryColor),
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
