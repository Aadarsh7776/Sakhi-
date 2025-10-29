import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  final Battery _battery = Battery();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  bool _isMonitoring = false;
  bool _sosTriggered = false;
  List<String> _emergencyContacts = [];
  String? _userId;
  
  // Thresholds for abnormal movement detection
  static const double SHAKE_THRESHOLD = 20.0;
  static const double FALL_THRESHOLD = 15.0;
  static const int ABNORMAL_MOVEMENT_DURATION = 3000; // milliseconds
  
  DateTime? _lastAbnormalMovement;

  List<String> get emergencyContacts => _emergencyContacts;

  // Initialize the SOS service
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _loadEmergencyContacts();
    await _requestPermissions();
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationAlways,
      Permission.sms,
      Permission.phone,
      Permission.sensors,
    ].request();
  }

  // Load emergency contacts from local storage and Firestore
  Future<void> _loadEmergencyContacts() async {
    try {
      // Try to load from Firestore first
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data()?['emergencyContacts'] != null) {
        _emergencyContacts = List<String>.from(doc.data()!['emergencyContacts']);
        
        // Save to local storage for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('emergency_contacts', _emergencyContacts);
      } else {
        // Load from local storage if offline
        final prefs = await SharedPreferences.getInstance();
        _emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
      }
    } catch (e) {
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      _emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    }
  }

  // Add emergency contact
  Future<void> addEmergencyContact(String phoneNumber) async {
    if (!_emergencyContacts.contains(phoneNumber)) {
      _emergencyContacts.add(phoneNumber);
      await _saveEmergencyContacts();
    }
  }

  // Remove emergency contact
  Future<void> removeEmergencyContact(String phoneNumber) async {
    _emergencyContacts.remove(phoneNumber);
    await _saveEmergencyContacts();
  }

  // Save emergency contacts to both local and cloud
  Future<void> _saveEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts', _emergencyContacts);
    
    try {
      await _firestore.collection('users').doc(_userId).set({
        'emergencyContacts': _emergencyContacts,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to save to cloud: $e');
    }
  }

  // Start monitoring for abnormal movements
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    // Monitor accelerometer for shakes and falls
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Detect shake (sudden movement)
      if (acceleration > SHAKE_THRESHOLD) {
        _handleAbnormalMovement('SHAKE');
      }
      
      // Detect fall (sudden drop)
      if (event.z < -FALL_THRESHOLD) {
        _handleAbnormalMovement('FALL');
      }
    });

    // Monitor gyroscope for sudden rotations
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      double rotation = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      if (rotation > 5.0) {
        _handleAbnormalMovement('ROTATION');
      }
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  // Handle abnormal movement detection
  void _handleAbnormalMovement(String type) {
    final now = DateTime.now();
    
    if (_lastAbnormalMovement == null) {
      _lastAbnormalMovement = now;
      return;
    }
    
    final difference = now.difference(_lastAbnormalMovement!).inMilliseconds;
    
    // If abnormal movements persist, trigger SOS
    if (difference < ABNORMAL_MOVEMENT_DURATION && !_sosTriggered) {
      triggerSOS(automatic: true, reason: type);
    } else if (difference > ABNORMAL_MOVEMENT_DURATION) {
      _lastAbnormalMovement = now;
    }
  }

  // Trigger SOS manually or automatically
  Future<void> triggerSOS({bool automatic = false, String reason = 'MANUAL'}) async {
    if (_sosTriggered) return;
    _sosTriggered = true;
    
    try {
      // Get current location
      Position? position = await _getCurrentLocation();
      
      // Get battery percentage
      int batteryLevel = await _battery.batteryLevel;
      
      // Create SOS message
      String message = _createSOSMessage(position, batteryLevel, automatic, reason);
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      // Send SOS via SMS (works offline)
      await _sendSMSAlerts(message);
      
      // If online, also send via Firebase and other online services
      if (isOnline) {
        await _sendOnlineAlerts(position, batteryLevel, reason);
      }
      
      // Save SOS trigger locally
      await _saveSOSLocally(position, batteryLevel, reason, DateTime.now());
      
    } catch (e) {
      print('Error triggering SOS: $e');
    }
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Create SOS message
  String _createSOSMessage(Position? position, int batteryLevel, bool automatic, String reason) {
    String message = automatic 
        ? '🆘 EMERGENCY ALERT (Auto-detected: $reason)\n' 
        : '🆘 EMERGENCY ALERT\n';
    
    message += 'User needs immediate help!\n';
    
    if (position != null) {
      message += 'Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n';
      message += 'Lat: ${position.latitude.toStringAsFixed(6)}\n';
      message += 'Lng: ${position.longitude.toStringAsFixed(6)}\n';
    } else {
      message += 'Location: Unable to fetch location\n';
    }
    
    message += 'Battery: $batteryLevel%\n';
    message += 'Time: ${DateTime.now().toString()}\n';
    message += '\nPlease respond immediately!';
    
    return message;
  }

  // Send SMS alerts to emergency contacts
  Future<void> _sendSMSAlerts(String message) async {
    for (String contact in _emergencyContacts) {
      try {
        // Method 1: Try using flutter_sms package
        await _sendSMS(message, [contact]);
      } catch (e) {
        print('Failed to send SMS to $contact using flutter_sms: $e');
        
        // Method 2: Fallback to URL launcher (opens SMS app)
        try {
          final Uri smsUri = Uri(
            scheme: 'sms',
            path: contact,
            queryParameters: {'body': message},
          );
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
        } catch (e2) {
          print('Failed to send SMS to $contact using URL launcher: $e2');
        }
      }
    }
  }

  // Helper method to send SMS using flutter_sms
  Future<void> _sendSMS(String message, List<String> recipients) async {
    try {
      String result = await sendSMS(
        message: message,
        recipients: recipients,
        sendDirect: true, // Try to send directly without user interaction
      );
      print('SMS sent: $result');
    } catch (e) {
      print('Error sending SMS: $e');
      // If direct send fails, open SMS app
      await sendSMS(
        message: message,
        recipients: recipients,
        sendDirect: false,
      );
    }
  }

  // Send online alerts via Firebase and other services
  Future<void> _sendOnlineAlerts(Position? position, int batteryLevel, String reason) async {
    try {
      // Save to Firestore
      await _firestore.collection('sos_alerts').add({
        'userId': _userId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': position != null 
            ? GeoPoint(position.latitude, position.longitude) 
            : null,
        'batteryLevel': batteryLevel,
        'reason': reason,
        'contacts': _emergencyContacts,
      });
      
      // You can add integration with police API here
      // await _notifyPoliceStation(position, batteryLevel);
      
    } catch (e) {
      print('Failed to send online alerts: $e');
    }
  }

  // Save SOS trigger locally for offline sync
  Future<void> _saveSOSLocally(Position? position, int batteryLevel, String reason, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sosHistory = prefs.getStringList('sos_history') ?? [];
    
    String sosRecord = '${timestamp.toIso8601String()}|'
        '${position?.latitude ?? 0}|'
        '${position?.longitude ?? 0}|'
        '$batteryLevel|'
        '$reason';
    
    sosHistory.add(sosRecord);
    await prefs.setStringList('sos_history', sosHistory);
  }

  // Reset SOS state
  void resetSOS() {
    _sosTriggered = false;
  }

  // Clean up
  void dispose() {
    stopMonitoring();
  }
}