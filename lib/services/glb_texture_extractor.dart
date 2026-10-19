import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class GlbTextureExtractorService {
  /// Extract embedded PNG/JPEG textures from a local .glb file
  static Future<List<Uint8List>> extractTexturesFromGlbFile(
    File glbFile,
  ) async {
    final bytes = await glbFile.readAsBytes();
    return extractTexturesFromGlbBytes(bytes);
  }

  /// Parse GLB binary format and extract all embedded image bytes
  static List<Uint8List> extractTexturesFromGlbBytes(Uint8List bytes) {
    if (bytes.length < 20) return [];

    final byteData = ByteData.sublistView(bytes);

    // Verify GLB magic (0x46546C67 = 'glTF')
    final magic = byteData.getUint32(0, Endian.little);
    if (magic != 0x46546C67) {
      throw Exception('File is not a valid binary .glb format.');
    }

    // Chunk 0: JSON
    final jsonChunkLength = byteData.getUint32(12, Endian.little);
    final jsonChunkType = byteData.getUint32(16, Endian.little);
    if (jsonChunkType != 0x4E4F534A) {
      throw Exception('Invalid GLB JSON header structure.');
    }

    final jsonBytes = bytes.sublist(20, 20 + jsonChunkLength);
    final jsonString = utf8.decode(jsonBytes);
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    final List<dynamic>? images = jsonMap['images'];
    if (images == null || images.isEmpty) {
      return []; // Clean empty list when no embedded textures exist
    }

    // Chunk 1: BIN (starts immediately after JSON chunk)
    final binChunkStart = 20 + jsonChunkLength;
    Uint8List? binBytes;

    if (bytes.length >= binChunkStart + 8) {
      final binChunkLength = byteData.getUint32(binChunkStart, Endian.little);
      final binDataStart = binChunkStart + 8;
      if (bytes.length >= binDataStart + binChunkLength) {
        binBytes = bytes.sublist(binDataStart, binDataStart + binChunkLength);
      }
    }

    final List<dynamic>? bufferViews = jsonMap['bufferViews'];
    final List<Uint8List> extractedTextures = [];

    for (final image in images) {
      if (image is! Map<String, dynamic>) continue;

      // Handle embedded base64 Data URI
      if (image.containsKey('uri') &&
          image['uri'].toString().startsWith('data:image')) {
        final uriStr = image['uri'].toString();
        final base64Data = uriStr.split(',').last;
        extractedTextures.add(base64Decode(base64Data));
        continue;
      }

      // Handle BufferView binary slice
      if (image.containsKey('bufferView') &&
          binBytes != null &&
          bufferViews != null) {
        final bufferViewIdx = image['bufferView'] as int;
        if (bufferViewIdx >= 0 && bufferViewIdx < bufferViews.length) {
          final bView = bufferViews[bufferViewIdx] as Map<String, dynamic>;
          final byteOffset = (bView['byteOffset'] as int?) ?? 0;
          final byteLength = bView['byteLength'] as int;

          if (byteOffset + byteLength <= binBytes.length) {
            final imgSlice = binBytes.sublist(
              byteOffset,
              byteOffset + byteLength,
            );
            extractedTextures.add(imgSlice);
          }
        }
      }
    }

    return extractedTextures;
  }

  /// Save ALL extracted textures directly to device gallery/downloads
  static Future<int> saveAllExtractedTexturesToGallery(
    List<Uint8List> texturesList,
    String modelTitle,
  ) async {
    if (texturesList.isEmpty) return 0;
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) return 0;
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = modelTitle.replaceAll(RegExp(r'[^\w\.-]'), '_');
      int savedCount = 0;

      for (int i = 0; i < texturesList.length; i++) {
        final fileName =
            '${sanitizedTitle}_Texture_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${tempDir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(texturesList[i], flush: true);

        await Gal.putImage(filePath, album: 'Jersey Studio Textures');
        savedCount++;
      }

      return savedCount;
    } catch (_) {
      return 0;
    }
  }
}
