import 'package:flutter/material.dart';

class AppData extends ChangeNotifier {
  bool isUploading = false;

  double uploadProgress = 0.0;

  void updateS3StateUploading(bool state) {
    isUploading = state;
    notifyListeners();
  }

  void updateS3Progress(double state) {
    uploadProgress = state;
    notifyListeners();
  }
}
