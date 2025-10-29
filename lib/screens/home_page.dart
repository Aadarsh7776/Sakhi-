import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sakhi/screens/sos_screen.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Polygons disabled for now
    // final dangerZone = Polygon(
    //   points: [
    //     LatLng(19.0800, 72.8700),
    //     LatLng(19.0850, 72.8800),
    //     LatLng(19.0750, 72.8900),
    //   ],
    //   color: Colors.redAccent.withValues(alpha: 0.3),
    //   borderStrokeWidth: 2,
    //   borderColor: Colors.red,
    // );

    // final safeZone = Polygon(
    //   points: [
    //     LatLng(19.0700, 72.8600),
    //     LatLng(19.0650, 72.8700),
    //     LatLng(19.0750, 72.8650),
    //   ],
    //   color: Colors.greenAccent.withValues(alpha: 0.3),
    //   borderStrokeWidth: 2,
    //   borderColor: const Color.fromARGB(255, 45, 66, 45),
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sakhi"),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(19.0760, 72.8777),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          // PolygonLayer disabled for now
          // PolygonLayer(polygons: [dangerZone, safeZone]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SOSScreen(
                userId: FirebaseAuth.instance.currentUser?.uid ?? '', // Replace with actual user ID from Firebase Auth
              ),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.emergency, color: Colors.white),
      ),
    );
  }
}