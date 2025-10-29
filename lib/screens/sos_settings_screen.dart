import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sos_service.dart';

class SOSSettingsScreen extends StatefulWidget {
  final String userId;

  const SOSSettingsScreen({super.key, required this.userId});

  @override
  State<SOSSettingsScreen> createState() => _SOSSettingsScreenState();
}

class _SOSSettingsScreenState extends State<SOSSettingsScreen> {
  final SOSService _sosService = SOSService();
  
  double _shakeThreshold = 20.0;
  double _fallThreshold = 15.0;
  int _detectionDuration = 3000;
  bool _vibrateonTrigger = true;
  bool _soundAlert = true;
  bool _autoCallPolice = false;
  String _policeNumber = '100'; // Default emergency number India
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shakeThreshold = prefs.getDouble('shake_threshold') ?? 20.0;
      _fallThreshold = prefs.getDouble('fall_threshold') ?? 15.0;
      _detectionDuration = prefs.getInt('detection_duration') ?? 3000;
      _vibrateonTrigger = prefs.getBool('vibrate_on_trigger') ?? true;
      _soundAlert = prefs.getBool('sound_alert') ?? true;
      _autoCallPolice = prefs.getBool('auto_call_police') ?? false;
      _policeNumber = prefs.getString('police_number') ?? '100';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shake_threshold', _shakeThreshold);
    await prefs.setDouble('fall_threshold', _fallThreshold);
    await prefs.setInt('detection_duration', _detectionDuration);
    await prefs.setBool('vibrate_on_trigger', _vibrateonTrigger);
    await prefs.setBool('sound_alert', _soundAlert);
    await prefs.setBool('auto_call_police', _autoCallPolice);
    await prefs.setString('police_number', _policeNumber);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPoliceNumberDialog() {
    final controller = TextEditingController(text: _policeNumber);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Police Emergency Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter emergency number',
            prefixIcon: Icon(Icons.local_police),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _policeNumber = controller.text;
              });
              Navigator.pop(context);
              _saveSettings();
            },
            child: Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOS Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Detection Sensitivity Section
          _buildSectionHeader('Detection Sensitivity'),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shake Detection Threshold',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current: ${_shakeThreshold.toStringAsFixed(1)} m/s²',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Slider(
                    value: _shakeThreshold,
                    min: 10.0,
                    max: 30.0,
                    divisions: 20,
                    label: _shakeThreshold.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _shakeThreshold = value;
                      });
                    },
                  ),
                  Text(
                    'Lower = More sensitive (may have false positives)',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Fall Detection Threshold',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current: ${_fallThreshold.toStringAsFixed(1)} m/s²',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Slider(
                    value: _fallThreshold,
                    min: 10.0,
                    max: 25.0,
                    divisions: 15,
                    label: _fallThreshold.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _fallThreshold = value;
                      });
                    },
                  ),
                  Text(
                    'Lower = More sensitive to falls',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Detection Duration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current: ${(_detectionDuration / 1000).toStringAsFixed(1)} seconds',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Slider(
                    value: _detectionDuration.toDouble(),
                    min: 1000,
                    max: 5000,
                    divisions: 8,
                    label: '${(_detectionDuration / 1000).toStringAsFixed(1)}s',
                    onChanged: (value) {
                      setState(() {
                        _detectionDuration = value.toInt();
                      });
                    },
                  ),
                  Text(
                    'Time window for detecting sustained abnormal movement',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Alert Preferences Section
          _buildSectionHeader('Alert Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Vibrate on Trigger'),
                  subtitle: Text('Phone will vibrate when SOS is triggered'),
                  value: _vibrateonTrigger,
                  onChanged: (value) {
                    setState(() {
                      _vibrateonTrigger = value;
                    });
                  },
                  secondary: Icon(Icons.vibration),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Sound Alert'),
                  subtitle: Text('Play alert sound when SOS is triggered'),
                  value: _soundAlert,
                  onChanged: (value) {
                    setState(() {
                      _soundAlert = value;
                    });
                  },
                  secondary: Icon(Icons.volume_up),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Emergency Services Section
          _buildSectionHeader('Emergency Services'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Auto-Call Police'),
                  subtitle: Text('Automatically call police when SOS is triggered'),
                  value: _autoCallPolice,
                  onChanged: (value) {
                    setState(() {
                      _autoCallPolice = value;
                    });
                  },
                  secondary: Icon(Icons.local_police, color: Colors.blue),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.blue),
                  title: Text('Police Emergency Number'),
                  subtitle: Text(_policeNumber),
                  trailing: Icon(Icons.edit),
                  onTap: _showPoliceNumberDialog,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Testing Section
          _buildSectionHeader('Testing & Calibration'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.science, color: Colors.purple),
                  title: Text('Test Shake Detection'),
                  subtitle: Text('Shake your phone to test sensitivity'),
                  trailing: Icon(Icons.play_arrow),
                  onTap: () {
                    _showTestDialog('Shake', 'Shake your phone vigorously');
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.airline_seat_flat, color: Colors.orange),
                  title: Text('Test Fall Detection'),
                  subtitle: Text('Simulate a fall (be careful!)'),
                  trailing: Icon(Icons.play_arrow),
                  onTap: () {
                    _showTestDialog('Fall', 'Drop your phone gently onto a soft surface');
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.restore, color: Colors.red),
                  title: Text('Reset to Defaults'),
                  subtitle: Text('Restore default sensitivity settings'),
                  trailing: Icon(Icons.refresh),
                  onTap: _resetToDefaults,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Info Section
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Lower thresholds increase sensitivity but may cause false alarms\n'
                    '• Test your settings in a safe environment\n'
                    '• Ensure location services are always enabled\n'
                    '• Keep emergency contacts up to date\n'
                    '• Battery optimization may affect automatic detection',
                    style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red[700],
        ),
      ),
    );
  }

  void _showTestDialog(String type, String instruction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test $type Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'Shake' ? Icons.phone_android : Icons.airline_seat_flat,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(instruction),
            SizedBox(height: 20),
            Text(
              'The test will run for 10 seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTest(type);
            },
            child: Text('START TEST'),
          ),
        ],
      ),
    );
  }

  void _startTest(String type) {
    // Temporarily enable monitoring for test
    _sosService.startMonitoring();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test started - $type detection active for 10 seconds'),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.blue,
      ),
    );
    
    // Stop test after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      _sosService.stopMonitoring();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Defaults'),
        content: Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shakeThreshold = 20.0;
                _fallThreshold = 15.0;
                _detectionDuration = 3000;
                _vibrateonTrigger = true;
                _soundAlert = true;
                _autoCallPolice = false;
                _policeNumber = '100';
              });
              Navigator.pop(context);
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('RESET'),
          ),
        ],
      ),
    );
  }
}