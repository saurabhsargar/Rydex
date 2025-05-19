import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/ride_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String from;
  final String to;
  final DateTime? date;
  final int persons;
  final String? userId;

  const SearchResultScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.persons,
    required this.userId,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late Future<List<Map<String, dynamic>>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = _fetchMatchingRides();
  }

  Future<List<Map<String, dynamic>>> _fetchMatchingRides() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('rides')
            .where('from', isEqualTo: widget.from)
            .where('to', isEqualTo: widget.to)
            .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final rideDateStr = data['date'] as String?;
          final rideDate =
              rideDateStr != null ? DateTime.tryParse(rideDateStr) : null;

          // Consistently use 'seats_available' field for available seats
          final seatsAvailable = data['seats_available'] ?? 0;
          
          // Optional: Exclude user's own rides
          // final isNotSelfRide = data['userId'] != widget.userId;

          return rideDate != null &&
              rideDate.year == widget.date?.year &&
              rideDate.month == widget.date?.month &&
              rideDate.day == widget.date?.day &&
              seatsAvailable >= widget.persons;
              // isNotSelfRide; // Uncomment to exclude self rides
        })
        .map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Rides")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No matching rides found."));
          }

          final rides = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = rides[index];
              final seatsAvailable = ride['seats_available'] ?? 0;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text("${ride['from']} → ${ride['to']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ride['date'] != null)
                        Text(
                          "Date: ${ride['date']}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      if (ride['time'] != null)
                        Text(
                          "Time: ${ride['time']}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      Text(
                        "Available Seats: $seatsAvailable",
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (ride['driverName'] != null)
                        Text(
                          "Driver: ${ride['driverName']}",
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _bookRide(context, ride),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _bookRide(BuildContext context, Map<String, dynamic> ride) async {
    final int seatsAvailable = ride['seats_available'] ?? 0;
    final int requestedSeats = widget.persons;

    // Early validation to improve UX
    if (seatsAvailable < requestedSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not enough seats available for your request."),
        ),
      );
      return;
    }
    print('----------------------------Available Seats: ${seatsAvailable}');
    print('-----------------------------------Requested Seats: ${requestedSeats}');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use a transaction to ensure atomicity and prevent race conditions
      final rideRef = FirebaseFirestore.instance.collection('rides').doc(ride['id']);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the latest document to ensure we have current seat availability
        final DocumentSnapshot rideSnapshot = await transaction.get(rideRef);
        
        if (!rideSnapshot.exists) {
          throw Exception("Ride no longer exists");
        }
        
        final rideData = rideSnapshot.data() as Map<String, dynamic>;
        final currentSeatsAvailable = rideData['seats_available'] ?? 0;
        
        // Re-validate with the latest data
        if (currentSeatsAvailable < requestedSeats) {
          throw Exception("Not enough seats available");
        }
        
        // Update the seats_available field
        transaction.update(rideRef, {
          'seats_available': currentSeatsAvailable - requestedSeats,
        });
      });
      
      // Create the booking record after successful seat update
      await FirebaseFirestore.instance.collection('bookings').add({
        'rideId': ride['id'],
        'userId': widget.userId,
        'from': widget.from,
        'to': widget.to,
        'date': widget.date != null ? DateFormat('yyyy-MM-dd').format(widget.date!) : null,
        'persons': requestedSeats,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context).pop();
      
      // Navigate to ride details with updated seat count
      final updatedRide = {...ride, 'seats_available': seatsAvailable - requestedSeats};
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideDetailScreen(
            ride: updatedRide,
            rideId: ride['id'],
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book ride: ${e.toString()}")),
      );
    }
  }
}