import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../services/sos_service.dart';

class SOSScreen extends StatefulWidget {
  final String userId;

  const SOSScreen({super.key, required this.userId});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  final SOSService _sosService = SOSService();
  final TextEditingController _contactController = TextEditingController();
  final Battery _battery = Battery();
  
  bool _isMonitoring = false;
  bool _sosActive = false;
  int _batteryLevel = 100;
  Position? _currentPosition;
  List<String> _emergencyContacts = [];
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSOSService();
    _setupAnimations();
    _updateBatteryLevel();
    _updateLocation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeSOSService() async {
    await _sosService.initialize(widget.userId);
    setState(() {
      _emergencyContacts = _sosService.emergencyContacts;
    });
  }

  Future<void> _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
    
    // Update every minute
    Future.delayed(Duration(minutes: 1), _updateBatteryLevel);
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
      if (_isMonitoring) {
        _sosService.startMonitoring();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automatic monitoring enabled'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _sosService.stopMonitoring();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automatic monitoring disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _triggerSOS() async {
    setState(() {
      _sosActive = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm SOS Alert'),
          ],
        ),
        content: Text(
          'This will send an emergency alert to all your contacts with your location and battery status. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sosActive = false;
              });
              Navigator.pop(context);
            },
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sosService.triggerSOS(automatic: false);
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text('SOS Sent'),
                    ],
                  ),
                  content: Text('Emergency alerts have been sent to all your contacts.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _sosActive = false;
                        });
                        _sosService.resetSOS();
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('SEND SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmergencyContact() async {
    if (_contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    // Basic phone number validation
    String contact = _contactController.text.trim();
    if (contact.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    await _sosService.addEmergencyContact(contact);
    setState(() {
      _emergencyContacts = _sosService.emergencyContacts;
    });
    _contactController.clear();
    Navigator.pop(context);
  }

  Future<void> _removeContact(String contact) async {
    await _sosService.removeEmergencyContact(contact);
    setState(() {
      _emergencyContacts = _sosService.emergencyContacts;
    });
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: TextField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: _addEmergencyContact,
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOS Emergency'),
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[700]!, Colors.red[900]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Status Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Battery',
                          '$_batteryLevel%',
                          Icons.battery_full,
                          _batteryLevel > 20 ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusCard(
                          'Location',
                          _currentPosition != null ? 'Active' : 'Searching...',
                          Icons.location_on,
                          _currentPosition != null ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // SOS Button
                  Center(
                    child: GestureDetector(
                      onTap: _triggerSOS,
                      child: ScaleTransition(
                        scale: _sosActive ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emergency,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'PRESS FOR HELP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Auto-Monitor Toggle
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automatic Monitoring',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Detects falls and unusual movements',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isMonitoring,
                          onChanged: (value) => _toggleMonitoring(),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Emergency Contacts Section
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Emergency Contacts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green),
                              onPressed: _showAddContactDialog,
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (_emergencyContacts.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No emergency contacts added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ..._emergencyContacts.map((contact) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red[100],
                              child: Icon(Icons.person, color: Colors.red[700]),
                            ),
                            title: Text(contact),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeContact(contact),
                            ),
                          )),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Info Card
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'How it works',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Press SOS button to send immediate alert\n'
                          '• Enable auto-monitoring to detect falls\n'
                          '• Works offline via SMS\n'
                          '• Sends location & battery status\n'
                          '• Add trusted contacts for alerts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}