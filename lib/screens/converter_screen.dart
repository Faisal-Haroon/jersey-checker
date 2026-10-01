import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/selected_file.dart';
import '../services/bytes_converter_service.dart';
import '../theme/app_theme.dart';

const Color _kGreen = Color(0xFF10B981);
const Color _kGreenBg = Color(0xFFECFDF5);
const Color _kGreenBorder = Color(0xFFD1FAE5);

enum ConversionMode { pngToBytes, bytesToPng }

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    required this.files,
    required this.onPickFiles,
    required this.onPickBytesFiles,
    required this.onClearAll,
    required this.onRemoveFile,
  });

  final List<SelectedJerseyFile> files;
  final VoidCallback onPickFiles;
  final VoidCallback onPickBytesFiles;
  final VoidCallback onClearAll;
  final ValueChanged<SelectedJerseyFile> onRemoveFile;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  ConversionMode _mode = ConversionMode.pngToBytes;
  bool _isConverting = false;
  bool _isDone = false;
  String? _statusMessage;
  String? _customOutputDir;

  @override
  void initState() {
    super.initState();
    _initDefaultDirectory();
  }

  Future<void> _initDefaultDirectory() async {
    final defaultDir = await _getDefaultJerseyStudioDir();
    if (mounted && defaultDir != null) {
      setState(() {
        _customOutputDir = defaultDir.path;
      });
    }
  }

  Future<Directory?> _getDefaultJerseyStudioDir() async {
    try {
      Directory? baseDownloads;
      if (Platform.isAndroid) {
        baseDownloads = Directory('/storage/emulated/0/Download');
        if (!await baseDownloads.exists()) {
          baseDownloads = await getDownloadsDirectory();
        }
      } else {
        baseDownloads = await getDownloadsDirectory();
      }

      if (baseDownloads != null) {
        final target = Directory(path.join(baseDownloads.path, 'JerseyStudio'));
        if (!await target.exists()) {
          await target.create(recursive: true);
        }
        return target;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleConvert() async {
    if (widget.files.isEmpty) {
      _showSnackBar(_mode == ConversionMode.pngToBytes
          ? 'Select at least one PNG file first.'
          : 'Select at least one file first.');
      return;
    }

    String? outputDir = _customOutputDir;
    if (outputDir == null) {
      final defaultDir = await _getDefaultJerseyStudioDir();
      outputDir = defaultDir?.path;
    }

    if (!mounted || outputDir == null) {
      _showSnackBar('Could not access Download folder.');
      return;
    }

    setState(() {
      _customOutputDir = outputDir;
      _isConverting = true;
      _isDone = false;
      _statusMessage = 'Converting 0/${widget.files.length}...';
    });

    final result = _mode == ConversionMode.pngToBytes
        ? await BytesConverterService.convertBatch(
            files: widget.files,
            outputDirectoryPath: outputDir,
            onProgress: (current, total) {
              if (mounted) {
                setState(() {
                  _statusMessage = 'Converting $current/$total...';
                });
              }
            },
          )
        : await BytesConverterService.convertBytesToPngBatch(
            files: widget.files,
            outputDirectoryPath: outputDir,
            onProgress: (current, total) {
              if (mounted) {
                setState(() {
                  _statusMessage = 'Converting $current/$total...';
                });
              }
            },
          );

    if (!mounted) return;
    setState(() {
      _isConverting = false;
      _isDone = true;
      _statusMessage = result.statusMessage;
    });

    _showSnackBar(result.statusMessage);
  }

  void _showRenameDialog(SelectedJerseyFile file) {
    final rawName = path.basenameWithoutExtension(file.customName);
    final controller = TextEditingController(text: rawName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('Rename File', style: TextStyle(color: AppTheme.textMain)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  final ext = _mode == ConversionMode.pngToBytes ? '.png' : '';
                  file.customName = '$newName$ext';
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isPngToBytes = _mode == ConversionMode.pngToBytes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        // Mode Switcher Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isConverting
                      ? null
                      : () {
                          if (_mode != ConversionMode.pngToBytes) {
                            setState(() {
                              _mode = ConversionMode.pngToBytes;
                              _isDone = false;
                              _statusMessage = null;
                            });
                            widget.onClearAll();
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isPngToBytes ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: isPngToBytes ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PNG → File',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isPngToBytes ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _isConverting
                      ? null
                      : () {
                          if (_mode != ConversionMode.bytesToPng) {
                            setState(() {
                              _mode = ConversionMode.bytesToPng;
                              _isDone = false;
                              _statusMessage = null;
                            });
                            widget.onClearAll();
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: !isPngToBytes ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 18,
                          color: !isPngToBytes ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'File → PNG',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: !isPngToBytes ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOOLKIT',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                letterSpacing: 2,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isPngToBytes ? 'PNG to File' : 'File to PNG',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isPngToBytes
                  ? 'Convert PNG images to binary format'
                  : 'Extract PNG images from game files',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isConverting
              ? null
              : (isPngToBytes ? widget.onPickFiles : widget.onPickBytesFiles),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPngToBytes
                        ? Icons.add_photo_alternate_rounded
                        : Icons.file_open_rounded,
                    color: AppTheme.primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isPngToBytes ? 'Tap to Add PNG Files' : 'Tap to Add Files',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 3),
                Text(
                  isPngToBytes
                      ? 'Select one or more PNG image files'
                      : 'Select one or more binary files',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (widget.files.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${widget.files.length} FILES ADDED',
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue),
                ),
              ),
              TextButton.icon(
                onPressed: _isConverting ? null : widget.onClearAll,
                icon: const Icon(Icons.delete_outline, size: 15, color: AppTheme.textMuted),
                label: const Text('Clear all',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.files.map((file) {
            final rawName = path.basenameWithoutExtension(file.customName);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                      isPngToBytes ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20),
                ),
                title: Text(rawName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        fontSize: 14)),
                subtitle: Text('${file.name} • ${file.formattedSize}',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed:
                          _isConverting ? null : () => _showRenameDialog(file),
                      tooltip: 'Rename',
                      icon: const Icon(Icons.edit_rounded,
                          size: 19, color: AppTheme.textMuted),
                    ),
                    IconButton(
                      onPressed:
                          _isConverting ? null : () => widget.onRemoveFile(file),
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close_rounded,
                          size: 19, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SAVE LOCATION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.textSubtle)),
              const SizedBox(height: 5),
              Text(
                _customOutputDir ?? 'Download/JerseyStudio',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_statusMessage != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isDone ? _kGreenBg : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _isDone ? _kGreenBorder : AppTheme.border),
            ),
            child: Row(
              children: [
                if (_isConverting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: _kGreen),
                  )
                else
                  Icon(
                      _isDone
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 20,
                      color: _isDone ? _kGreen : AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_statusMessage!,
                      style: TextStyle(
                        color: _isDone ? _kGreen : AppTheme.textMuted,
                        fontWeight:
                            _isDone ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isConverting
                ? []
                : [
                    BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isConverting ? null : _handleConvert,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                disabledBackgroundColor:
                    AppTheme.primaryBlue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isConverting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Converting...',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                            isPngToBytes
                                ? 'Convert to File'
                                : 'Convert to PNG',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

