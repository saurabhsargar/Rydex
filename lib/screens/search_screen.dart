import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/map_preview.dart';
import 'package:rydex/screens/place_search_screen.dart';
import 'package:rydex/screens/search_result_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController leavingFromController = TextEditingController();
  final TextEditingController goingToController = TextEditingController();
  DateTime? _selectedDate;
  int _selectedPersons = 1;
  late AnimationController _animationController;

  LatLng? leavingFromLatLng;
  LatLng? goingToLatLng;

  final String googleMapsApiKey = 'AIzaSyCDYtA7aiWr5_Xni4Q6JLrC27xpCk1VKSM';
  
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  "Find a Ride",
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
                  "Where would you like to go today?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                )
                .animate(controller: _animationController)
                .fadeIn(duration: 200.ms, delay: 200.ms)
                .moveY(begin: -20, end: 0),
                
                const SizedBox(height: 30),
                
                // Search Form
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
                              builder: (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
                            ),
                          );
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              leavingFromController.text = result['description'];
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
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.teal.shade600),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.my_location, color: Colors.teal.shade600),
                                  onPressed: () {
                                    // Current location functionality remains the same
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
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
                              builder: (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
                            ),
                          );
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              goingToController.text = result['description'];
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
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.teal.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
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
                        "WHEN",
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
                          DateTime? selected = await showDatePicker(
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
                          if (selected != null) {
                            setState(() => _selectedDate = selected);
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
                                hintText: _selectedDate == null
                                    ? "Select date"
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                hintStyle: TextStyle(
                                  color: _selectedDate == null ? Colors.grey.shade500 : Colors.black87,
                                ),
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.teal.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 200.ms, delay: 200.ms)
                      .moveX(begin: -20, end: 0),
                      
                      const SizedBox(height: 20),
                      
                      // Persons Field
                      Text(
                        "PASSENGERS",
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
                        child: DropdownButtonFormField<int>(
                          value: _selectedPersons,
                          items: List.generate(6, (index) => index + 1)
                              .map(
                                (num) => DropdownMenuItem(
                                  value: num,
                                  child: Text("$num Person${num > 1 ? 's' : ''}"),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _selectedPersons = value!),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.people_outline, color: Colors.teal.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade600),
                          dropdownColor: Colors.white,
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
                          if (leavingFromLatLng == null || goingToLatLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Please select both locations"),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.redAccent,
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapPreviewScreen(
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
                    
                    // Search Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text("Find Rides"),
                        onPressed: () {
                          if (leavingFromLatLng == null || goingToLatLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Please select both locations"),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.redAccent,
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                            return;
                          }
                          if (_selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Please select a date"),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.redAccent,
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                            return;
                          }
                          if (leavingFromController.text == goingToController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Departure and destination cannot be the same"),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.redAccent,
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchResultScreen(
                                from: leavingFromController.text,
                                to: goingToController.text,
                                date: _selectedDate,
                                persons: _selectedPersons,
                                userId: FirebaseAuth.instance.currentUser?.uid,
                              ),
                            ),
                          );
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
                )
                .animate(controller: _animationController)
                .fadeIn(duration: 200.ms, delay: 200.ms)
                .moveY(begin: 20, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}