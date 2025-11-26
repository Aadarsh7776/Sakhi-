import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

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
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              './assets/sakhi_logo.jpg', // 🩷 Replace with your 3rd uploaded image file
              height: 35,
            ),
            const SizedBox(width: 10),
            const Text(
              "Sakhi",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // ❌ Removes the back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      // 🌍 Map Section
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

      // ⚡ Bottom Navigation Bar
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
              // 🗺 Home Button
              IconButton(
                icon: Icon(
                  Icons.map_rounded,
                  color: _selectedIndex == 0 ? Colors.pinkAccent : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),

              const SizedBox(width: 40), // Space for SOS button
              // 👤 Profile Button
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 2 ? Colors.pinkAccent : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),

      // 🚨 Floating SOS Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() => _selectedIndex = 1);
          Navigator.pushNamed(context, '/sos');
        },
        child: Image.asset(
          './assets/sos_icon.png', // ⚠ Replace with your 2nd uploaded SOS image file
          height: 40,
        ),
      ),
    );
  }
}

