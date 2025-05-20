import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class YourRidesScreen extends StatefulWidget {
  const YourRidesScreen({super.key});

  @override
  State<YourRidesScreen> createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _publishedRides = [];
  List<Map<String, dynamic>> _bookedRides = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchRides();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRides() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final publishedSnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('userId', isEqualTo: uid)
          // .orderBy('timestamp', descending: true)
          .get();

      final bookedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          // .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _publishedRides = publishedSnapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();
        
        _bookedRides = bookedSnapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();
        
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching rides: $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Not specified";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchRides,
      color: Colors.teal.shade600,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.teal.shade600,
              ),
            )
          : _publishedRides.isEmpty && _bookedRides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 80,
                        color: Colors.teal.shade200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No rides yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your published and booked rides will appear here",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_publishedRides.isNotEmpty) ...[
                      Text(
                        "Published Rides",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms)
                      .moveY(begin: -10, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      ..._publishedRides.asMap().entries.map((entry) {
                        final index = entry.key;
                        final ride = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.directions_car_filled,
                                        color: Colors.teal.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "You're driving",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(ride['date']),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Ride Details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Route
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              color: Colors.green.shade600,
                                              size: 14,
                                            ),
                                            Container(
                                              width: 2,
                                              height: 25,
                                              color: Colors.grey.shade300,
                                            ),
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.red.shade600,
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${ride['from']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "${ride['to']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Details
                                    Row(
                                      children: [
                                        // Time
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                ride['time'] ?? "Not set",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Seats
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.event_seat,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${ride['seats_available'] ?? 0} seats",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                        // .animate(controller: _animationController)
                        // .fadeIn(
                        //   duration: 200.ms,
                        //   delay: Duration(milliseconds: 100 * index),
                        // )
                        // .moveY(begin: 20, end: 0);
                      }).toList(),
                    ],
                    
                    if (_bookedRides.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      
                      Text(
                        "Booked Rides",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms, delay: 200.ms)
                      .moveY(begin: -10, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      ..._bookedRides.asMap().entries.map((entry) {
                        final index = entry.key;
                        final ride = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.directions_car_outlined,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "You're a passenger",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(ride['date']),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Ride Details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Route
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              color: Colors.green.shade600,
                                              size: 14,
                                            ),
                                            Container(
                                              width: 2,
                                              height: 25,
                                              color: Colors.grey.shade300,
                                            ),
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.red.shade600,
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${ride['from']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "${ride['to']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Details
                                    Row(
                                      children: [
                                        // Time
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                ride['time'] ?? "Not set",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Driver
                                        if (ride['driverName'] != null)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "${ride['driverName']}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                        // .animate(controller: _animationController)
                        // .fadeIn(
                        //   duration: 200.ms,
                        //   delay: Duration(milliseconds: 200 + (200 * index)),
                        // )
                        // .moveY(begin: 20, end: 0);
                      }).toList(),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}