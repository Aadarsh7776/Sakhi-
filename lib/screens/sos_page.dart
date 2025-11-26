import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  bool _isSending = false;
  String _status = "Press SOS to Send Alert 🚨";
  Position? _position;
  List<String> _emergencyContacts = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initSOSSetup();
  }

  Future<void> _initSOSSetup() async {
    await _requestPermissions();
    await _fetchContactsFromFirebase();
    await _getCurrentLocation();
  }

  // ✅ Request permissions for location
  Future<void> _requestPermissions() async {
    await [Permission.location].request();
  }

  // ✅ Fetch user's emergency contacts from Firestore
  Future<void> _fetchContactsFromFirebase() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('user_id_123') // 🔁 Replace with actual user ID
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('emergencyContacts')) {
        List<dynamic> contacts = userDoc['emergencyContacts'];
        setState(() => _emergencyContacts = contacts.cast<String>());
      } else {
        setState(() => _status = "⚠️ No emergency contacts found.");
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
      setState(() => _status = "Error loading contacts ❌");
    }
  }

  // ✅ Get user’s current location
  Future<void> _getCurrentLocation() async {
    if (await Permission.location.isGranted) {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {});
    } else {
      setState(() => _status = "Location permission denied ❌");
    }
  }

  // ✅ Simulate SOS message sending (without SMS)
  Future<void> _sendSOS() async {
    if (_emergencyContacts.isEmpty) {
      setState(() => _status = "⚠️ No emergency contacts found.");
      return;
    }

    setState(() {
      _isSending = true;
      _status = "Preparing SOS alert...";
    });

    String locationUrl = _position != null
        ? "https://www.google.com/maps?q=${_position!.latitude},${_position!.longitude}"
        : "Location not available";

    String message =
        "🚨 SOS ALERT from Sakhi App!\n\nI am in danger, please help!\nMy location: $locationUrl";

    // Simulate delay (like sending process)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSending = false;
      _status = "✅ SOS alert triggered successfully!";
    });

    // 💬 Show popup alert
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "🚨 SOS ACTIVATED",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your emergency contacts would receive this alert:\n\n$message",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Icon(Icons.shield, color: Colors.red, size: 60),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Emergency SOS"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                  parent: _animController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: GestureDetector(
                onTap: _isSending ? null : _sendSOS,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.redAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "SOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            if (_position != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "📍 ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
