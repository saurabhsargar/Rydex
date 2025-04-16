import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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

class _MapPreviewScreenState extends State<MapPreviewScreen> {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _drawRoute();
  }

  void _setMarkers() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin,
        infoWindow: const InfoWindow(title: 'Leaving From'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: const InfoWindow(title: 'Going To'),
      ),
    ]);
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
          color: Colors.blue,
        ));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  LatLngBounds _getBounds() {
    return LatLngBounds(
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
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (widget.origin.latitude + widget.destination.latitude) / 2,
      (widget.origin.longitude + widget.destination.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 12),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(
                const Duration(milliseconds: 300),
                () {
                  try {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(_getBounds(), 50),
                    );
                  } catch (e) {
                    debugPrint("Camera move error: $e");
                  }
                },
              );
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),
        ],
      ),
    );
  }
}

