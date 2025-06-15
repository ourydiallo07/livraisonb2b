import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class Utils {
  static int expireTimer = 60;

  static String calculateSHA256(String input) {
    final bytes = utf8.encode(input); // Convert the string to bytes
    final digest = sha256.convert(bytes); // Calculate the SHA-256 hash
    return digest.toString(); // Return the hash as a hexadecimal string
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SpinKitRing(
              size: 140,
              color: Theme.of(context).primaryColor,
              duration: const Duration(seconds: 3),
            ),
          ),
        );
      },
    );
  }

  static Future<File> compressFile(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
    );

    if (result == null) {
      throw Exception('Compression failed');
    }

    return File(result.path);
  }
}

void displayMessage(msg, BuildContext context, error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(child: Text(msg)),
      backgroundColor: error ? Colors.red : Colors.green,
    ),
  );
}

void customPrint(dynamic message) {
  print('[CustomLog] $message');
}
