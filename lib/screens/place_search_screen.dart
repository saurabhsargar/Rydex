import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;

class PlacesSearchScreen extends StatefulWidget {
  final String apiKey;

  const PlacesSearchScreen({super.key, required this.apiKey});

  @override
  State<PlacesSearchScreen> createState() => _PlacesSearchScreenState();
}

class _PlacesSearchScreenState extends State<PlacesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places;
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(input);
    });
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions.clear();
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _places.autocomplete(
      input,
      language: 'en',
      components: [Component(Component.country, "in")],
    );

    if (response.isOkay) {
      setState(() {
        _predictions
          ..clear()
          ..addAll(response.predictions);
        _isLoading = false;
      });
    } else {
      setState(() {
        _predictions.clear();
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPlace(Prediction prediction) async {
    final details = await _places.getDetailsByPlaceId(prediction.placeId!);
    final location = details.result.geometry!.location;
    Navigator.pop(context, {
      'description': prediction.description,
      'location': LatLng(location.lat, location.lng),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _searchPlaces('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const LinearProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_predictions.isEmpty && _controller.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No results found.'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    title: Text(prediction.description ?? ''),
                    onTap: () => _selectPlace(prediction),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

