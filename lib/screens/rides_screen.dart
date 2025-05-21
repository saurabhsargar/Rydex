import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/chat_screen.dart';

class YourRidesScreen extends StatefulWidget {
  const YourRidesScreen({super.key});

  @override
  State<YourRidesScreen> createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen>
    with SingleTickerProviderStateMixin {
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

      // Fetch published rides (as you're already doing)
      final publishedSnapshot =
          await FirebaseFirestore.instance
              .collection('rides')
              .where('userId', isEqualTo: uid)
              .get();

      final publishedRides =
          publishedSnapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();

      // Fetch booked rides
      final bookedSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .get();

      // Process booked rides and fetch associated ride info
      List<Map<String, dynamic>> bookedRides = [];
      for (var doc in bookedSnapshot.docs) {
        final bookingData = doc.data();
        final bookingWithId = {'id': doc.id, ...bookingData};

        // Fetch the associated ride to get driver information
        if (bookingData['rideId'] != null) {
          final rideDoc =
              await FirebaseFirestore.instance
                  .collection('rides')
                  .doc(bookingData['rideId'])
                  .get();

          if (rideDoc.exists) {
            final rideData = rideDoc.data();
            // Add driver ID from the ride to the booking data
            bookingWithId['driverId'] = rideData?['userId'];

            // Optionally fetch driver name too
            if (rideData?['userId'] != null) {
              final driverDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(rideData?['userId'])
                      .get();

              if (driverDoc.exists) {
                final driverData = driverDoc.data();
                bookingWithId['driverName'] = driverData?['name'] ?? 'Driver';
              }
            }
          }
        }

        bookedRides.add(bookingWithId);
      }

      setState(() {
        _publishedRides = publishedRides;
        _bookedRides = bookedRides;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getDriverOrPassengerDetails(
    Map<String, dynamic> ride,
    bool isDriver,
  ) async {
    try {
      String otherUserId;
      String otherUserName = "User";

      if (isDriver) {
        // If current user is the driver, get passenger details
        otherUserId = ride['userId']; // The passenger's ID

        // Fetch passenger's name
        final passengerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

        if (passengerDoc.exists) {
          final userData = passengerDoc.data();
          otherUserName = userData?['name'] ?? 'Passenger';
        }
      } else {
        // If current user is the passenger, get driver details
        otherUserId = ride['driverId']; // The driver's ID

        // Fetch driver's name
        final driverDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

        if (driverDoc.exists) {
          final userData = driverDoc.data();
          otherUserName = userData?['name'] ?? 'Driver';
        }
      }

      return {'userId': otherUserId, 'name': otherUserName};
    } catch (e) {
      // Return default values if error occurs
      return {'userId': '', 'name': 'User'};
    }
  }

  void _navigateToChat(Map<String, dynamic> ride, bool isDriver) async {
    try {
      setState(() {
        _isLoading = true;
      });

      String otherUserId = '';
      String otherUserName = 'User';

      if (isDriver) {
        // Current user is the driver, get passenger info
        // Code for this case seems fine
        final bookingsSnapshot =
            await FirebaseFirestore.instance
                .collection('bookings')
                .where('rideId', isEqualTo: ride['id'])
                .get();

        if (bookingsSnapshot.docs.isNotEmpty) {
          final bookingData = bookingsSnapshot.docs.first.data();
          otherUserId = bookingData['userId'];

          // Get passenger name
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            otherUserName = userData?['name'] ?? 'Passenger';
          }
        }
      } else {
        // Current user is the passenger, get driver info
        // This part should now work because we've added driverId to the booking data
        otherUserId = ride['driverId'] ?? '';

        if (otherUserId.isNotEmpty) {
          // Get driver name if not already fetched
          if (ride['driverName'] == null) {
            final userDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              otherUserName = userData?['name'] ?? 'Driver';
            }
          } else {
            otherUserName = ride['driverName'];
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (otherUserId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  rideId: ride['id'],
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  isDriver: isDriver,
                ),
          ),
        );
      } else {
        // Show an error if we couldn't find the other user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't find the other user for this ride"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
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

  // Show confirmation dialog for deleting a ride
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Ride",
            style: TextStyle(
              color: Colors.teal.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this ride? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Show confirmation dialog for canceling a booked ride
  Future<bool> _showCancelBookingConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Cancel Booking",
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to cancel this booking? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Keep Booking",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Cancel Booking"),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Delete a published ride
  Future<void> _deleteRide(String rideId) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the ride from Firestore
      await FirebaseFirestore.instance.collection('rides').doc(rideId).delete();

      // Also delete any bookings associated with this ride
      final bookingsSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('rideId', isEqualTo: rideId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in bookingsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Refresh the rides list
      await _fetchRides();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Ride deleted successfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting ride: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  // Cancel a booked ride
  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await _showCancelBookingConfirmation(context);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the booking to find associated ride
      final bookingDoc =
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .get();

      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data();
        final rideId = bookingData?['rideId'];

        // First, delete the booking
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .delete();

        // Then update the ride to increase available seats
        if (rideId != null) {
          final rideDoc =
              await FirebaseFirestore.instance
                  .collection('rides')
                  .doc(rideId)
                  .get();

          if (rideDoc.exists) {
            final rideData = rideDoc.data();
            final currentSeats = rideData?['seats_available'] ?? 0;

            await FirebaseFirestore.instance
                .collection('rides')
                .doc(rideId)
                .update({'seats_available': currentSeats + 1});
          }
        }
      }

      // Refresh the rides list
      await _fetchRides();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking canceled successfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error canceling booking: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  // Navigate to edit ride screen
  void _navigateToEditRide(Map<String, dynamic> ride) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditRideScreen(ride: ride),
            fullscreenDialog: true,
          ),
        )
        .then((_) => _fetchRides());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchRides,
      color: Colors.teal.shade600,
      child:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.teal.shade600),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                      const SizedBox(height: 16),

                                      if (ride['fare'] != null)
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "\$${ride['fare']}",
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

                                  const SizedBox(height: 16),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed:
                                            () => _navigateToChat(
                                              ride,
                                              true,
                                            ), // true means current user is the driver
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.blue.shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.message_outlined,
                                          size: 18,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Edit button
                                      OutlinedButton.icon(
                                        onPressed:
                                            () => _navigateToEditRide(ride),
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.teal.shade700,
                                        ),
                                        label: Text(
                                          "Edit",
                                          style: TextStyle(
                                            color: Colors.teal.shade700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.teal.shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Delete button
                                      OutlinedButton.icon(
                                        onPressed:
                                            () => _deleteRide(ride['id']),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        label: const Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.red.shade200,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                      // Add fare if available
                                      if (ride['fare'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.attach_money,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Fare: \$${ride['fare']}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Cancel booking button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed:
                                            () => _navigateToChat(
                                              ride,
                                              false,
                                            ), // false means current user is the passenger
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.blue.shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.message_outlined,
                                          size: 18,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      OutlinedButton.icon(
                                        onPressed:
                                            () => _cancelBooking(ride['id']),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        label: const Text(
                                          "Cancel Booking",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.red.shade200,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
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
                    }).toList(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
    );
  }
}

// EditRideScreen class for updating ride details
class EditRideScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const EditRideScreen({super.key, required this.ride});

  @override
  State<EditRideScreen> createState() => _EditRideScreenState();
}

class _EditRideScreenState extends State<EditRideScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _seatsController;
  late TextEditingController _timeController;
  late TextEditingController _fareController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.ride['from']);
    _toController = TextEditingController(text: widget.ride['to']);
    _seatsController = TextEditingController(
      text: (widget.ride['seats_available'] ?? 0).toString(),
    );
    _timeController = TextEditingController(text: widget.ride['time']);
    _fareController = TextEditingController(
      text: widget.ride['fare']?.toString() ?? '',
    );

    if (widget.ride['date'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.ride['date']);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _seatsController.dispose();
    _timeController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time picker
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (_timeController.text.isNotEmpty) {
      try {
        final parts = _timeController.text.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        // Use default time if parsing fails
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // Update ride in Firestore
  Future<void> _updateRide() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select a date"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final updatedRide = {
          'from': _fromController.text.trim(),
          'to': _toController.text.trim(),
          'seats_available': int.parse(_seatsController.text),
          'time': _timeController.text,
          'date': _selectedDate!.toIso8601String(),
          'fare': double.parse(_fareController.text), // Add fare
          'updated_at': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.ride['id'])
            .update(updatedRide);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Ride updated successfully"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.teal.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error updating ride: $e"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Ride"),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.teal.shade600),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From location
                      TextFormField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          labelText: "From",
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: Colors.teal.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade600,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter departure location";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // To location
                      TextFormField(
                        controller: _toController,
                        decoration: InputDecoration(
                          labelText: "To",
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.teal.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade600,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter destination";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Date selection
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat(
                                        'EEE, MMM d, yyyy',
                                      ).format(_selectedDate!)
                                      : "Select Date",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        _selectedDate != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Time selection
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _timeController.text.isNotEmpty
                                      ? _timeController.text
                                      : "Select Time",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        _timeController.text.isNotEmpty
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Seats available
                      TextFormField(
                        controller: _seatsController,
                        decoration: InputDecoration(
                          labelText: "Available Seats",
                          prefixIcon: Icon(
                            Icons.event_seat,
                            color: Colors.teal.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade600,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter number of seats";
                          }

                          final seats = int.tryParse(value);
                          if (seats == null) {
                            return "Please enter a valid number";
                          }

                          if (seats < 1) {
                            return "Must have at least 1 seat";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _fareController,
                        decoration: InputDecoration(
                          labelText: "Fare",
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: Colors.teal.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade600,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter fare amount";
                          }

                          final fare = double.tryParse(value);
                          if (fare == null) {
                            return "Please enter a valid number";
                          }

                          if (fare < 0) {
                            return "Fare cannot be negative";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Update button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Update Ride",
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
              ),
    );
  }
}
