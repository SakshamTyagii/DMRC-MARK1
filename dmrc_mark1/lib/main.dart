import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_search/dropdown_search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MetroHomePage(),
    );
  }
}

class MetroHomePage extends StatefulWidget {
  const MetroHomePage({super.key});

  @override
  _MetroHomePageState createState() => _MetroHomePageState();
}

class _MetroHomePageState extends State<MetroHomePage> {
  List<Map<String, dynamic>> stations = [];
  String? selectedFromStation;
  String? selectedToStation;
  String selectedPathOption = 'Shortest Path';

  @override
  void initState() {
    super.initState();
    loadStations(); // Load stations when the app starts
  }

  Future<void> loadStations() async {
    final jsonString = await rootBundle.loadString('assets/stops.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      stations = List<Map<String, dynamic>>.from(jsonData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Metro Navigator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Searchable dropdown for 'from' station
            DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
              ),
              items: stations
                  .map((station) => station['stop_name'] as String)
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedFromStation = value;
                });
              },
              selectedItem: selectedFromStation, // Show the selected item
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'From Station',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Searchable dropdown for 'to' station
            DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
              ),
              items: stations
                  .map((station) => station['stop_name'] as String)
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedToStation = value;
                });
              },
              selectedItem: selectedToStation, // Show the selected item
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'To Station',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // RadioListTile for Pathfinding options
            RadioListTile<String>(
              title: const Text('Shortest Path'),
              value: 'Shortest Path',
              groupValue: selectedPathOption,
              onChanged: (value) {
                setState(() {
                  selectedPathOption = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Minimum Line Exchange'),
              value: 'Minimum Line Exchange',
              groupValue: selectedPathOption,
              onChanged: (value) {
                setState(() {
                  selectedPathOption = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            // Button to navigate to the next page with selected options
            ElevatedButton(
              onPressed:
                  selectedFromStation != null && selectedToStation != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MetroMapPage(
                                fromStation: selectedFromStation!,
                                toStation: selectedToStation!,
                                pathOption: selectedPathOption,
                              ),
                            ),
                          );
                        }
                      : null,
              child: const Text('Find Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class MetroMapPage extends StatelessWidget {
  final String fromStation;
  final String toStation;
  final String pathOption;

  const MetroMapPage({
    super.key,
    required this.fromStation,
    required this.toStation,
    required this.pathOption,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route: $fromStation to $toStation'),
      ),
      body: SplitScreenMap(
          fromStation: fromStation,
          toStation: toStation,
          pathOption: pathOption),
    );
  }
}

class SplitScreenMap extends StatelessWidget {
  final String fromStation;
  final String toStation;
  final String pathOption;

  const SplitScreenMap({
    super.key,
    required this.fromStation,
    required this.toStation,
    required this.pathOption,
  });

  @override
  Widget build(BuildContext context) {
    // Split screen layout
    return Row(
      children: [
        // First half: Dynamic map showing travel path
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blueAccent,
            child: Center(
              child: Text('Dynamic Map Placeholder\n($pathOption)',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),

        // Second half: List of stations for the selected route
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: loadStations(), // You would calculate the path here
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final stations = snapshot.data!;
                  // Filter or find the path using fromStation, toStation, and pathOption
                  return ListView.builder(
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(stations[index]['stop_name']),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

Future<List<Map<String, dynamic>>> loadStations() async {
  final jsonString = await rootBundle.loadString('assets/stops.json');
  final jsonData = jsonDecode(jsonString);
  return List<Map<String, dynamic>>.from(jsonData);
}
