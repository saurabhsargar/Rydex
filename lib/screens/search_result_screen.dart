import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/ride_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _SearchResultScreenState extends State<SearchResultScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _rides = []; // Changed to local state
  bool _isLoading = true;
  bool _isBooking = false;
  int? _bookingIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchMatchingRides();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatchingRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('rides')
              .where('from', isEqualTo: widget.from)
              .where('to', isEqualTo: widget.to)
              .get();

      final rides =
          snapshot.docs
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
                // isNotSelfRide; // Exclude self rides
              })
              .map((doc) {
                final data = doc.data();
                return {'id': doc.id, ...data};
              })
              .toList();

      setState(() {
        _rides = rides;
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

  // Check if user has already booked this ride
  Future<bool> _hasUserAlreadyBooked(String rideId) async {
    try {
      final bookingSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('rideId', isEqualTo: rideId)
              .where('userId', isEqualTo: widget.userId)
              .get();

      return bookingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking existing bookings: $e");
      return false;
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

  // NEW: Method to update local ride data when returning from detail screen
  void _updateLocalRideData(Map<String, dynamic> updatedRide) {
    final rideId = updatedRide['id'] ?? '';
    final rideIndex = _rides.indexWhere((ride) => ride['id'] == rideId);

    if (rideIndex != -1) {
      setState(() {
        _rides[rideIndex] = updatedRide;
      });
    }
  }

  // NEW: Navigate to ride detail screen and handle updates
  Future<void> _navigateToRideDetail(Map<String, dynamic> ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RideDetailScreen(
              ride: ride,
              rideId: ride['id'],
              requestedSeats: widget.persons, // Pass the requested seats
            ),
      ),
    );

    // If result is returned (updated ride data), update the local state
    if (result != null && result is Map<String, dynamic>) {
      _updateLocalRideData(result);
    }
  }

  Future<void> _bookRide(
    BuildContext context,
    Map<String, dynamic> ride,
    int index,
  ) async {
    final int seatsAvailable = ride['seats_available'] ?? 0;
    final int requestedSeats = widget.persons;
    final String rideId = ride['id'];

    // Early validation to improve UX
    if (seatsAvailable < requestedSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Not enough seats available for your request."),
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

    // Check for double booking
    final hasAlreadyBooked = await _hasUserAlreadyBooked(rideId);
    if (hasAlreadyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You have already booked this ride."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
      _bookingIndex = index;
    });

    try {
      // Use a transaction to ensure atomicity and prevent race conditions
      final rideRef = FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId);

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
        'rideId': rideId,
        'userId': widget.userId,
        'from': widget.from,
        'to': widget.to,
        'date':
            widget.date != null
                ? DateFormat('yyyy-MM-dd').format(widget.date!)
                : null,
        'persons': requestedSeats,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the local state to reflect the change immediately
      setState(() {
        _rides[index]['seats_available'] = seatsAvailable - requestedSeats;
      });

      // Navigate to ride details with updated seat count
      final updatedRide = {
        ...ride,
        'seats_available': seatsAvailable - requestedSeats,
      };

      // Show success animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOut,
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Ride Booked Successfully",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Use the new navigation method
                        _navigateToRideDetail(updatedRide);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("View Details"),
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to book ride: ${e.toString()}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() {
        _isBooking = false;
        _bookingIndex = null;
      });
    }
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
            stops: const [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.teal.shade700,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .moveX(begin: -20, end: 0),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Available Rides",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${widget.from} → ${widget.to}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms)
                          .moveY(begin: -10, end: 0),
                    ),
                  ],
                ),
              ),

              // Search Summary
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          // Date
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: Colors.teal.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.date != null
                                      ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(widget.date!)
                                      : "Any date",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Persons
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: Colors.teal.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "${widget.persons} ${widget.persons > 1 ? 'persons' : 'person'}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .moveY(begin: -10, end: 0),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.teal.shade600,
                          ),
                        )
                        : _rides.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.teal.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No matching rides found",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try different dates or locations",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("Back to Search"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rides.length,
                          itemBuilder: (context, index) {
                            final ride = _rides[index];
                            final seatsAvailable = ride['seats_available'] ?? 0;

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
                                            Text(
                                              _formatDate(ride['date']),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal.shade800,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              ride['time'] ??
                                                  "Time not specified",
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
                                                      color:
                                                          Colors.green.shade600,
                                                      size: 14,
                                                    ),
                                                    Container(
                                                      width: 2,
                                                      height: 25,
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    Icon(
                                                      Icons.location_on,
                                                      color:
                                                          Colors.red.shade600,
                                                      size: 14,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "${ride['from']}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        "${ride['to']}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
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
                                                // Driver
                                                if (ride['driverName'] != null)
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 16,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          "${ride['driverName']}",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade700,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
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
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "$seatsAvailable seats available",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            // Add fare display
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.teal.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],

                                            const SizedBox(height: 16),

                                            // Action Buttons
                                            Row(
                                              children: [
                                                // View Details Button
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      // Use the new navigation method
                                                      _navigateToRideDetail(
                                                        ride,
                                                      );
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.teal.shade700,
                                                      side: BorderSide(
                                                        color:
                                                            Colors
                                                                .teal
                                                                .shade300,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "View Details",
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 12),

                                                // Book Now Button
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        _isBooking &&
                                                                _bookingIndex ==
                                                                    index
                                                            ? null
                                                            : () => _bookRide(
                                                              context,
                                                              ride,
                                                              index,
                                                            ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.teal.shade600,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    child:
                                                        _isBooking &&
                                                                _bookingIndex ==
                                                                    index
                                                            ? SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                            : const Text(
                                                              "Book Now",
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
                                )
                                .animate(controller: _animationController)
                                .fadeIn(
                                  duration: 400.ms,
                                  delay: Duration(milliseconds: 100 * index),
                                )
                                .moveY(begin: 20, end: 0);
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
