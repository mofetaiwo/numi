import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 
import 'receipt_verification.dart'; 
import '../../viewmodels/receipt_scanner/permissions_viewmodel.dart';
import '../../models/receipt_model.dart'; 

/// Renders the live camera view and handles the photo capture
class CameraViewPage extends StatefulWidget {
  // The PermissionsViewModel is passed from the PermissionsPage
  // and holds the state and logic for OCR processing.
  final PermissionsViewModel viewModel;

  const CameraViewPage({required this.viewModel, super.key});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.viewModel.addListener(_onViewModelChanged); 
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.viewModel.removeListener(_onViewModelChanged);
    _controller?.dispose();
    super.dispose();
  }
  
  void _onViewModelChanged() {
    setState(() {});
    
    // Check if processing is done and we have a receipt to navigate
    if (!widget.viewModel.isProcessing && widget.viewModel.selectedReceipt != null) {
      _navigateToVerification(widget.viewModel.selectedReceipt!);
    } else if (!widget.viewModel.isProcessing && widget.viewModel.errorMessage != null) {
      _showSnackbar(widget.viewModel.errorMessage!);
    }
  }

  // Reinitialize camera when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraReady) return;
    if (_controller == null) return;
    
    final CameraController cameraController = _controller!;
    
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Initializes the camera controller with the first available camera.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available.');
      }
      // Use the first camera (typically the back camera)
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error initializing camera: $e');
      }
      setState(() {
        _isCameraReady = false;
      });
    }

    await _controller!.initialize();
  }

  /// Handles the image capture and triggers the OCR process via the ViewModel.
  void _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showSnackbar('Camera not ready.');
      return;
    }

    try {
      final XFile image = await _controller!.takePicture();
      
     await widget.viewModel.runOcrOnCapture(image.path); 
      
    } on CameraException catch (e) {
      _showSnackbar('Capture error: ${e.code}');
    } catch (e) {
      _showSnackbar('An unknown error occurred during capture.');
    }
  }

  /// Displays a Snackbar with an error message if an error occurs.
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

  /// Navigates to the verification screen using the processed data.
  void _navigateToVerification(ReceiptModel receipt) {
     Navigator.of(context).pushReplacement( 
        MaterialPageRoute(
            builder: (context) => ReceiptVerificationPage(receiptData: receipt),
        ),
    );
    // Clear the error state in the VM after successful navigation
    widget.viewModel.clearProcessingState(); 
  }

  // Helper method to display the loading overlay when OCR is running
  Widget _buildProcessingOverlay(ColorScheme colorScheme) {
    return Container(
      color: Colors.black54, // Dark overlay
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.secondary),
          const SizedBox(height: 20),
          const Text(
            'Scanning Receipt...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Builder(
        builder: (context) {
          if (!_isCameraReady || _controller == null || !_controller!.value.isInitialized) {
            // Show loading indicator while camera initializes
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Initializing Camera...'),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),

              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Align Receipt Here',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: FloatingActionButton(
                    heroTag: 'captureBtn', 
                    onPressed: widget.viewModel.isProcessing ? null : _onCapturePressed,
                    backgroundColor: widget.viewModel.isProcessing ? Colors.grey : colorScheme.primary,
                    child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
                  ),
                ),
              ),
              
              if (widget.viewModel.isProcessing) 
                _buildProcessingOverlay(colorScheme),
            ],
          );
        },
      ),
    );
  }
}