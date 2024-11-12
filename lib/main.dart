import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Battery _battery = Battery();
  BatteryState _batteryState = BatteryState.unknown;
  int _batteryLevel = 0;
  String _lightStatus = "Not Set Yet"; // Initialize the light status
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _timer;
  bool _isLoading = true;
  double _alertThreshold = 80.0; // Default threshold value
  bool _hasShownAlert = false; // Flag to track if alert has been shown

  @override
  void initState() {
    super.initState();

    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) {
        setState(() {
          _batteryState = state;
        });
      },
    );

    _getLevel();

    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _getLevel());
    _fetchLightStatus(); // Fetch the light status initially
  }

  Future<void> _getLevel() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final int batteryLevel = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = batteryLevel;
        _isLoading = false;
      });
      // Check if battery level is less than the custom threshold and perform an action
      if (_batteryLevel < _alertThreshold) {
        if (!_hasShownAlert) {
          _showBatteryAlert();
          _hasShownAlert = true; // Set the flag to true after showing alert
        }
        _setLightStatus(
            'ON'); // Call ON API if battery level is below threshold
      } else {
        _setLightStatus(
            'OFF'); // Call OFF API if battery level is above or equal to threshold
      }
    } catch (e) {
      print("Error fetching battery level: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLightStatus() async {
    try {
      final response = await http
          .get(Uri.parse('http://ridoy.destinyenergy.net/light-status'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _lightStatus = data['light']['status'] ??
              'Not Set Yet'; // Handle potential null value
        });
      } else {
        print("Failed to fetch light status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching light status: $e");
    }
  }

  void _showBatteryAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Low Battery'),
          content: Text('Battery level is below $_alertThreshold%.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showChargingAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(
              'Please connect with our Smart charging port to change the alert threshold.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setLightStatus(String status) async {
    final url = status == "ON"
        ? 'http://ridoy.destinyenergy.net/light-setstatuson'
        : 'http://ridoy.destinyenergy.net/light-setstatusoff';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("Light status set to $status successfully.");
        setState(() {
          _lightStatus = status; // Update the light status locally
        });
      } else {
        print("Failed to set light status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error setting light status: $e");
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battery Status App'),
      ),
      body: GestureDetector(
        onLongPress: () {
          _getLevel(); // Refresh battery data on long press
          _fetchLightStatus(); // Refresh light status on long press
        },
        child: Center(
          child: _isLoading
              ? Image.asset('assets/loading-gif.gif') // Display loading GIF
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Battery Level: $_batteryLevel%'),
                    SizedBox(height: 20),
                    Text('Battery State: $_batteryState'),
                    SizedBox(height: 20),
                    Text('Alert Threshold: ${_alertThreshold.toInt()}%'),
                    Slider(
                      value: _alertThreshold,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _alertThreshold.toInt().toString(),
                      onChanged: (double value) {
                        if (_batteryState == BatteryState.charging) {
                          setState(() {
                            _alertThreshold = value;
                            _hasShownAlert = false; // Reset the alert flag
                          });
                        } else {
                          _showChargingAlert();
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Light Status: $_lightStatus'), // Display light status
                  ],
                ),
        ),
      ),
    );
  }
}
