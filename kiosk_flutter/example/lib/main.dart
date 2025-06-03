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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  List<Map<String, String?>> _missingPermissions = [];
  final _kioskFlutterPlugin = KioskFlutter();
  bool _isKioskModeActive = false;
  String _kioskModeStatusText = 'Kiosk Mode: Unknown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchMissingPermissions();
    _getKioskModeStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMissingPermissions();
      _getKioskModeStatus();
    }
  }

  Future<void> _fetchMissingPermissions() async {
    List<Map<String, String?>>? permissions;
    try {
      permissions = await _kioskFlutterPlugin.getMissingPermissions();
    } on PlatformException catch (e) {
      debugPrint('Failed to get missing permissions: ${e.message}');
      permissions = [];
    } catch (e) {
      debugPrint('Failed to get missing permissions: ${e.toString()}');
      permissions = [];
    }

    if (!mounted) return;

    setState(() {
      _missingPermissions = permissions ?? [];
    });
    // After fetching permissions, update kiosk status as it might affect button enablement
    _getKioskModeStatus(); 
  }

  Future<void> _getKioskModeStatus() async {
    bool? isActive;
    try {
      isActive = await _kioskFlutterPlugin.isKioskModeActive();
    } on PlatformException catch (e) {
      debugPrint('Failed to get kiosk mode status: ${e.message}');
    } catch (e) {
      debugPrint('Failed to get kiosk mode status: ${e.toString()}');
    }

    if (!mounted) return;

    setState(() {
      _isKioskModeActive = isActive ?? false;
      _kioskModeStatusText = _isKioskModeActive ? "Kiosk Mode: Active" : "Kiosk Mode: Inactive";
    });
  }

  Future<void> _toggleKioskMode() async {
    if (!_missingPermissions.isEmpty) {
      debugPrint('Cannot toggle kiosk mode: Not all permissions are granted.');
      // Optionally, show a snackbar or dialog to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant all missing permissions to enable kiosk mode.')),
      );
      return;
    }

    try {
      if (_isKioskModeActive) {
        await _kioskFlutterPlugin.stopKioskMode();
      } else {
        if (_missingPermissions.isEmpty) { // Only start if permissions are granted
          await _kioskFlutterPlugin.startKioskMode();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please grant all permissions to start kiosk mode.')),
          );
          return; // Don't try to refresh status if we didn't attempt to start
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to toggle kiosk mode: ${e.message}');
    } catch (e) {
      debugPrint('Failed to toggle kiosk mode: ${e.toString()}');
    }
    _getKioskModeStatus(); // Refresh status after attempting toggle
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the kiosk mode button should be enabled
    final bool isKioskToggleButtonEnabled = _missingPermissions.isEmpty;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kiosk Plugin Example'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_kioskModeStatusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Missing Permissions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_missingPermissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('All required permissions are granted.'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _missingPermissions.length,
                    itemBuilder: (context, index) {
                      final permission = _missingPermissions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(permission['label'] ?? 'Unknown Permission'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              final String? permissionType = permission['type'];
                              if (permissionType != null) {
                                _kioskFlutterPlugin.openPermissionSettings(permissionType);
                              } else {
                                debugPrint('Cannot open settings: permission type is null.');
                              }
                            },
                            child: const Text('Enable'),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchMissingPermissions,
                  child: const Text('Refresh Permissions List'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isKioskToggleButtonEnabled ? _toggleKioskMode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isKioskToggleButtonEnabled ? null : Colors.grey,
                  ),
                  child: Text(_isKioskModeActive ? 'Stop Kiosk Mode' : 'Start Kiosk Mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
