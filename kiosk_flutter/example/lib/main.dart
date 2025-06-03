import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kiosk_flutter/kiosk_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _kioskFlutterPlugin = KioskFlutter();
  String _dummyMessage = 'No message yet.';

  // Method to fetch the dummy message
  Future<void> _fetchDummyMessage() async {
    String? message;
    try {
      message = await _kioskFlutterPlugin.getDummyMessage();
    } on PlatformException catch (e) {
      message = 'Failed to get dummy message: ${e.message}';
    } catch (e) {
      message = 'Failed to get dummy message: ${e.toString()}';
    }

    if (!mounted) return;

    setState(() {
      _dummyMessage = message ?? 'Received null message';
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _kioskFlutterPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Running on: $_platformVersion\n'),
              const SizedBox(height: 16),
              Text('Dummy Message: $_dummyMessage\n'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDummyMessage,
                child: const Text('Get Dummy Message from Native'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
