import 'dart:io';
import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel =
      MethodChannel('com.bobziex.jerseychecker/media_scanner');

  /// Notifies Android's MediaScanner / MediaStore about a new file so it shows up
  /// immediately in Android's system file picker, DocumentsProvider, and gallery.
  static Future<void> scanFile(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scanFile', {'path': filePath});
    } catch (_) {}
  }
}
