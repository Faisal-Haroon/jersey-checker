import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/selected_file.dart';
import '../services/ad_service.dart';
import '../services/bytes_converter_service.dart';
import '../services/jersey_preset_service.dart';
import '../services/texture_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

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
    this.initialMode = ConversionMode.pngToBytes,
    this.onBack,
  });

  final List<SelectedJerseyFile> files;
  final VoidCallback onPickFiles;
  final VoidCallback onPickBytesFiles;
  final VoidCallback onClearAll;
  final ValueChanged<SelectedJerseyFile> onRemoveFile;
  final ConversionMode initialMode;
  final VoidCallback? onBack;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late ConversionMode _mode;
  bool _isConverting = false;
  bool _isDone = false;
  String? _statusMessage;
  String? _customOutputDir;
  JerseyCategoryPreset? _selectedCategory;
  JerseyTeamPreset? _selectedTeam;
  int _selectedTargetFileIndex = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initDefaultDirectory();
  }

  @override
  void didUpdateWidget(covariant ConverterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      setState(() {
        _mode = widget.initialMode;
        _isDone = false;
        _statusMessage = null;
        _selectedCategory = null;
        _selectedTeam = null;
        _selectedTargetFileIndex = 0;
      });
      _initDefaultDirectory();
    } else if (oldWidget.files.isEmpty && widget.files.isNotEmpty) {
      // Fresh files added after conversion or clear -> reset presets
      setState(() {
        _selectedCategory = null;
        _selectedTeam = null;
        _selectedTargetFileIndex = 0;
      });
    } else if (widget.files.isEmpty &&
        (oldWidget.files.isNotEmpty ||
            _selectedCategory != null ||
            _selectedTeam != null)) {
      setState(() {
        _selectedCategory = null;
        _selectedTeam = null;
        _selectedTargetFileIndex = 0;
      });
    }
  }

  Future<void> _initDefaultDirectory() async {
    final defaultDir = await _getDefaultJerseyStudioDir();
    if (mounted && defaultDir != null) {
      setState(() {
        _customOutputDir = defaultDir.path;
      });
    }
  }

  /// Returns the base JerseyStudio root folder (/storage/emulated/0/Download/JerseyStudio).
  Future<Directory?> _getBaseJerseyStudioDir() async {
    final candidates = <String>[];

    if (Platform.isAndroid) {
      candidates.add('/storage/emulated/0/Download/JerseyStudio');
    }

    try {
      final dl = await getDownloadsDirectory();
      if (dl != null) candidates.add(path.join(dl.path, 'JerseyStudio'));
    } catch (_) {}

    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) candidates.add(path.join(ext.path, 'JerseyStudio'));
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      candidates.add(path.join(docs.path, 'JerseyStudio'));
    } catch (_) {}

    for (final p in candidates) {
      try {
        final dir = Directory(p);
        if (!await dir.exists()) await dir.create(recursive: true);
        // Verify write access with probe
        final probe = File(
          path.join(dir.path, '.probe_${DateTime.now().millisecondsSinceEpoch}'),
        );
        await probe.writeAsString('probe');
        await probe.delete();
        return dir;
      } catch (_) {}
    }
    return null;
  }

  /// Returns the subfolder inside JerseyStudio based on conversion mode:
  ///   - PNG to File -> Download/JerseyStudio/Files
  ///   - File to PNG -> Download/JerseyStudio/PNG
  Future<Directory?> _getDefaultJerseyStudioDir({ConversionMode? mode}) async {
    final base = await _getBaseJerseyStudioDir();
    if (base == null) return null;

    final targetMode = mode ?? _mode;
    final subName = targetMode == ConversionMode.pngToBytes ? 'Files' : 'PNG';
    final subDir = Directory(path.join(base.path, subName));

    try {
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }
      return subDir;
    } catch (_) {
      return base;
    }
  }

  Future<void> _pickFromJerseyStudio() async {
    final baseDir = await _getBaseJerseyStudioDir();
    if (baseDir == null) {
      _showSnackBar('Cannot access JerseyStudio directory.');
      return;
    }

    // Look in JerseyStudio/Files first (where binary files are saved)
    final filesDir = Directory(path.join(baseDir.path, 'Files'));
    final loadedFiles = <SelectedJerseyFile>[];

    if (await filesDir.exists()) {
      loadedFiles.addAll(
        await TextureService.loadFilesFromDirectory(filesDir.path),
      );
    }

    // Also include files from base JerseyStudio for backward compatibility
    final rootFiles = await TextureService.loadFilesFromDirectory(baseDir.path);
    for (final f in rootFiles) {
      if (!loadedFiles.any((item) => item.name == f.name)) {
        loadedFiles.add(f);
      }
    }

    if (!mounted) return;

    if (loadedFiles.isEmpty) {
      _showSnackBar(
        'No saved jersey files found in JerseyStudio yet.\nConvert some PNG textures first!',
      );
      return;
    }

    final selected = await showModalBottomSheet<List<SelectedJerseyFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _JerseyStudioFolderSheet(files: loadedFiles),
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      int added = 0;
      bool reachedLimit = false;
      setState(() {
        for (final item in selected) {
          if (widget.files.length >= 5) {
            reachedLimit = true;
            break;
          }
          if (!widget.files.any((f) => f.name == item.name)) {
            widget.files.add(item);
            added++;
          }
        }
      });
      if (reachedLimit) {
        _showSnackBar('Maximum 5 files allowed per conversion batch.');
      } else {
        _showSnackBar('Added $added file(s) from JerseyStudio.');
      }
    }
  }

  /// Show bottom sheet so user can choose WHERE to load files from.
  /// This solves the problem where files downloaded to any folder won't
  /// show up in the basic file picker's initial view.
  Future<void> _showFileSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Load Jersey Files From…',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick files shared by others or saved anywhere on your device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 18),

                // Option 1: System File Picker
                _SourceOption(
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.primaryBlue,
                  title: 'Browse Files (Any Folder)',
                  subtitle: 'Use file picker — navigate to Downloads, WhatsApp or any folder',
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onPickBytesFiles();
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: JerseyStudio folder
                _SourceOption(
                  icon: Icons.folder_special_rounded,
                  color: _kGreen,
                  title: 'JerseyStudio Folder',
                  subtitle:
                      'Load saved files (Download/JerseyStudio/Files)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromJerseyStudio();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConvert() async {
    if (widget.files.isEmpty) {
      _showSnackBar(
        _mode == ConversionMode.pngToBytes
            ? 'Select at least one PNG file first.'
            : 'Select at least one file first.',
      );
      return;
    }

    String? outputDir = _customOutputDir;
    if (outputDir == null) {
      final defaultDir = await _getDefaultJerseyStudioDir();
      outputDir = defaultDir?.path;
    }

    if (!mounted || outputDir == null) {
      _showSnackBar(
        'Could not access storage.\n'
        'Please grant Storage permission in Settings → Apps → Jersey Checker Studio → Permissions.',
      );
      return;
    }

    setState(() {
      _customOutputDir = outputDir;
      _isConverting = true;
      _isDone = false;
      _statusMessage = null;
    });

    final result = await showDialog<ConversionResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConversionProgressDialog(
        mode: _mode,
        files: List.from(widget.files),
        outputDir: outputDir!,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isConverting = false;
      if (result != null) {
        _isDone = result.isSuccess;
        _statusMessage = result.statusMessage;
      }
    });

    if (result != null && result.isSuccess) {
      setState(() {
        _selectedCategory = null;
        _selectedTeam = null;
        _selectedTargetFileIndex = 0;
      });
      widget.onClearAll();
      _showSnackBar(result.statusMessage);
    }
  }

  void _showRenameDialog(SelectedJerseyFile file) {
    final rawName = path.basenameWithoutExtension(file.customName);
    final controller = TextEditingController(text: rawName);
    JerseyCategoryPreset? dialogCategory = _selectedCategory;
    JerseyTeamPreset? dialogTeam = _selectedTeam;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rename File',
                  style: TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mode == ConversionMode.pngToBytes) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.sports_cricket_rounded,
                                size: 15,
                                color: AppTheme.primaryBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Quick Game Preset',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'League / Tournament',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<JerseyCategoryPreset>(
                                value: dialogCategory,
                                isExpanded: true,
                                items: JerseyPresetService.categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(
                                      cat.displayName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (cat) {
                                  setDialogState(() {
                                    dialogCategory = cat;
                                    dialogTeam = null;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Team & Game Code',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<JerseyTeamPreset>(
                                value: dialogTeam,
                                isExpanded: true,
                                hint: Text(
                                  dialogCategory == null
                                      ? 'Select tournament first'
                                      : 'Select team',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                items: dialogCategory?.teams.map((team) {
                                  return DropdownMenuItem(
                                    value: team,
                                    child: Text(
                                      '${team.displayName} (${team.gameCode})',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: dialogCategory == null
                                    ? null
                                    : (team) {
                                        if (team != null) {
                                          setDialogState(() {
                                            dialogTeam = team;
                                            controller.text = team.gameCode;
                                          });
                                        }
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Custom File Name',
                      hintText: 'e.g. pak24 or kk24',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mode == ConversionMode.pngToBytes
                        ? 'Target game file: "${controller.text}"'
                        : 'Extracted image: "${controller.text}.png"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
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
                      final ext =
                          _mode == ConversionMode.pngToBytes ? '.png' : '';
                      file.customName = '$newName$ext';
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports_cricket_rounded,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Jersey Auto-Naming',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      'Official game code (e.g. pak24, kk24) required for custom jerseys',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-file target selector if more than 1 file
          if (widget.files.length > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Apply Preset To: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedTargetFileIndex < widget.files.length
                            ? _selectedTargetFileIndex
                            : 0,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                        items: widget.files.asMap().entries.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(
                              'File ${e.key + 1}: ${e.value.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (idx) {
                          if (idx != null) {
                            setState(() => _selectedTargetFileIndex = idx);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Dropdown 1: Tournament / League
          InputDecorator(
            decoration: InputDecoration(
              labelText: '1. Select League / Tournament',
              labelStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<JerseyCategoryPreset>(
                value: _selectedCategory,
                isExpanded: true,
                items: JerseyPresetService.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedTeam = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown 2: Team Name & Game Code
          InputDecorator(
            decoration: InputDecoration(
              labelText: '2. Select Team Name',
              labelStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<JerseyTeamPreset>(
                value: _selectedTeam,
                isExpanded: true,
                hint: Text(
                  _selectedCategory == null
                      ? 'First select a tournament above'
                      : '2. Select Team Jersey Code',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                ),
                items: _selectedCategory?.teams.map((team) {
                  return DropdownMenuItem(
                    value: team,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            team.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            team.gameCode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _selectedCategory == null
                    ? null
                    : (team) {
                        if (team != null && widget.files.isNotEmpty) {
                          setState(() {
                            _selectedTeam = team;
                            final targetIdx =
                                _selectedTargetFileIndex < widget.files.length
                                ? _selectedTargetFileIndex
                                : 0;
                            widget.files[targetIdx].customName =
                                '${team.gameCode}.png';
                          });
                        }
                      },
              ),
            ),
          ),

          if (_selectedTeam != null && widget.files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreenBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: _kGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target Game File: "${_selectedTeam!.gameCode}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final targetIdx =
                          _selectedTargetFileIndex < widget.files.length
                          ? _selectedTargetFileIndex
                          : 0;
                      _showRenameDialog(widget.files[targetIdx]);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Edit Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      children: [
        // Active Mode Indicator (Switcher removed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isPngToBytes
                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                      : _kGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPngToBytes
                        ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                        : _kGreenBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPngToBytes ? AppTheme.primaryBlue : _kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPngToBytes
                            ? Icons.swap_horiz_rounded
                            : Icons.image_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPngToBytes ? 'PNG → File' : 'File → PNG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isPngToBytes
                                  ? AppTheme.primaryBlue
                                  : _kGreen,
                            ),
                          ),
                          Text(
                            isPngToBytes
                                ? 'Convert PNG textures into Jersey files'
                                : 'Extract PNG textures from Jersey files',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _isConverting
                    ? null
                    : () {
                        if (widget.files.length >= 5) {
                          _showSnackBar(
                            'Maximum 5 files reached. Convert or clear files first.',
                          );
                          return;
                        }
                        if (isPngToBytes) {
                          setState(() {
                            _selectedCategory = null;
                            _selectedTeam = null;
                            _selectedTargetFileIndex = 0;
                          });
                          widget.onPickFiles();
                        } else {
                          _showFileSourceSheet();
                        }
                      },
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
                        isPngToBytes
                            ? 'Tap to Add PNG Files'
                            : 'Tap to Add Files',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPngToBytes
                            ? 'Select up to 5 PNG image files (Max 5)'
                            : 'Select up to 5 jersey files (Max 5)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${widget.files.length}/5 FILES ADDED',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isConverting
                          ? null
                          : () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedTeam = null;
                                _selectedTargetFileIndex = 0;
                              });
                              widget.onClearAll();
                            },
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: AppTheme.textMuted,
                      ),
                      label: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isPngToBytes) _buildPresetCard(),
                ...widget.files.map((file) {
                  final rawName = path.basenameWithoutExtension(
                    file.customName,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isPngToBytes
                                ? Icons.image_rounded
                                : Icons.insert_drive_file_rounded,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rawName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${file.name} • ${file.formattedSize}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isPngToBytes) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '🎮 Game File: $rawName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _isConverting
                                  ? null
                                  : () => _showRenameDialog(file),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: _isConverting
                                  ? null
                                  : () => widget.onRemoveFile(file),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAVE LOCATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _customOutputDir ??
                          (_mode == ConversionMode.pngToBytes
                              ? 'Download/JerseyStudio/Files'
                              : 'Download/JerseyStudio/PNG'),
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
                      color: _isDone ? _kGreenBorder : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isConverting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _kGreen,
                          ),
                        )
                      else
                        Icon(
                          _isDone
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 20,
                          color: _isDone ? _kGreen : AppTheme.primaryBlue,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _isDone ? _kGreen : AppTheme.textMuted,
                            fontWeight: _isDone
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
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
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isConverting ? null : _handleConvert,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      disabledBackgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isConverting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Converting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPngToBytes
                                    ? 'Convert to File'
                                    : 'Convert to PNG',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
    );
  }
}

/// Modal Dialog that shows an MREC ad at top, followed by a smooth
/// 4-second conversion progress bar and status animations.
class _ConversionProgressDialog extends StatefulWidget {
  const _ConversionProgressDialog({
    required this.mode,
    required this.files,
    required this.outputDir,
  });

  final ConversionMode mode;
  final List<SelectedJerseyFile> files;
  final String outputDir;

  @override
  State<_ConversionProgressDialog> createState() =>
      _ConversionProgressDialogState();
}

class _ConversionProgressDialogState extends State<_ConversionProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  bool _isFinished = false;
  bool _isSuccess = false;
  String _statusText = 'Preparing Conversion...';
  String _detailText = 'Reading input files...';
  ConversionResult? _result;

  @override
  void initState() {
    super.initState();
    // 4.2 seconds smooth progress animation for high viewability
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        if (!mounted || _isFinished) return;
        final val = _progressAnim.value;
        setState(() {
          if (val < 0.25) {
            _statusText = 'Preparing Textures...';
            _detailText = 'Reading ${widget.files.length} selected file(s)...';
          } else if (val < 0.65) {
            _statusText = widget.mode == ConversionMode.pngToBytes
                ? 'Converting to Game File...'
                : 'Extracting PNG Textures...';
            _detailText = 'Processing texture buffers & headers...';
          } else {
            final subName =
                widget.mode == ConversionMode.pngToBytes ? 'Files' : 'PNG';
            _statusText = 'Finalizing Output...';
            _detailText = 'Writing to Download/JerseyStudio/$subName...';
          }
        });
      });

    _animController.forward();
    _startConversion();
  }

  Future<void> _startConversion() async {
    try {
      final convertFuture = widget.mode == ConversionMode.pngToBytes
          ? BytesConverterService.convertBatch(
              files: widget.files,
              outputDirectoryPath: widget.outputDir,
            )
          : BytesConverterService.convertBytesToPngBatch(
              files: widget.files,
              outputDirectoryPath: widget.outputDir,
            );

      final results = await Future.wait([
        convertFuture,
        Future.delayed(const Duration(milliseconds: 4200)),
      ]);

      if (!mounted) return;
      final res = results[0] as ConversionResult;
      setState(() {
        _result = res;
        _isFinished = true;
        _isSuccess = res.isSuccess;
        _statusText = _isSuccess ? 'Conversion Complete!' : 'Conversion Error';
        _detailText = res.statusMessage;
      });

      // Natural interstitial ad check
      AdService.instance.showInterstitialIfReady();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFinished = true;
        _isSuccess = false;
        _statusText = 'Error Occurred';
        _detailText = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPngToBytes = widget.mode == ConversionMode.pngToBytes;
    final progress = _isFinished ? 1.0 : _progressAnim.value;
    final pct = (progress * 100).toInt();

    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── TOP MREC AD ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: const AppMrecWidget(),
              ),
              const SizedBox(height: 16),

              // ── STATUS HEADER ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _isFinished
                          ? (_isSuccess
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : AppTheme.errorRed.withValues(alpha: 0.12))
                          : (isPngToBytes
                              ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: _isFinished
                        ? Icon(
                            _isSuccess
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            size: 20,
                            color: _isSuccess
                                ? const Color(0xFF10B981)
                                : AppTheme.errorRed,
                          )
                        : SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isPngToBytes
                                  ? AppTheme.primaryBlue
                                  : const Color(0xFF10B981),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _isFinished
                            ? (_isSuccess
                                ? const Color(0xFF10B981)
                                : AppTheme.errorRed)
                            : AppTheme.textMain,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _isFinished
                          ? const Color(0xFF10B981)
                          : (isPngToBytes
                              ? AppTheme.primaryBlue
                              : const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── PROGRESS BAR ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(
                    _isFinished
                        ? (_isSuccess
                            ? const Color(0xFF10B981)
                            : AppTheme.errorRed)
                        : (isPngToBytes
                            ? AppTheme.primaryBlue
                            : const Color(0xFF10B981)),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),

              // ── DETAIL TEXT ───────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _detailText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── ACTION BUTTON / WAITING INDICATOR ─────────────────
              if (!_isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Converting... please wait a few seconds',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _result),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isSuccess
                          ? const Color(0xFF10B981)
                          : AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JerseyStudioFolderSheet extends StatefulWidget {
  const _JerseyStudioFolderSheet({required this.files});

  final List<SelectedJerseyFile> files;

  @override
  State<_JerseyStudioFolderSheet> createState() =>
      _JerseyStudioFolderSheetState();
}

class _JerseyStudioFolderSheetState extends State<_JerseyStudioFolderSheet> {
  late Set<String> _selectedNames;

  @override
  void initState() {
    super.initState();
    // Cap initial pre-selection at 5 files
    _selectedNames = widget.files.take(5).map((f) => f.name).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JerseyStudio Folder Files',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.files.length} saved file${widget.files.length == 1 ? '' : 's'} found (Max 5 per batch)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedNames.isNotEmpty) {
                      _selectedNames.clear();
                    } else {
                      _selectedNames =
                          widget.files.take(5).map((f) => f.name).toSet();
                    }
                  });
                },
                child: Text(
                  _selectedNames.isNotEmpty
                      ? 'Deselect All'
                      : 'Select First 5',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.files.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final file = widget.files[index];
                final isChecked = _selectedNames.contains(file.name);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _selectedNames.remove(file.name);
                      } else {
                        if (_selectedNames.length >= 5) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Maximum 5 files allowed per batch.',
                                ),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        } else {
                          _selectedNames.add(file.name);
                        }
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked
                            ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChecked
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isChecked
                              ? AppTheme.primaryBlue
                              : AppTheme.textSubtle,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _kGreenBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kGreenBorder),
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            size: 16,
                            color: _kGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              Text(
                                file.formattedSize,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _selectedNames.isEmpty
                  ? null
                  : () {
                      final selected = widget.files
                          .where((f) => _selectedNames.contains(f.name))
                          .toList();
                      Navigator.pop(context, selected);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Import ${_selectedNames.length} File${_selectedNames.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable option tile used in the "Load Jersey Files From." sheet.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}