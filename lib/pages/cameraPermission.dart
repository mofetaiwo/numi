import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPromptPage extends StatefulWidget {
  const CameraPromptPage({super.key});

  @override
  State<CameraPromptPage> createState() => _CameraPromptPageState();
}

class _CameraPromptPageState extends State<CameraPromptPage> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPermissionDialog(context);
    });
  }

  // Check the current status of user camera permissions
  Future<void> _checkAndShowPermissionDialog(BuildContext context) async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraStatus = status;
    });

    if (status.isDenied) {
      _showCustomPermissionDialog(context);
    }
  }

  // Request the user for permission to use the camera
  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraStatus = status;
    });

    // behavior for if user permanently denied camera access
    if (status.isPermanentlyDenied) {
      _showSettingsPrompt(context);
    }
  }

  // --- UI Methods ---

  // Custom Dialog to ask the user for permission (instead of using alert())
  void _showCustomPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Enable Receipt Scanning'),
          content: const Text(
            'To automatically track expenses, we need access to your camera to take pictures of receipts.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // User chose not to grant now, update UI state
                setState(() {
                  _cameraStatus = PermissionStatus.denied;
                });
              },
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _requestPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Grant Access'),
            ),
          ],
        );
      },
    );
  }

  // Dialog for permanently denied status
  void _showSettingsPrompt(BuildContext context) {
     showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Camera Access Blocked'),
          content: const Text(
            'It looks like camera access is permanently denied. Please open your app settings to enable it manually.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings(); // Opens the device's app settings
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Determine the display message and color based on the permission status
  Widget _buildStatusDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String statusText;
    IconData icon;
    Color color;

    if (_cameraStatus.isGranted) {
      statusText = 'Camera access GRANTED! You can now scan receipts.';
      icon = Icons.check_circle_outline;
      color = Colors.green.shade700;
    } else if (_cameraStatus.isDenied) {
      statusText = 'Camera access is REQUIRED for receipt scanning. Would you like to maunally input your receipt?';
      icon = Icons.cancel_outlined;
      color = Colors.red.shade700;
    } else if (_cameraStatus.isPermanentlyDenied) {
      statusText = 'Permission permanently denied. Go to settings to change.';
      icon = Icons.lock_outline;
      color = Colors.orange.shade700;
    } else {
       statusText = 'Checking camera permission status...';
       icon = Icons.pending_actions;
       color = colorScheme.secondary;
    }

    return Column(
      children: [
        Icon(icon, size: 80, color: color),
        const SizedBox(height: 24),
        Text(
          'Receipt Scanner Ready',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusDisplay(context),
              if (_cameraStatus.isDenied || _cameraStatus.isPermanentlyDenied)
                const SizedBox(height: 32),
              if (_cameraStatus.isDenied)
                ElevatedButton.icon(
                  onPressed: () => _showCustomPermissionDialog(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Request Camera Permission'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (_cameraStatus.isPermanentlyDenied)
                ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Go to App Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}