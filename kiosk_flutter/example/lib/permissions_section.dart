import 'package:flutter/material.dart';

class PermissionsAndKioskControlSection extends StatelessWidget {
  final List<Map<String, String?>> missingPermissions;
  final Function(String permissionType) onOpenPermissionSettings;
  final VoidCallback onRefreshPermissions;
  final bool isKioskModeActive;
  final bool isKioskToggleButtonEnabled;
  final VoidCallback onToggleKioskMode;
  final String kioskModeStatusText;

  const PermissionsAndKioskControlSection({
    Key? key,
    required this.missingPermissions,
    required this.onOpenPermissionSettings,
    required this.onRefreshPermissions,
    required this.isKioskModeActive,
    required this.isKioskToggleButtonEnabled,
    required this.onToggleKioskMode,
    required this.kioskModeStatusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(kioskModeStatusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Missing Permissions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (missingPermissions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('All required permissions are granted.'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missingPermissions.length,
              itemBuilder: (context, index) {
                final permission = missingPermissions[index];
                return ListTile(
                  title: Text(permission['label'] ?? permission['name'] ?? 'Unknown Permission'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final String? permissionType = permission['type'];
                      if (permissionType != null) {
                        onOpenPermissionSettings(permissionType);
                      } else {
                        debugPrint('Cannot open settings: permission type is null for ${permission['name']}.');
                      }
                    },
                    child: const Text('Enable'),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRefreshPermissions,
            child: const Text('Refresh Permissions List'),
          ),
          const SizedBox(height: 20),
          const Text('Kiosk Mode Control:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isKioskToggleButtonEnabled ? onToggleKioskMode : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isKioskToggleButtonEnabled ? null : Colors.grey,
            ),
            child: Text(isKioskModeActive ? 'Stop Kiosk Mode' : 'Start Kiosk Mode'),
          ),
        ],
      ),
    );
  }
}