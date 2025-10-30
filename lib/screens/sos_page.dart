import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  bool _isSending = false;
  String _status = "Tap the button to send SOS 🚨";
  Position? _position;

  // Example emergency contacts — can later come from Firestore or user profile
  final List<String> _emergencyContacts = [
    '+919999999999',
    '+918888888888'
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Step 1: Request permissions
  Future<void> _requestPermissions() async {
    var status = await Permission.location.request();

    if (status.isDenied) {
      setState(() =>
          _status = "❌ Location permission denied. Please enable it manually.");
      openAppSettings();
    } else if (status.isPermanentlyDenied) {
      setState(() =>
          _status = "⚠ Permission permanently denied. Enable from settings.");
      openAppSettings();
    }
  }

  // Step 2: Get user location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = "⚠ Location services are disabled.");
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = "❌ Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status =
          "⚠ Location permission permanently denied. Enable in settings.");
      await Geolocator.openAppSettings();
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _status = "✅ Location fetched successfully!";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Failed to get location: $e";
      });
    }
  }

  // Step 3: Send SOS alert to Firestore
  Future<void> _sendSOS() async {
    setState(() {
      _isSending = true;
      _status = "Sending SOS alert...";
    });

    await _getCurrentLocation();

    if (_position == null) {
      setState(() {
        _isSending = false;
        _status = "❌ Unable to get location. Please enable GPS.";
      });
      return;
    }

    try {
      final sosData = {
        'timestamp': Timestamp.now(),
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'message': "🚨 SOS ALERT! I am in danger, please help me!",
        'contacts': _emergencyContacts,
      };

      await FirebaseFirestore.instance.collection('sos_alerts').add(sosData);

      setState(() {
        _isSending = false;
        _status = "✅ SOS alert sent successfully!";
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("🚨 SOS SENT"),
          content: const Text("Your SOS alert has been sent successfully!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isSending = false;
        _status = "❌ Failed to send SOS: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("SOS Alert"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendSOS,
                icon: const Icon(Icons.emergency, color: Colors.white),
                label: Text(
                  _isSending ? "Sending..." : "Send SOS",
                  style: const TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}