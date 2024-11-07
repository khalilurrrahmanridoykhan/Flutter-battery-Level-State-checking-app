import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

void main() {
  runApp(MyApp());
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
    try {
      final int batteryLevel = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = batteryLevel;
      });
    } catch (e) {
      print("Error fetching battery level: $e");
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
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      home: Scaffold(
        appBar: AppBar(
          title: Text('Battery Status App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Battery Level: $_batteryLevel%'),
              SizedBox(height: 20),
              Text('Battery State: $_batteryState'),
            ],
          ),
        ),
      ),
    );
  }
}
