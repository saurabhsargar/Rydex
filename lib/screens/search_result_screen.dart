import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/ride_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String from;
  final String to;
  final DateTime? date;
  final int persons;

  const SearchResultScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.persons,
    required userId,
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
    final snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .where('from', isEqualTo: widget.from)
        .where('to', isEqualTo: widget.to)
        .get();

    return snapshot.docs.where((doc) {
      final ride = doc.data();
      final rideDateStr = ride['date'] as String?;
      if (rideDateStr == null) return false;

      final rideDate = DateFormat('yyyy-MM-dd').parse(rideDateStr);
      return widget.date == null || rideDate == widget.date;
    }).map((doc) {
      final rideData = doc.data();
      rideData['id'] = doc.id; // Add doc ID to ride data
      return rideData;
    }).toList();
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
                        Text("Date: ${ride['date']}", style: const TextStyle(fontSize: 13)),
                      if (ride['time'] != null)
                        Text("Time: ${ride['time']}", style: const TextStyle(fontSize: 13)),
                      if (ride['seats'] != null)
                        Text("Available Seats: ${ride['seats']}", style: const TextStyle(fontSize: 13)),
                      if (ride['driverName'] != null)
                        Text("Driver: ${ride['driverName']}", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideDetailScreen(
                          ride: ride,
                          rideId: ride['id'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
