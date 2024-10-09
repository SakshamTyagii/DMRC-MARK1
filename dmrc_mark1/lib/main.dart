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
        pathOption: pathOption,
      ),
    );
  }
}

class SplitScreenMap extends StatefulWidget {
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
  _SplitScreenMapState createState() => _SplitScreenMapState();
}

class _SplitScreenMapState extends State<SplitScreenMap> {
  bool isMapFullScreen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dynamic map
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: isMapFullScreen ? 0 : MediaQuery.of(context).size.height * 0.5,
          bottom: isMapFullScreen ? 0 : MediaQuery.of(context).size.height * 0.5,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.blueAccent,
            child: Center(
              child: Text(
                'Dynamic Map Placeholder\n(${widget.pathOption})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        // Station list
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: isMapFullScreen ? MediaQuery.of(context).size.height : 0,
          bottom: isMapFullScreen ? -MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.5,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: loadStations(widget.fromStation, widget.toStation),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        final stations = snapshot.data!;
                        return ListView.builder(
                          itemCount: stations.length,
                          itemBuilder: (context, index) {
                            final station = stations[index];
                            return ListTile(
                              title: Text(station['stop_name']),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('No data available'));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Toggle arrow
        Positioned(
          top: isMapFullScreen
              ? MediaQuery.of(context).size.height * 0.9
              : MediaQuery.of(context).size.height * 0.4,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isMapFullScreen = !isMapFullScreen;
                });
              },
              child: Icon(
                isMapFullScreen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 48,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Dummy function to get stations for the route
  Future<List<Map<String, dynamic>>> loadStations(String from, String to) async {
    // Simulate fetching route data based on the selected stations
    return [
      {"stop_name": "Dilshad Garden"},
      {"stop_name": "Jhilmil"},
      {"stop_name": "Mansrover Park"},
      {"stop_name": "Shahdara"},
      {"stop_name": "Seelampur"},
      {"stop_name": "Welcome"},
    ];
  }
}
