import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              place.imageUrl,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => Container(
                height: 260,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600]),
                      const SizedBox(width: 6),
                      Text('${place.rating} • ${place.reviewCount} reviews'),
                      const Spacer(),
                      Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text('${place.latitude.toStringAsFixed(3)}, ${place.longitude.toStringAsFixed(3)}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(place.description),
                  const SizedBox(height: 12),
                  if (place.localTip.isNotEmpty) ...[
                    const Text('Local tip', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(place.localTip),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(context),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Leave a rating'),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...place.reviews.reversed.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('${r.userName} • ${r.score}/5'),
                          subtitle: Text(r.comment),
                          trailing: Text(r.createdAt.toLocal().toString().split(' ').first),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double value = 4.0;
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate this place'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${value.toStringAsFixed(1)} / 5'),
                Slider(
                  value: value,
                  min: 1,
                  max: 5,
                  divisions: 8,
                  label: value.toStringAsFixed(1),
                  onChanged: (v) => setState(() => value = v),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Optional comment'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
              Provider.of<AppProvider>(context, listen: false).addRating(
                place.id,
                value,
                commentController.text.trim(),
                userId: currentUser?.id,
                userName: currentUser?.name,
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
