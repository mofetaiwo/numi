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
  // Instantiate the VM once
  final PermissionsViewModel _viewModel = PermissionsViewModel(); 
  
  // State variable to track the last determined permission outcome
  PermissionActionOutcome? _lastOutcome;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    
    // Check permissions immediately after the first frame is built
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
    // Rebuild UI to reflect changes in loading or error state
    setState(() {}); 
  }

  /// Initial check for camera permission, which dictates the next screen.
  Future<void> _initialPermissionCheck() async {
    // Check and request camera permission
    final result = await _viewModel.checkInitialPermissions();

    if (!mounted) return;
    
    // Set the outcome state to drive the UI in the build method
    setState(() {
      _lastOutcome = result;
    });

    switch (result) {
      case PermissionActionOutcome.granted:
        // Permission granted, proceed to the camera view, passing the viewModel
        _navigateToCamera();
        break;
      case PermissionActionOutcome.permanentlyDenied:
      case PermissionActionOutcome.permissionDenied:
      case PermissionActionOutcome.error:
      case PermissionActionOutcome.selectionCancelled:
        // For all other outcomes, the build method will render the appropriate denial/request UI.
        break;
    }
  }

  // --- NAVIGATION HANDLERS ---
  
  /// Navigates to the live camera view.
  void _navigateToCamera() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // FIX: Passing the active ViewModel instance
        builder: (context) => CameraViewPage(viewModel: _viewModel), 
      ),
    );
  }

  /// Navigates to the manual entry screen.
  void _navigateToManualEntry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ReceiptVerificationPage(
            // Pass an empty receipt model for manual data entry
            receiptData: ReceiptModel.empty('manual_entry')), 
      ),
    );
  }

  // --- UI STATE BUILDERS ---
  
  // State 1: Loading/Checking Permissions
  Widget _buildLoadingView(ColorScheme colorScheme) {
    return _buildCentralView(
      colorScheme,
      title: 'Checking Permissions',
      subtitle: 'Preparing receipt scanner and checking existing permissions.',
      isLoading: true,
      button: Container(), // No button during loading
    );
  }

  // State 2: Requesting Permission (Not permanently denied)
  Widget _buildPermissionRequestView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    // If there's an error message, show it below the main text
    final currentSubtitle = _viewModel.errorMessage ?? 
      'We need camera permission to scan your receipts automatically. You can still enter receipts manually.';

    return _buildCentralView(
      colorScheme,
      title: 'Enable Camera Access',
      subtitle: currentSubtitle,
      isLoading: false,
      button: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              // Attempt to request permission again
              final result = await _viewModel.requestCameraPermission();
              
              if (!mounted) return;
              
              if (result == PermissionActionOutcome.granted) {
                _navigateToCamera();
              } else if (result == PermissionActionOutcome.permanentlyDenied) {
                // Update state to render the permanent denial view
                setState(() => _lastOutcome = PermissionActionOutcome.permanentlyDenied);
              } else {
                _showSnackbar(_viewModel.errorMessage ?? 'Camera access denied.');
                setState(() => _lastOutcome = result); // Rebuild to show updated message
              }
            },
            icon: const Icon(Icons.photo_camera),
            label: const Text('Grant Camera Access'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _navigateToManualEntry,
            child: const Text('Enter Receipt Manually'),
          ),
        ],
      ),
    );
  }

  // State 3: Permanently Denied or Feature Unavailable (Fallback to Manual)
  Widget _buildPermissionDeniedView(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildCentralView(
      colorScheme,
      title: 'Scanner Unavailable',
      subtitle: message,
      isLoading: false,
      button: Column(
        children: [
          // Only show 'Open App Settings' if the denial is permanent
          if (_lastOutcome == PermissionActionOutcome.permanentlyDenied) ...[
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open App Settings'),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: _navigateToManualEntry,
            child: const Text('Enter Receipt Manually'),
          ),
        ],
      ),
    );
  }
  
  // Generic snackbar helper
  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // --- MASTER BUILDER ---
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_viewModel.isCheckingPermissions || _lastOutcome == null) {
      return _buildLoadingView(colorScheme);
    } 
    
    switch (_lastOutcome!) {
      case PermissionActionOutcome.granted:
        // This case should be handled by navigation in _initialPermissionCheck
        // but as a fallback, show loading.
        return _buildLoadingView(colorScheme);
        
      case PermissionActionOutcome.permanentlyDenied:
        return _buildPermissionDeniedView('Camera access permanently denied. Please enable in settings.');
        
      case PermissionActionOutcome.error:
        return _buildPermissionDeniedView(_viewModel.errorMessage ?? 'Scanner feature is temporarily unavailable due to an error.');

      case PermissionActionOutcome.permissionDenied:
      case PermissionActionOutcome.selectionCancelled:
        // Show the view that prompts the user to grant permission or use manual entry
        return _buildPermissionRequestView();
    }
  }

  // Scaffold Template Builder
  Widget _buildCentralView(
    ColorScheme colorScheme, {
    required String title,
    String? subtitle,
    required bool isLoading,
    required Widget button,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner Setup'),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Container(
        color: colorScheme.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLoading ? Icons.cached : Icons.lock_outline, 
                  size: 80, 
                  color: colorScheme.secondary
                ),
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
                if (subtitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                if (isLoading)
                  LinearProgressIndicator(
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: colorScheme.secondaryContainer,
                    color: colorScheme.secondary,
                  )
                else
                  button,
              ],
            ),
          ),
        ),
      ),
    );
  }
}