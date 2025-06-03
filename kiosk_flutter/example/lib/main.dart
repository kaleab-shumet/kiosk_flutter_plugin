import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kiosk_flutter/kiosk_flutter.dart';
import 'permissions_section.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Corrected type for _missingPermissions, assuming getMissingPermissions returns List<Map<String, String?>>
  // where each map has 'name', 'label', 'type'. If it's just List<String> of permission names, adjust accordingly.
  List<Map<String, String?>> _missingPermissions = []; 
  final _kioskFlutterPlugin = KioskFlutter();
  bool _isKioskModeActive = false;
  String _kioskModeStatusText = 'Kiosk Mode: Unknown';
  bool _isDefaultLauncher = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchMissingPermissions(); // This will also call _getKioskModeStatus
    _checkIfDefaultLauncher();
    // _getKioskModeStatus(); // Called by _fetchMissingPermissions
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMissingPermissions(); // This will also call _getKioskModeStatus
      _checkIfDefaultLauncher();
      // _getKioskModeStatus(); // Called by _fetchMissingPermissions
    }
  }

  Future<void> _fetchMissingPermissions() async {
    List<Map<String, String?>>? permissions;
    try {
      // Assuming getMissingPermissions returns List<Map<String, String?>>
      // If it returns List<String> (permission names), the type of _missingPermissions and this logic needs to change.
      permissions = await _kioskFlutterPlugin.getMissingPermissions();
    } on PlatformException catch (e) {
      debugPrint('Failed to get missing permissions: ${e.message}');
      permissions = []; // Default to empty list on error
    } catch (e) {
      debugPrint('Failed to get missing permissions: ${e.toString()}');
      permissions = []; // Default to empty list on error
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
      // isActive remains null, will be handled below
    } catch (e) {
      debugPrint('Failed to get kiosk mode status: ${e.toString()}');
      // isActive remains null, will be handled below
    }

    if (!mounted) return;

    setState(() {
      _isKioskModeActive = isActive ?? false;
      _kioskModeStatusText = _isKioskModeActive ? "Kiosk Mode: Active" : "Kiosk Mode: Inactive";
    });
  }

  Future<void> _checkIfDefaultLauncher() async {
    bool? isDefault;
    try {
      isDefault = await _kioskFlutterPlugin.isSetAsDefaultLauncher();
    } catch (e) {
      debugPrint('Failed to check if default launcher: $e');
      // isDefault remains null, will be handled below
    }
    if (mounted) {
      setState(() {
        _isDefaultLauncher = isDefault ?? false;
      });
    }
  }

  Future<void> _openHomeSettings() async {
    try {
      // Ensure your plugin has a method like openSettings or a specific one for default apps
      await _kioskFlutterPlugin.openSettings('android.settings.action.ACTION_MANAGE_DEFAULT_APPS_SETTINGS');
      // Consider refreshing default launcher status after returning from settings
      // Future.delayed(const Duration(seconds: 1), _checkIfDefaultLauncher);
    } catch (e) {
      debugPrint('Failed to open home settings: $e');
    }
  }

  Future<void> _toggleKioskMode() async {
    if (!_missingPermissions.isEmpty) {
      debugPrint('Cannot toggle kiosk mode: Not all permissions are granted.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please grant all missing permissions to enable kiosk mode.')),
        );
      }
      return;
    }

    try {
      if (_isKioskModeActive) {
        await _kioskFlutterPlugin.stopKioskMode();
      } else {
        // Redundant check, already handled by the top if, but kept for clarity
        // if (_missingPermissions.isEmpty) { 
          await _kioskFlutterPlugin.startKioskMode();
        // } else {
        //   if (mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Please grant all permissions to start kiosk mode.')),
        //     );
        //   }
        //   return; 
        // }
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
    final bool _allPermissionsGranted = _missingPermissions.isEmpty;
    // Determine if the kiosk mode button should be enabled
    final bool isKioskToggleButtonEnabled = _allPermissionsGranted; 

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kiosk Plugin Example'),
        ),
        body: (_allPermissionsGranted && _isKioskModeActive)
            ? const Center(
                child: Text(
                  'Normal Functioning',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            : Center(
                child: PermissionsAndKioskControlSection(
                  missingPermissions: _missingPermissions,
                  onOpenPermissionSettings: (String permissionType) {
                    _kioskFlutterPlugin.openPermissionSettings(permissionType);
                  },
                  onRefreshPermissions: _fetchMissingPermissions,
                  isKioskModeActive: _isKioskModeActive,
                  isKioskToggleButtonEnabled: isKioskToggleButtonEnabled,
                  onToggleKioskMode: _toggleKioskMode,
                  kioskModeStatusText: _kioskModeStatusText,
                ),
              ),
      ),
    );
  }
}
