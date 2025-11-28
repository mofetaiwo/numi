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
  final TesseractService _ocrService = TesseractService();

  bool _isCheckingPermissions = true;
  bool get isCheckingPermissions => _isCheckingPermissions;

  // Observable state for the selected ReceiptModel (used after OCR processing)
  ReceiptModel? _selectedReceipt;
  ReceiptModel? get selectedReceipt => _selectedReceipt;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true; // Set the flag when disposed
    super.dispose();
  }

  // Override notifyListeners to check the flag
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Checks initial permissions
  Future<PermissionActionOutcome> checkInitialPermissions() async {
    _isCheckingPermissions = true;
    notifyListeners();

    final cameraStatus = await Permission.camera.status;
    await Permission.photos.status;

    _isCheckingPermissions = false;
    
    if (!_isDisposed) {
        notifyListeners();
    }

    // If camera is granted, suggest auto-launching (if the view handles it)
    if (cameraStatus.isGranted) {
      return PermissionActionOutcome.granted;
    }
    return PermissionActionOutcome.permissionDenied;
  }

  /// Requests or confirms Camera permission and returns the outcome.
  Future<PermissionActionOutcome> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      return PermissionActionOutcome.granted;
    }

    // Request permission if not granted
    PermissionStatus newStatus = await Permission.camera.request();

    if (newStatus.isGranted) {
      return PermissionActionOutcome.granted;
    } else if (newStatus.isPermanentlyDenied) {
      return PermissionActionOutcome.permanentlyDenied;
    } else {
      _errorMessage = 'Camera access denied.';
      return PermissionActionOutcome.permissionDenied;
    }
  }

  /// Requests or confirms Gallery permission and launches the picker if successful.
  /// If an image is selected, it mocks the OCR result and prepares the ReceiptModel.
  Future<PermissionActionOutcome> handleGallerySelection() async {
    PermissionStatus status = await Permission.photos.status;

    // 1. Check if permission is already sufficient
    if (!(status.isGranted || status.isLimited)) {
      // Check for permanent blocks before attempting a request
      if (status.isPermanentlyDenied || status.isRestricted) {
        return PermissionActionOutcome.permanentlyDenied;
      }

      // Request permission
      status = await Permission.photos.request();
    }

    // 2. Handle the result of the permission request
    if (status.isGranted || status.isLimited) {
      return _uploadPicture();
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionActionOutcome.permanentlyDenied;
    } else {
      _errorMessage = 'Photo Gallery access denied.';
      return PermissionActionOutcome.permissionDenied;
    }
  }
  
  /// Launches the image picker, mocks OCR, and sets the selectedReceipt state.
  Future<PermissionActionOutcome> _uploadPicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        try {
        final imagePath = image.path;

        // Ensure Tesseract is initialized (if the image picker is the first action)
        await _ocrService.initializeTesseract(); 

        // 3. Run OCR using the selected image path
        final rawOcrText = await _ocrService.runOcr(imagePath);

        // 4. Parse the OCR result into ReceiptModel
        _selectedReceipt = _ocrService.parseOcrResult(rawOcrText, imagePath);

        notifyListeners();
        return PermissionActionOutcome.granted;
      } catch (e) {
        return PermissionActionOutcome.error;
      }

      } else {
        _errorMessage = 'No image selected.';
        return PermissionActionOutcome.selectionCancelled;
      }
    } catch (e) {
      _errorMessage = 'Error selecting image: $e';
      return PermissionActionOutcome.error;
    }
  }
}