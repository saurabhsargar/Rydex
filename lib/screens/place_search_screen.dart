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
  List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: '');
  // late GoogleMapsPlaces _places;

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
  }

  void _searchPlaces(String input) async {
    if (input.isEmpty) return;

    final response = await _places.autocomplete(
      input,
      language: 'en',
      components: [Component(Component.country, "in")],
    );

    if (response.isOkay) {
      setState(() {
        _predictions = response.predictions;
      });
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _selectPlace(Prediction prediction) async {
    final details = await _places.getDetailsByPlaceId(prediction.placeId!);
    final location = details.result.geometry!.location;
    final result = {
      'description': prediction.description,
      'lat': location.lat,
      'lng': location.lng,
    };
    Navigator.pop(context, {
      'description': prediction.description,
      'location': LatLng(location.lat, location.lng),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Location')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchPlaces,
            ),
            const SizedBox(height: 10),
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
