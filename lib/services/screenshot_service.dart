import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShowcaseScreenshotService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  /// Capture the 3D Showcase container with watermark overlay
  Future<Uint8List?> captureShowcase() async {
    return await _screenshotController.capture(
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );
  }

  /// Save showcase image bytes to device photo gallery
  Future<bool> saveToGallery(Uint8List imageBytes) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final requestGranted = await Gal.requestAccess(toAlbum: true);
        if (!requestGranted) return false;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Jersey_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);

      await Gal.putImage(filePath, album: 'Jersey Studio');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share captured showcase image using native Android share sheet
  Future<void> shareShowcase(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'Showcase_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes, flush: true);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Created with Jersey Studio 3D',
      subject: 'Custom Jersey Showcase',
    );
  }
}
