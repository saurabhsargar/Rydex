import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rydex/screens/map_preview.dart';
import 'package:rydex/screens/place_search_screen.dart';
import 'package:geolocator/geolocator.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  final _formKey = GlobalKey<FormState>();
  LatLng? leavingFromLatLng;
  LatLng? goingToLatLng;
  bool _isPublishing = false; // Add loading state

  final String googleMapsApiKey =
      'AIzaSyCDYtA7aiWr5_Xni4Q6JLrC27xpCk1VKSM'; // Replace with your actual key

  final TextEditingController leavingFromController = TextEditingController();
  final TextEditingController goingToController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController seatsAvailableController =
      TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Function to check if similar ride exists
  Future<bool> _checkIfSimilarRideExists() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    
    // Format date and time for comparison
    final dateString = selectedDate?.toIso8601String();
    final timeString = selectedTime?.format(context);
    
    final rideQuery = await FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: userId)
        .where('from', isEqualTo: leavingFromController.text)
        .where('to', isEqualTo: goingToController.text)
        .where('date', isEqualTo: dateString)
        .where('time', isEqualTo: timeString)
        .limit(1)
        .get();
    
    return rideQuery.docs.isNotEmpty;
  }

  Future<void> _uploadRideToFirebase() async {
    final rideData = {
      'userId': FirebaseAuth.instance.currentUser?.uid, // Store the userId
      'from': leavingFromController.text,
      'from_location': {
        'lat': leavingFromLatLng!.latitude,
        'lng': leavingFromLatLng!.longitude,
      },
      'to': goingToController.text,
      'to_location': {
        'lat': goingToLatLng!.latitude,
        'lng': goingToLatLng!.longitude,
      },
      'date': selectedDate?.toIso8601String(),
      'time': selectedTime?.format(context),
      'car_model': carModelController.text,
      'seats_available': int.parse(seatsAvailableController.text),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('rides').add(rideData);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);

    setState(() {
      leavingFromLatLng = latLng;
      leavingFromController.text = "Current Location";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Publish a Ride",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      leavingFromController.text = result['description'];
                      leavingFromLatLng = result['location'];
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: leavingFromController,
                    decoration: InputDecoration(
                      labelText: "Leaving From",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? "Enter departure location" : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      goingToController.text = result['description'];
                      goingToLatLng = result['location'];
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: goingToController,
                    decoration: const InputDecoration(
                      labelText: "Going To",
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) => value!.isEmpty ? "Enter destination" : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText:
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => selectedDate == null ? "Select a date" : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText:
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => selectedTime == null ? "Select a time" : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: carModelController,
                decoration: const InputDecoration(
                  labelText: "Car Model (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: seatsAvailableController,
                decoration: const InputDecoration(
                  labelText: "Seats Available",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Enter number of seats";
                  final seats = int.tryParse(value);
                  if (seats == null || seats < 1 || seats > 8) {
                    return "Enter a valid seat count (1-8)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Center(
                child: ElevatedButton.icon(
                  icon: _isPublishing 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(_isPublishing ? "Publishing..." : "Publish Ride"),
                  onPressed: _isPublishing 
                      ? null // Disable button while publishing
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (leavingFromLatLng == null || goingToLatLng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select both locations"),
                                ),
                              );
                              return;
                            }
                            
                            if (selectedDate == null || selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select date and time"),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isPublishing = true;
                            });

                            try {
                              // First check if a similar ride exists
                              final similarRideExists = await _checkIfSimilarRideExists();
                              
                              if (similarRideExists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("You've already published a ride with the same route, date and time"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                // No similar ride exists, proceed with upload
                                await _uploadRideToFirebase();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Ride Published Successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                
                                // Clear form after successful submission (optional)
                                // _formKey.currentState!.reset();
                              }
                            } catch (e) {
                              debugPrint("Error with ride publication: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to publish ride"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() {
                                _isPublishing = false;
                              });
                            }
                          }
                        },
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text("Preview"),
                  onPressed: () {
                    if (leavingFromLatLng == null || goingToLatLng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select both locations"),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MapPreviewScreen(
                              origin: leavingFromLatLng!,
                              destination: goingToLatLng!,
                              apiKey: googleMapsApiKey,
                            ),
                      ),
                    );
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