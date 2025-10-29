import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling emergency communications (SMS and calls)
/// Alternative to discontinued telephony package
class EmergencyCommunicationService {
  static final EmergencyCommunicationService _instance = 
      EmergencyCommunicationService._internal();
  factory EmergencyCommunicationService() => _instance;
  EmergencyCommunicationService._internal();

  /// Request SMS permission
  Future<bool> requestSMSPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Request phone call permission
  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Send SMS to multiple recipients
  /// Returns true if SMS was sent/queued successfully
  Future<bool> sendEmergencySMS({
    required String message,
    required List<String> recipients,
  }) async {
    try {
      // Check if SMS permission is granted
      if (!await Permission.sms.isGranted) {
        final granted = await requestSMSPermission();
        if (!granted) {
          print('SMS permission not granted');
          return false;
        }
      }

      // Try to send SMS directly (background sending)
      try {
        String result = await sendSMS(
          message: message,
          recipients: recipients,
          sendDirect: true,
        );
        print('SMS sent directly: $result');
        return true;
      } catch (e) {
        print('Direct SMS send failed: $e');
        
        // Fallback: Open SMS app with pre-filled message
        return await _openSMSApp(message, recipients);
      }
    } catch (e) {
      print('Error in sendEmergencySMS: $e');
      return false;
    }
  }

  /// Open SMS app with pre-filled message
  Future<bool> _openSMSApp(String message, List<String> recipients) async {
    try {
      // For multiple recipients, some Android versions support comma-separated
      String recipientsString = recipients.join(',');
      
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: recipientsString,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening SMS app: $e');
      return false;
    }
  }

  /// Send SMS to single recipient
  Future<bool> sendSMSToContact({
    required String message,
    required String phoneNumber,
  }) async {
    return await sendEmergencySMS(
      message: message,
      recipients: [phoneNumber],
    );
  }

  /// Make emergency call
  Future<bool> makeEmergencyCall(String phoneNumber) async {
    try {
      // Check if phone permission is granted
      if (!await Permission.phone.isGranted) {
        final granted = await requestPhonePermission();
        if (!granted) {
          print('Phone permission not granted');
          return false;
        }
      }

      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Error making emergency call: $e');
      return false;
    }
  }

  /// Open dialer with phone number pre-filled
  Future<bool> openDialer(String phoneNumber) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening dialer: $e');
      return false;
    }
  }

  /// Send SOS to all contacts with retry mechanism
  Future<Map<String, bool>> sendSOSToAllContacts({
    required String message,
    required List<String> contacts,
    int maxRetries = 2,
  }) async {
    Map<String, bool> results = {};
    
    for (String contact in contacts) {
      bool success = false;
      
      // Try up to maxRetries times
      for (int attempt = 0; attempt < maxRetries && !success; attempt++) {
        success = await sendSMSToContact(
          message: message,
          phoneNumber: contact,
        );
        
        if (!success && attempt < maxRetries - 1) {
          // Wait before retry
          await Future.delayed(Duration(seconds: 2));
        }
      }
      
      results[contact] = success;
    }
    
    return results;
  }

  /// Check if device can send SMS
  Future<bool> canSendSMS() async {
    try {
      // Check if SMS permission is available
      final status = await Permission.sms.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      return false;
    }
  }

  /// Check if device can make calls
  Future<bool> canMakeCall() async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: '');
      return await canLaunchUrl(telUri);
    } catch (e) {
      return false;
    }
  }

  /// Send batch SMS with delay between each
  Future<void> sendBatchSMS({
    required String message,
    required List<String> recipients,
    Duration delayBetween = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < recipients.length; i++) {
      await sendSMSToContact(
        message: message,
        phoneNumber: recipients[i],
      );
      
      // Add delay between messages to avoid carrier rate limits
      if (i < recipients.length - 1) {
        await Future.delayed(delayBetween);
      }
    }
  }

  /// Share location via SMS
  Future<bool> shareLocationViaSMS({
    required double latitude,
    required double longitude,
    required String recipientPhone,
    String? customMessage,
  }) async {
    String mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    String message = customMessage ?? 
        '🆘 Emergency Location: $mapsUrl\nLat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    
    return await sendSMSToContact(
      message: message,
      phoneNumber: recipientPhone,
    );
  }

  /// Validate phone number format (basic validation)
  bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it has at least 10 digits (excluding country code)
    return cleaned.length >= 10;
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+91')) {
      // Indian format: +91 XXXXX XXXXX
      if (cleaned.length == 13) {
        return '+91 ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
      }
    }
    
    return phoneNumber;
  }
}

/// Widget to show SMS sending status
class SMSSendingDialog extends StatelessWidget {
  final Future<Map<String, bool>> sendingFuture;
  
  const SMSSendingDialog({super.key, required this.sendingFuture});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 16),
          Text('Sending Emergency SMS'),
        ],
      ),
      content: FutureBuilder<Map<String, bool>>(
        future: sendingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sending alerts to emergency contacts...'),
                SizedBox(height: 16),
                LinearProgressIndicator(),
              ],
            );
          }
          
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          
          if (snapshot.hasData) {
            final results = snapshot.data!;
            int success = results.values.where((v) => v).length;
            int total = results.length;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sent $success of $total messages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: success == total ? Colors.green : Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                ...results.entries.map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.error,
                        color: entry.value ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(entry.key)),
                    ],
                  ),
                )),
              ],
            );
          }
          
          return Text('Unknown status');
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CLOSE'),
        ),
      ],
    );
  }
}