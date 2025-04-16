import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YourRidesScreen extends StatelessWidget {
  const YourRidesScreen({super.key});

  Future<Map<String, List<Map<String, dynamic>>>> fetchRides() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final publishedSnapshot =
        await FirebaseFirestore.instance
            .collection('rides')
            .where('userId', isEqualTo: uid)
            // .orderBy('date', descending: true)
            .get();

    final bookedSnapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            // .orderBy('timestamp', descending: true)
            .get();

    final published = publishedSnapshot.docs.map((doc) => doc.data()).toList();
    final booked = bookedSnapshot.docs.map((doc) => doc.data()).toList();

    return {'published': published, 'booked': booked};
  }

  Widget buildRideCard(Map<String, dynamic> ride, {required bool isPublished}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isPublished ? Icons.directions_car_filled : Icons.directions_car,
          color: isPublished ? Colors.indigo : Colors.green,
        ),
        title: Text(
          "${ride['from']} → ${ride['to']}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ride['date'] != null && ride['time'] != null)
              Text("Date: ${ride['date']} • Time: ${ride['time']}"),
            if (ride['seats'] != null) Text("Seats: ${ride['seats']}"),
            if (ride['driverName'] != null)
              Text("Driver: ${ride['driverName']}"),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Rides")),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: fetchRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No rides found."));
          }

          final published = snapshot.data!['published']!;
          final booked = snapshot.data!['booked']!;

          if (published.isEmpty && booked.isEmpty) {
            return const Center(
              child: Text("You haven't published or booked any rides."),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              if (published.isNotEmpty)
                ExpansionTile(
                  title: const Text(
                    "Published Rides",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: true,
                  children:
                      published
                          .map((ride) => buildRideCard(ride, isPublished: true))
                          .toList(),
                ),
              if (booked.isNotEmpty)
                ExpansionTile(
                  title: const Text(
                    "Booked Rides",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: true,
                  children:
                      booked
                          .map(
                            (ride) => buildRideCard(ride, isPublished: false),
                          )
                          .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
