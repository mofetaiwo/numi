import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_view.dart';
import 'receipt_verification.dart';
import '../../models/receipt_model.dart';
import '../../viewmodels/receipt_scanner/permissions_viewmodel.dart';

/// This is the page for collecting user permission to access their 
/// camera and/or photo gallery for the receipt scanning feature. The
/// app allows for manual entry of receipts if permission is not granted.

// INITIAL STATES
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final PermissionsViewModel _viewModel = PermissionsViewModel(); 

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initialPermissionCheck();
    });
  }
  
  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }
  
  void _onViewModelChanged() {
    setState(() {});
  }

  Future<void> _initialPermissionCheck() async {
    await _viewModel.checkInitialPermissions();
  }

  /// When user presses "Take Photo" button
  Future<void> _handleCameraTap() async {
    final outcome = await _viewModel.requestCameraPermission();
    if (!mounted) return;

    switch (outcome) {
      case PermissionActionOutcome.granted:
        _launchCamera(context);
        break;
      case PermissionActionOutcome.permanentlyDenied:
        _showSettingsPrompt(context, 'Camera');
        break;
      case PermissionActionOutcome.permissionDenied:
        _showSnackbar(_viewModel.errorMessage ?? 'Camera access denied.', isSuccess: false);
        break;
      default:
        // No action needed for other states here
    }
  }

  /// When user clicks "Upload from Photo Gallery" button
  Future<void> _handleGalleryTap() async {
    final outcome = await _viewModel.handleGallerySelection();
    if (!mounted) return;

    switch (outcome) {
      case PermissionActionOutcome.granted:
        /// If Photo is found, process it into the app
        if (_viewModel.selectedReceipt != null) {
          _launchReceiptVerification(_viewModel.selectedReceipt as ReceiptModel);
        } else {
          _showSnackbar('File selection successful, but data is missing.', isSuccess: false);
        }
        break;
      case PermissionActionOutcome.permanentlyDenied:
        _showSettingsPrompt(context, 'Photo Gallery');
        break;
      case PermissionActionOutcome.permissionDenied:
        _showSnackbar(_viewModel.errorMessage ?? 'Photo Gallery access denied.', isSuccess: false);
        break;
      case PermissionActionOutcome.selectionCancelled:
        _showSnackbar('Photo selection cancelled.', isSuccess: false);
        break;
      case PermissionActionOutcome.error:
        _showSnackbar(_viewModel.errorMessage ?? 'An unknown error occurred during selection.', isSuccess: false);
        break;
    }
  }

  // NAVIGATION LOGIC
  /// Launches camera when user clicks "Take Photo" and permission is granted
  void _launchCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraViewPage()), 
    );
  }
  
  /// Navigates to receipt verfication page when picture is taken or selected and processed
  /// to let the user make sure it is correct before adding it to the app
  void _launchReceiptVerification(ReceiptModel receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptVerificationPage(receiptData: receipt),
      ),
    );
  }

  /// If camera or photo gallery permissions are not granted, the user can input the details
  /// of their receipt manually with this
  void _launchManualInput(BuildContext context) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ReceiptVerificationPage(receiptData: ReceiptModel.empty('Manual Input')),
    //   ),
    // );
  }

  // UI METHODS
  /// This dialog box appears if permission is denied. It gives the user the option to go
  /// into settings and grant permissions to use the automatic receipt scanner or to 
  /// manually add the receipt.
  void _showSettingsPrompt(BuildContext context, String resourceName) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // content of widget
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          
          title: Column(
            children: [
              Icon(
                Icons.no_photography_rounded,
                size: 40,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                '$resourceName Access Blocked',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          content: Text(
            'Permission is required for the Receipt Scanner feature to work. Please open settings to enable access, or choose to enter your receipt details manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          
          // Aligning content of widget
          actions: <Widget>[
            // Secondary action (TextButton)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _launchManualInput(context);
              },
              child: const Text('Manual Input'),
            ),
            
            // Primary action (ElevatedButton)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Open Settings'),
            ),
          ],
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }
  
  /// Snackbar shown at the botton of the screen to alert the user of messages such as errors.
  /// Changes color (green or red) according if the message is a success or an error
  void _showSnackbar(String message, {bool isSuccess = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = isSuccess ? Colors.green.shade700 : colorScheme.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // MAIN BUILD METHOD
  @override
  Widget build(BuildContext context) {
    if (_viewModel.isCheckingPermissions) {
      return const _ReceiptScannerLoading(title: 'Checking Permissions');
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Container(
        // surface color for slight contrast from default
        color: colorScheme.surface, 
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Visual Header
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Icon(
                    Icons.receipt_long,
                    size: 96,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Text
                Text(
                  'Capture Your Receipt',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Use the camera for instant capture or upload an existing image to log your expense.',
                  style: TextStyle(
                    fontSize: 17,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Camera Button (Primary Action)
                ElevatedButton.icon(
                  onPressed: _handleCameraTap,
                  icon: const Icon(Icons.photo_camera_rounded, size: 28),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(double.infinity, 60),
                    elevation: 6,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo Gallery Button (Secondary Action)
                OutlinedButton.icon(
                  onPressed: _handleGalleryTap,
                  icon: const Icon(Icons.photo_library_rounded, size: 28),
                  label: const Text(
                    'Upload from Photo Gallery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: colorScheme.primary, width: 2),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                ),
                
                // Manual Entry Button (Third Action)
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _launchManualInput(context),
                  child: Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Loading Receipt Scanner Widget
class _ReceiptScannerLoading extends StatelessWidget {
  final String title;
  const _ReceiptScannerLoading({this.title = 'Checking Scanner Status'});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        color: colorScheme.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cached, size: 80, color: colorScheme.secondary),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: colorScheme.secondaryContainer,
                  color: colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing receipt scanner and checking existing permissions.',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}