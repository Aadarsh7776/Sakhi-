import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // For tracking selected button

  // 🗺️ Your map polygons
  final dangerZone = Polygon(
    points: [
      LatLng(19.0800, 72.8700),
      LatLng(19.0850, 72.8800),
      LatLng(19.0750, 72.8900),
    ],
    color: Colors.redAccent.withValues(alpha: 0.3),
    borderStrokeWidth: 2,
    borderColor: Colors.red,
  );

  final safeZone = Polygon(
    points: [
      LatLng(19.0700, 72.8600),
      LatLng(19.0650, 72.8700),
      LatLng(19.0750, 72.8650),
    ],
    color: Colors.greenAccent.withValues(alpha: 0.3),
    borderStrokeWidth: 2,
    borderColor: Colors.green,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sakhi"),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),

      // 🌍 MAP BODY
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(19.0760, 72.8777),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(polygons: [dangerZone, safeZone]),
        ],
      ),

      // ⚡ Sleek Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 65,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 🗺️ MAP Button
              IconButton(
                icon: Icon(
                  Icons.map,
                  color: _selectedIndex == 0 ? Colors.pinkAccent : Colors.grey,
                ),
                onPressed: () {
                  setState(() => _selectedIndex = 0);
                  // Navigate or reload map if needed
                },
              ),

              // 🚨 SOS Button (center floating)
              const SizedBox(width: 40), // Space for FAB
              // 👤 PROFILE Button
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 2 ? Colors.pinkAccent : Colors.grey,
                ),
                onPressed: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ),
      ),

      // 🚨 Floating Action Button (SOS)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: const Icon(Icons.emergency, color: Colors.white, size: 30),
        onPressed: () {
          setState(() => _selectedIndex = 1);
          Navigator.pushNamed(context, '/sos');
        },
      ),
    );
  }
}
