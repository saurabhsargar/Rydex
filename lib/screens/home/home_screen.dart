import 'package:flutter/material.dart';
import 'package:rydex/screens/chat_screen.dart';
import 'package:rydex/screens/profile/profile_screen.dart';
import 'package:rydex/screens/publish_screen.dart';
import 'package:rydex/screens/rides_screen.dart';
import 'package:rydex/screens/search_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _animationController;

  final List<Widget> pages = [
    const SearchScreen(),
    const PublishRideScreen(),
    const YourRidesScreen(),
    const ChatInboxScreen(),
    const ProfileScreen(),
  ];

  final List<String> titles = [
    "Search Rides",
    "Publish Ride",
    "Your Rides",
    "Inbox",
    "Profile"
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (currentIndex != index) {
      setState(() {
        currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      titles[currentIndex],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms)
                    .moveY(begin: -10, end: 0),
                    
                    const Spacer(),
                    
                    // Notification Icon
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
                        icon: Icon(Icons.notifications_outlined, color: Colors.teal.shade700),
                        onPressed: () {
                          // Notification functionality
                        },
                      ),
                    )
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms, delay: 200.ms)
                    .moveX(begin: 10, end: 0),
                  ],
                ),
              ),
              
              // Page Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: pages[currentIndex],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: Colors.teal.shade700,
              unselectedItemColor: Colors.grey.shade600,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "Search",
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.search, color: Colors.teal.shade700),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  label: "Publish",
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_circle_outline, color: Colors.teal.shade700),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car_outlined),
                  label: "Rides",
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.directions_car_filled, color: Colors.teal.shade700),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message_outlined),
                  label: "Inbox",
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.message_outlined, color: Colors.teal.shade700),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: "Profile",
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person, color: Colors.teal.shade700),
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