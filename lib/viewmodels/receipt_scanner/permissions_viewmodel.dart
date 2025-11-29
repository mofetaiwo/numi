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

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<PermissionActionOutcome> checkInitialPermissions() async {
    _isCheckingPermissions = true;
    notifyListeners();

    final cameraStatus = await Permission.camera.status;
    await Permission.photos.status;

    _isCheckingPermissions = false;
    
    if (!_isDisposed) {
        notifyListeners();
    }

    /// Checks and Requests permission from the user to use the camera
    if (cameraStatus.isGranted) {
      return PermissionActionOutcome.granted;
    }
    return PermissionActionOutcome.permissionDenied;
  }

  Future<PermissionActionOutcome> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      return PermissionActionOutcome.granted;
    }

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

  /// Checks or requests permission from the user to access their camera roll
  Future<PermissionActionOutcome> handleGallerySelection() async {
    PermissionStatus status = await Permission.photos.status;

    if (!(status.isGranted || status.isLimited)) {
      if (status.isPermanentlyDenied || status.isRestricted) {
        return PermissionActionOutcome.permanentlyDenied;
      }

      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      return _uploadPicture();
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionActionOutcome.permanentlyDenied;
    } else {
      _errorMessage = 'Photo Gallery access denied.';
      return PermissionActionOutcome.permissionDenied;
    }
  }
  
  /// Launches the image picker, OCR, and sets the selectedReceipt state
  Future<PermissionActionOutcome> _uploadPicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        try {
        final imagePath = image.path;

        await _ocrService.initializeTesseract(); 
        final rawOcrText = await _ocrService.runOcr(imagePath);

        // Parse the OCR result into ReceiptModel
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