import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rydex/screens/profile/edit_profile_screen.dart';
import '../../providers/auth_provider.dart' as my_auth;
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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

  Future<Map<String, dynamic>?> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data();
  }

  Future<Map<String, int>> fetchRideCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'ridesGiven': 0, 'ridesTaken': 0};

    try {
      // Fetch published rides (rides given)
      final publishedSnapshot =
          await FirebaseFirestore.instance
              .collection('rides')
              .where('userId', isEqualTo: uid)
              .get();

      // Fetch booked rides (rides taken)
      final bookedSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .get();

      return {
        'ridesGiven': publishedSnapshot.docs.length,
        'ridesTaken': bookedSnapshot.docs.length,
      };
    } catch (e) {
      // If there's an error, return 0 for both counts
      return {'ridesGiven': 0, 'ridesTaken': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.teal.shade50],
          stops: const [0.7, 1.0],
        ),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([fetchUserData(), fetchRideCounts()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.teal.shade600),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data![0] == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: Colors.teal.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No profile data found",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data![0] as Map<String, dynamic>;
          final rideCounts = snapshot.data![1] as Map<String, int>;

          final String name = userData['name'] ?? 'User';
          final String email = userData['email'] ?? 'No email';
          final String phone = userData['phone'] ?? 'No phone';
          final String role = userData['role'] ?? 'User';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                Container(
                      padding: const EdgeInsets.all(24),
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
                        children: [
                          // Avatar
                          Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.teal.shade300,
                                          Colors.teal.shade700,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade600,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 200.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                              ),

                          const SizedBox(height: 20),

                          // Name
                          Text(
                                name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 200.ms, delay: 200.ms)
                              .moveY(begin: -10, end: 0),

                          const SizedBox(height: 8),

                          // Role Badge
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 200.ms, delay: 200.ms)
                              .moveY(begin: -10, end: 0),
                        ],
                      ),
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms)
                    .moveY(begin: -20, end: 0),

                const SizedBox(height: 24),

                // Profile Info
                Container(
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
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Colors.teal.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "Personal Information",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // Email
                          ProfileTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                          ),

                          // Phone
                          ProfileTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: phone,
                          ),

                          // Account Created
                          ProfileTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member Since',
                            value:
                                userData['createdAt'] != null
                                    ? _formatDate(userData['createdAt'])
                                    : 'Not available',
                          ),
                        ],
                      ),
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms, delay: 200.ms)
                    .moveY(begin: 20, end: 0),

                const SizedBox(height: 24),

                // Stats Section
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
                      child: Row(
                        children: [
                          // Rides Given
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.directions_car_filled,
                                    color: Colors.teal.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  rideCounts['ridesGiven'].toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rides Given",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          Container(
                            height: 80,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),

                          // Rides Taken
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.emoji_people,
                                    color: Colors.teal.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  rideCounts['ridesTaken'].toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rides Taken",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms, delay: 200.ms)
                    .moveY(begin: 20, end: 0),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                      children: [
                        // Edit Profile Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final userData =
                                  snapshot.data![0] as Map<String, dynamic>;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfileScreen(userData: userData),
                                ),
                              );

                              // If profile was updated successfully, refresh the data
                              if (result == true) {
                                setState(() {
                                  // This will trigger a rebuild and fetch the updated data
                                });
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
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

                        // Logout Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show confirmation dialog
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text("Logout"),
                                      content: const Text(
                                        "Are you sure you want to logout?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade600,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text("Logout"),
                                        ),
                                      ],
                                    ),
                              );

                              if (shouldLogout == true) {
                                await Provider.of<my_auth.AuthProvider>(
                                  context,
                                  listen: false,
                                ).signOut();
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
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
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms, delay: 200.ms)
                    .moveY(begin: 20, end: 0),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not available';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Not available';
    } catch (e) {
      return 'Not available';
    }
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
