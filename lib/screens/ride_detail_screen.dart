import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ride;
  final String rideId;

  const RideDetailScreen({super.key, required this.ride, required this.rideId});

  Future<void> bookRide(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      // Create a booking in the separate 'bookings' collection
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'rideId': rideId,
        // 'userId': user.uid,
        'from': ride['from'],
        'to': ride['to'],
        'date': ride['date'],
        'time': ride['time'],
        'driverName': ride['driverName'],
        'phone': ride['phone'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Optionally: Notify the driver
      if (ride['driverId'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ride['driverId'])
            .collection('notifications')
            .add({
          'type': 'booking',
          'message': '${user.displayName ?? 'A user'} booked your ride.',
          'rideId': rideId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride booked successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${ride['from']} → ${ride['to']}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (ride['date'] != null) Text("Date: ${ride['date']}"),
                if (ride['time'] != null) Text("Time: ${ride['time']}"),
                if (ride['seats'] != null) Text("Available Seats: ${ride['seats']}"),
                if (ride['driverName'] != null) Text("Driver: ${ride['driverName']}"),
                if (ride['phone'] != null) Text("Contact: ${ride['phone']}"),
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => bookRide(context),
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Book Ride"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
