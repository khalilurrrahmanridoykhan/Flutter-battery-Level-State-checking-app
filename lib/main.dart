import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

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
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _timer;
  bool _isLoading = true;
  double _alertThreshold = 80.0; // Default threshold value

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
        _showBatteryAlert();
      }
    } catch (e) {
      print("Error fetching battery level: $e");
      setState(() {
        _isLoading = false;
      });
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
                        setState(() {
                          _alertThreshold = value;
                        });
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
