import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rydex/screens/map_preview.dart';
import 'package:rydex/screens/place_search_screen.dart';
import 'package:rydex/screens/search_result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController leavingFromController = TextEditingController();
  final TextEditingController goingToController = TextEditingController();
  DateTime? _selectedDate;
  int _selectedPersons = 1;

  LatLng? leavingFromLatLng;
  LatLng? goingToLatLng;

  final String googleMapsApiKey =
      'AIzaSyCDYtA7aiWr5_Xni4Q6JLrC27xpCk1VKSM'; // Replace with your actual API key

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search Rides",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
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
                child: TextFormField(
                  controller: leavingFromController,
                  decoration: const InputDecoration(
                    labelText: "Leaving From",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PlacesSearchScreen(apiKey: googleMapsApiKey),
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
                child: TextFormField(
                  controller: goingToController,
                  decoration: const InputDecoration(
                    labelText: "Going To",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: () async {
                DateTime? selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (selected != null) {
                  setState(() => _selectedDate = selected);
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText:
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: _selectedPersons,
              items:
                  List.generate(6, (index) => index + 1)
                      .map(
                        (num) => DropdownMenuItem(
                          value: num,
                          child: Text("$num Person${num > 1 ? 's' : ''}"),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedPersons = value!),
              decoration: const InputDecoration(
                labelText: "No. of Persons",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.preview),
                label: const Text("Preview"),
                onPressed: () {
                  if (leavingFromLatLng == null || goingToLatLng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select both locations"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MapPreviewScreen(
                            origin: leavingFromLatLng!,
                            destination: goingToLatLng!,
                            apiKey: googleMapsApiKey,
                          ),
                    ),
                  );
                },
              ),
            ),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Search"),
                onPressed: () {
                  if (leavingFromLatLng == null || goingToLatLng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select both locations"),
                      ),
                    );
                    return;
                  }
                  if (_selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a date")),
                    );
                    return;
                  }
                  if (leavingFromController.text == goingToController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Leaving From and Going To cannot be the same",
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SearchResultScreen(
                            from: leavingFromController.text,
                            to: goingToController.text,
                            date: _selectedDate,
                            persons: _selectedPersons,
                            userId: FirebaseAuth.instance.currentUser?.uid,
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
