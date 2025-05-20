import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlacesSearchScreen extends StatefulWidget {
  final String apiKey;

  const PlacesSearchScreen({super.key, required this.apiKey});

  @override
  State<PlacesSearchScreen> createState() => _PlacesSearchScreenState();
}

class _PlacesSearchScreenState extends State<PlacesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
  }

  void _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final response = await _places.autocomplete(
      input,
      language: 'en',
      components: [Component(Component.country, "in")],
    );

    setState(() {
      _isSearching = false;
      if (response.isOkay) {
        _predictions = response.predictions;
      } else {
        _predictions = [];
      }
    });
  }

  void _selectPlace(Prediction prediction) async {
    setState(() {
      _isSearching = true;
    });

    final details = await _places.getDetailsByPlaceId(prediction.placeId!);
    
    setState(() {
      _isSearching = false;
    });
    
    if (details.isOkay) {
      final location = details.result.geometry!.location;
      Navigator.pop(context, {
        'description': prediction.description,
        'location': LatLng(location.lat, location.lng),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.teal.shade50],
            stops: const [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.teal.shade700),
                        onPressed: () => Navigator.pop(context),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .moveX(begin: -20, end: 0),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Text(
                        "Search Location",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 100.ms)
                      .moveY(begin: -10, end: 0),
                    ),
                  ],
                ),
              ),
              
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search places...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade600),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _predictions = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: _searchPlaces,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .moveY(begin: -20, end: 0),
              ),
              
              const SizedBox(height: 16),
              
              // Loading Indicator
              if (_isSearching)
                Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.teal.shade600,
                    ),
                  ),
                ),
              
              // Results List
              Expanded(
                child: _predictions.isEmpty && !_isSearching
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_searching,
                              size: 80,
                              color: Colors.teal.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Search for a location",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _predictions.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                              title: Text(
                                prediction.structuredFormatting?.mainText ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                prediction.structuredFormatting?.secondaryText ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () => _selectPlace(prediction),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 50 * index),
                          )
                          .moveY(begin: 20, end: 0);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}