import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MapPreviewScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String apiKey;

  const MapPreviewScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.apiKey,
  });

  @override
  State<MapPreviewScreen> createState() => _MapPreviewScreenState();
}

class _MapPreviewScreenState extends State<MapPreviewScreen> with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _showDetails = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _setMarkers();
    _drawRoute();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setMarkers() {
    // Custom marker icons
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/origin_marker.png',
    ).then((icon) {
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin,
          infoWindow: const InfoWindow(title: 'Leaving From'),
          icon: icon,
        ));
      });
    }).catchError((_) {
      // Fallback to default marker if custom icon fails
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin,
          infoWindow: const InfoWindow(title: 'Leaving From'),
        ));
      });
    });

    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/destination_marker.png',
    ).then((icon) {
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination,
          infoWindow: const InfoWindow(title: 'Going To'),
          icon: icon,
        ));
      });
    }).catchError((_) {
      // Fallback to default marker if custom icon fails
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination,
          infoWindow: const InfoWindow(title: 'Going To'),
        ));
      });
    });
  }

  Future<void> _drawRoute() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      widget.apiKey,
      PointLatLng(widget.origin.latitude, widget.origin.longitude),
      PointLatLng(widget.destination.latitude, widget.destination.longitude),
    );

    if (result.points.isNotEmpty) {
      final polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          width: 5,
          color: Colors.teal.shade600,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ));
        _isLoading = false;
      });
      
      // Animate the details panel after route is drawn
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showDetails = true;
        });
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.origin.latitude < widget.destination.latitude
            ? widget.origin.latitude
            : widget.destination.latitude,
        widget.origin.longitude < widget.destination.longitude
            ? widget.origin.longitude
            : widget.destination.longitude,
      ),
      northeast: LatLng(
        widget.origin.latitude > widget.destination.latitude
            ? widget.origin.latitude
            : widget.destination.latitude,
        widget.origin.longitude > widget.destination.longitude
            ? widget.origin.longitude
            : widget.destination.longitude,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (widget.origin.latitude + widget.destination.latitude) / 2,
                (widget.origin.longitude + widget.destination.longitude) / 2,
              ),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(
                const Duration(milliseconds: 300),
                () => _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50)),
              );
              
              // Apply custom map style
              controller.setMapStyle('''
                [
                  {
                    "featureType": "water",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#e9e9e9"
                      },
                      {
                        "lightness": 17
                      }
                    ]
                  },
                  {
                    "featureType": "landscape",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#f5f5f5"
                      },
                      {
                        "lightness": 20
                      }
                    ]
                  },
                  {
                    "featureType": "road.highway",
                    "elementType": "geometry.fill",
                    "stylers": [
                      {
                        "color": "#ffffff"
                      },
                      {
                        "lightness": 17
                      }
                    ]
                  },
                  {
                    "featureType": "road.highway",
                    "elementType": "geometry.stroke",
                    "stylers": [
                      {
                        "color": "#ffffff"
                      },
                      {
                        "lightness": 29
                      },
                      {
                        "weight": 0.2
                      }
                    ]
                  },
                  {
                    "featureType": "road.arterial",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#ffffff"
                      },
                      {
                        "lightness": 18
                      }
                    ]
                  },
                  {
                    "featureType": "road.local",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#ffffff"
                      },
                      {
                        "lightness": 16
                      }
                    ]
                  },
                  {
                    "featureType": "poi",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#f5f5f5"
                      },
                      {
                        "lightness": 21
                      }
                    ]
                  },
                  {
                    "featureType": "poi.park",
                    "elementType": "geometry",
                    "stylers": [
                      {
                        "color": "#dedede"
                      },
                      {
                        "lightness": 21
                      }
                    ]
                  }
                ]
              ''');
            },
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          
          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.teal.shade700),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .moveX(begin: -20, end: 0),
            ),
          ),
          
          // Loading Indicator
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.teal.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Loading route...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Route Details Panel
          if (_showDetails)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.route,
                              color: Colors.teal.shade700,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Route Preview",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your journey from origin to destination",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.green.shade600,
                                size: 16,
                              ),
                              Container(
                                width: 2,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              Icon(
                                Icons.location_on,
                                color: Colors.red.shade600,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Origin",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your starting point",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Destination",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your end point",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Confirm Route",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(controller: _animationController)
              .fadeIn(duration: 400.ms)
              .moveY(begin: 100, end: 0, curve: Curves.easeOutQuad),
            ),
          
          // My Location Button
          Positioned(
            right: 29,
            bottom: _showDetails ? 240 : 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: Colors.teal.shade700),
                onPressed: () {
                  _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}