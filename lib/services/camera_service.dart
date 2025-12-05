import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? cameras;

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }

  Future<File?> captureReceipt() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error capturing receipt: $e');
      return null;
    }
  }

  Future<File?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<String?> saveReceiptLocally(File receipt) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${appDir.path}/$fileName';

      await receipt.copy(filePath);
      return filePath;
    } catch (e) {
      print('Error saving receipt: $e');
      return null;
    }
  }
}