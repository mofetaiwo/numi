import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/receipt_model.dart';
import '../../services/receipt_ocr_service.dart';

/// Types of Permissions
enum PermissionActionOutcome {
  granted,
  permissionDenied,
  permanentlyDenied,
  selectionCancelled,
  error,
}

/// ViewModel for handling camera and photo gallery access permissions
class PermissionsViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  // Using the injected service for Tesseract operations
  final TesseractService _ocrService = TesseractService(); 

  bool _isProcessing = false; // State for showing OCR loading overlay
  bool get isProcessing => _isProcessing;

  // Observable state for the selected ReceiptModel (used after OCR processing)
  ReceiptModel? _selectedReceipt;
  ReceiptModel? get selectedReceipt => _selectedReceipt;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  /// Sets the initial state of the receipt to 'Processing...' before starting
  /// any OCR operation.
  void setInitialProcessingState(String imagePath) {
    _selectedReceipt = ReceiptModel.empty(imagePath);
    notifyListeners();
  }

  void clearProcessingState() {
    _selectedReceipt = null;
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Requests or checks the current Camera permission status.
  /// This is the dedicated method for the PermissionsPage to call.
  Future<PermissionActionOutcome> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    // Request if not granted
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      return PermissionActionOutcome.granted;
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      _errorMessage = 'Camera access permanently denied. Please enable in settings.';
      return PermissionActionOutcome.permanentlyDenied;
    } else {
      _errorMessage = 'Camera access denied. Cannot use live scanner.';
      return PermissionActionOutcome.permissionDenied;
    }
  }

  /// Handles the camera capture file path and runs the OCR process.
  Future<PermissionActionOutcome> runOcrOnCapture(String imagePath) async {
    _setProcessing(true);
    _errorMessage = null;
    try {
      // Set initial processing state (showing 'Processing...' on next screen)
      setInitialProcessingState(imagePath);
      
      await _ocrService.initializeTesseract(); 
      
      // Run OCR
      final rawOcrText = await _ocrService.runOcr(imagePath);
      _selectedReceipt = _ocrService.parseOcrResult(rawOcrText, imagePath);

      _setProcessing(false);
      return PermissionActionOutcome.granted;

    } catch (e) {
      _errorMessage = 'Error during OCR: ${e.toString()}';
      _selectedReceipt = null;
      _setProcessing(false);
      return PermissionActionOutcome.error;
    }
  }

  /// Checks gallery permission, launches the image picker, and runs the OCR process.
  Future<PermissionActionOutcome> requestGalleryPermissionAndUpload() async {
    _errorMessage = null;
    
    // Check current Photos/Gallery status
    PermissionStatus status = await Permission.photos.status;

    // Request if not granted/limited
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      _errorMessage = 'Photo Gallery access permanently denied.';
      return PermissionActionOutcome.permanentlyDenied;
    }

    if (status.isGranted || status.isLimited) {
      return _uploadPicture();
    } else {
      _errorMessage = 'Photo Gallery access denied.';
      return PermissionActionOutcome.permissionDenied;
    }
  }
  
  /// Launches the image picker, OCR, and sets the selectedReceipt state
  Future<PermissionActionOutcome> _uploadPicture() async {
    _setProcessing(true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final imagePath = image.path;
        
        return runOcrOnCapture(imagePath);

      } else {
        // User cancelled image selection
        _errorMessage = 'No image selected.';
        _selectedReceipt = null;
        _setProcessing(false); // Stop processing if selection cancelled
        notifyListeners();
        return PermissionActionOutcome.selectionCancelled;
      }

    } catch (e) {
      // General failure during image picking
      _errorMessage = 'Image selection failed: ${e.toString()}';
      _selectedReceipt = null;
      _setProcessing(false); // Stop processing on error
      notifyListeners();
      return PermissionActionOutcome.error;
    }
  }
}