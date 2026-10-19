import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShowcaseScreenshotService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  /// Capture the 3D Showcase container and crop below top HUD with 3:4 portrait ratio (4:3 height-to-width)
  Future<Uint8List?> captureShowcase({
    double topCropRatio = 0.12,
    double aspectRatio = 3 / 4,
  }) async {
    final rawBytes = await _screenshotController.capture(
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );
    if (rawBytes == null) return null;
    return await cropToFrame(
      rawBytes,
      topCropRatio: topCropRatio,
      aspectRatio: aspectRatio,
    );
  }

  /// Crops full-height screenshot below top HUD to desired aspect ratio
  static Future<Uint8List> cropToFrame(
    Uint8List rawBytes, {
    double topCropRatio = 0.12,
    double aspectRatio = 3 / 4,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final imgWidth = image.width;
      final imgHeight = image.height;

      final targetWidth = imgWidth;
      // 3:4 portrait means height = width * 4 / 3 (1.33x width)
      int targetHeight = (targetWidth / aspectRatio).round();

      int top = (imgHeight * topCropRatio).round();
      if (top + targetHeight > imgHeight) {
        targetHeight = imgHeight - top;
      }
      if (targetHeight <= 0) targetHeight = imgHeight;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      );

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0,
          top.toDouble(),
          targetWidth.toDouble(),
          targetHeight.toDouble(),
        ),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(targetWidth, targetHeight);
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return rawBytes;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return rawBytes;
    }
  }

  /// Legacy helper for 1:1 cropping
  static Future<Uint8List> cropToSquare(
    Uint8List rawBytes, {
    double topCropRatio = 0.12,
  }) =>
      cropToFrame(rawBytes, topCropRatio: topCropRatio, aspectRatio: 1.0);

  /// Save showcase image bytes to device photo gallery
  Future<bool> saveToGallery(Uint8List imageBytes) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final requestGranted = await Gal.requestAccess(toAlbum: true);
        if (!requestGranted) return false;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'Jersey_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);

      await Gal.putImage(filePath, album: 'Jersey Checker');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share captured showcase image using native Android share sheet
  Future<void> shareShowcase(Uint8List imageBytes, {String? customText}) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Showcase_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes, flush: true);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(filePath)],
      text: customText ?? 'Created with Jersey Checker 3D',
      subject: 'Custom Jersey Showcase',
    );
  }
}
