import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rydex/screens/map_preview.dart';
import 'package:rydex/screens/place_search_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  LatLng? leavingFromLatLng;
  LatLng? goingToLatLng;
  bool _isPublishing = false;
  late AnimationController _animationController;

  final String googleMapsApiKey = ''; //Your API Key

  final TextEditingController leavingFromController = TextEditingController();
  final TextEditingController goingToController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController seatsAvailableController =
      TextEditingController();
  final TextEditingController fareController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to check if similar ride exists
  Future<bool> _checkIfSimilarRideExists() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    // Format date and time for comparison
    final dateString = selectedDate?.toIso8601String();
    final timeString = selectedTime?.format(context);

    final rideQuery =
        await FirebaseFirestore.instance
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
      'userId': FirebaseAuth.instance.currentUser?.uid,
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
      'fare': double.parse(fareController.text), // Add fare field
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.teal.shade50],
            stops: const [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                        "Publish a Ride",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms)
                      .moveY(begin: -20, end: 0),

                  const SizedBox(height: 8),

                  Text(
                        "Share your journey with others",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms, delay: 200.ms)
                      .moveY(begin: -20, end: 0),

                  const SizedBox(height: 30),

                  // Ride Form
                  Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Leaving From Field
                            Text(
                              "LEAVING FROM",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => PlacesSearchScreen(
                                              apiKey: googleMapsApiKey,
                                            ),
                                      ),
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        leavingFromController.text =
                                            result['description'];
                                        leavingFromLatLng = result['location'];
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        controller: leavingFromController,
                                        decoration: InputDecoration(
                                          hintText: "Enter departure location",
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.teal.shade600,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.my_location,
                                              color: Colors.teal.shade600,
                                            ),
                                            onPressed: _getCurrentLocation,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 15,
                                              ),
                                        ),
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? "Enter departure location"
                                                    : null,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            // Going To Field
                            Text(
                              "GOING TO",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => PlacesSearchScreen(
                                              apiKey: googleMapsApiKey,
                                            ),
                                      ),
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        goingToController.text =
                                            result['description'];
                                        goingToLatLng = result['location'];
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        controller: goingToController,
                                        decoration: InputDecoration(
                                          hintText: "Enter destination",
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.teal.shade600,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 15,
                                              ),
                                        ),
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? "Enter destination"
                                                    : null,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            // Date Field
                            Text(
                              "DATE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.teal.shade600,
                                              onPrimary: Colors.white,
                                              onSurface: Colors.black,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (date != null) {
                                      setState(() => selectedDate = date);
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          hintText:
                                              selectedDate == null
                                                  ? "Select date"
                                                  : DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(selectedDate!),
                                          hintStyle: TextStyle(
                                            color:
                                                selectedDate == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                            color: Colors.teal.shade600,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 15,
                                              ),
                                        ),
                                        validator:
                                            (value) =>
                                                selectedDate == null
                                                    ? "Select a date"
                                                    : null,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            // Time Field
                            Text(
                              "TIME",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.teal.shade600,
                                              onPrimary: Colors.white,
                                              onSurface: Colors.black,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      setState(() => selectedTime = time);
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          hintText:
                                              selectedTime == null
                                                  ? "Select time"
                                                  : selectedTime!.format(
                                                    context,
                                                  ),
                                          hintStyle: TextStyle(
                                            color:
                                                selectedTime == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.access_time,
                                            color: Colors.teal.shade600,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 15,
                                              ),
                                        ),
                                        validator:
                                            (value) =>
                                                selectedTime == null
                                                    ? "Select a time"
                                                    : null,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            // Car Model Field
                            Text(
                              "CAR MODEL",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    controller: carModelController,
                                    decoration: InputDecoration(
                                      hintText: "Enter car model (optional)",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.directions_car_outlined,
                                        color: Colors.teal.shade600,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                    ),
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            // Seats Available Field
                            Text(
                              "SEATS AVAILABLE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    controller: seatsAvailableController,
                                    decoration: InputDecoration(
                                      hintText: "Enter number of seats",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.event_seat_outlined,
                                        color: Colors.teal.shade600,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return "Enter number of seats";
                                      final seats = int.tryParse(value);
                                      if (seats == null ||
                                          seats < 1 ||
                                          seats > 8) {
                                        return "Enter a valid seat count (1-8)";
                                      }
                                      return null;
                                    },
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),

                            const SizedBox(height: 20),

                            Text(
                              "FARE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    controller: fareController,
                                    decoration: InputDecoration(
                                      hintText: "Enter fare amount",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: Colors.teal.shade600,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return "Enter fare amount";
                                      final fare = double.tryParse(value);
                                      if (fare == null || fare < 0) {
                                        return "Enter a valid fare amount";
                                      }
                                      return null;
                                    },
                                  ),
                                )
                                .animate(controller: _animationController)
                                .fadeIn(duration: 200.ms, delay: 200.ms)
                                .moveX(begin: -20, end: 0),
                          ],
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      // Preview Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text("Preview Route"),
                          onPressed: () {
                            if (leavingFromLatLng == null ||
                                goingToLatLng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Please select both locations",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  margin: const EdgeInsets.all(10),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.teal.shade200),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Publish Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon:
                              _isPublishing
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.publish),
                          label: Text(
                            _isPublishing ? "Publishing..." : "Publish Ride",
                          ),
                          onPressed:
                              _isPublishing
                                  ? null
                                  : () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (leavingFromLatLng == null ||
                                          goingToLatLng == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Please select both locations",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.redAccent,
                                            margin: const EdgeInsets.all(10),
                                          ),
                                        );
                                        return;
                                      }

                                      if (selectedDate == null ||
                                          selectedTime == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Please select date and time",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.redAccent,
                                            margin: const EdgeInsets.all(10),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _isPublishing = true;
                                      });

                                      try {
                                        // First check if a similar ride exists
                                        final similarRideExists =
                                            await _checkIfSimilarRideExists();

                                        if (similarRideExists) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "You've already published a ride with the same route, date and time",
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              backgroundColor: Colors.orange,
                                              margin: const EdgeInsets.all(10),
                                            ),
                                          );
                                        } else {
                                          // No similar ride exists, proceed with upload
                                          await _uploadRideToFirebase();

                                          // Show success animation
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder:
                                                (context) => Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          20,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          color: Colors.green,
                                                          size: 80,
                                                        ).animate().scale(
                                                          duration: 200.ms,
                                                          curve: Curves.easeOut,
                                                          begin: const Offset(
                                                            0.5,
                                                            0.5,
                                                          ),
                                                          end: const Offset(
                                                            1,
                                                            1,
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          height: 20,
                                                        ),

                                                        const Text(
                                                          "Ride Published Successfully",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          height: 20,
                                                        ),

                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .teal
                                                                    .shade600,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      30,
                                                                  vertical: 12,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            "OK",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                          );

                                          // Clear form after successful submission (optional)
                                          // _formKey.currentState!.reset();
                                        }
                                      } catch (e) {
                                        debugPrint(
                                          "Error with ride publication: $e",
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Failed to publish ride",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.red,
                                            margin: const EdgeInsets.all(10),
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          _isPublishing = false;
                                        });
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate(controller: _animationController).fadeIn(duration: 200.ms, delay: 200.ms).moveY(begin: 20, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
