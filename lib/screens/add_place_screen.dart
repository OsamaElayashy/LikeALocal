import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place_model.dart';
import '../providers/app_provider.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _category = TextEditingController();
  final _localTip = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _image.dispose();
    _lat.dispose();
    _lng.dispose();
    _category.dispose();
    _localTip.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final place = Place(
      id: id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
      localTip: _localTip.text.trim(),
      imageUrl: _image.text.trim().isEmpty
          ? 'https://via.placeholder.com/800x400.png?text=No+Image'
          : _image.text.trim(),
      latitude: double.tryParse(_lat.text) ?? 0.0,
      longitude: double.tryParse(_lng.text) ?? 0.0,
      contributorId: 'local_user',
      contributorName: 'Local User',
      createdAt: DateTime.now(),
    );

    Provider.of<AppProvider>(context, listen: false).addPlace(place);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Place')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v==null||v.isEmpty? 'Required':null),
              const SizedBox(height: 8),
              TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 8),
              TextFormField(controller: _image, decoration: const InputDecoration(labelText: 'Image URL')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _lat, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _lng, decoration: const InputDecoration(labelText: 'Longitude'))),
              ]),
              const SizedBox(height: 8),
              TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 8),
              TextFormField(controller: _localTip, decoration: const InputDecoration(labelText: 'Local Tip')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Add Place')),
            ],
          ),
        ),
      ),
    );
  }
}
