import 'package:flutter/material.dart';
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
    }
  }
  
  /// When user presses "Upload from Photo Gallery" button
  Future<void> _handleGalleryTap() async {
    final outcome = await _viewModel.requestGalleryPermissionAndUpload();
    if (!mounted) return;

    switch (outcome) {
      case PermissionActionOutcome.granted:
        if (_viewModel.selectedReceipt != null) {
          _launchReceiptVerification(_viewModel.selectedReceipt!);
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
        break;
      case PermissionActionOutcome.error:
        _showSnackbar(_viewModel.errorMessage ?? 'An unknown error occurred during selection.', isSuccess: false);
        break;
    }
    // Clear the error state in the VM after handling
    _viewModel.clearProcessingState();
  }

  // NAVIGATION LOGIC
  void _launchCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraViewPage(viewModel: _viewModel),
      ),
    );
  }
  
  void _launchReceiptVerification(ReceiptModel receipt) {
    // This pushes the verification page onto the stack, keeping the PermissionsPage underneath.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptVerificationPage(receiptData: receipt), 
      ),
    );
    // Clear the error state in the VM after successful navigation
    _viewModel.clearProcessingState(); 
  }

  void _navigateToManualEntry(BuildContext context) {
    // Implement navigation to manual entry page here
    _showSnackbar('Navigating to Manual Entry...', isSuccess: true);
  }

  // UI UTILITIES
  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                _navigateToManualEntry(context);
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

  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Icon(
                Icons.receipt_long,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'How would you like to add your receipt?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 40),

              // Take Photo Button
              ElevatedButton.icon(
                onPressed: _handleCameraTap,
                icon: const Icon(Icons.photo_camera, size: 28),
                label: const Text('Take Photo', style: TextStyle(fontSize: 18))
              ),
              const SizedBox(height: 16),

              // Upload from Gallary button
              OutlinedButton.icon(
                onPressed: _handleGalleryTap,
                icon: const Icon(Icons.photo_library, size: 28),
                label: const Text('Upload from Photo Gallery', style: TextStyle(fontSize: 18)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  side: BorderSide(color: colorScheme.secondary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
              ),
              const SizedBox(height: 40),

              // Manual Entry button
              TextButton.icon(
                onPressed: () => _navigateToManualEntry(context),
                icon: const Icon(Icons.edit_note, size: 24),
                label: const Text('Enter Receipt Details Manually'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}