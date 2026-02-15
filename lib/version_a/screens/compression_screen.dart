import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/compression_progress_indicator.dart';
import '../widgets/animated_button.dart';
import '../models/file_info.dart';
import '../models/compression_history.dart';
import '../models/compression_options.dart';
import '../../core/services/compression_service.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../widgets/compression_options_dialog.dart';
import 'paywall_screen.dart';

import 'package:in_app_review/in_app_review.dart';

class CompressionScreen extends StatefulWidget {
  final List<FileInfo> files;
  final CompressionPreset compressionPreset;
  final bool bundleFiles;
  final bool bulkConversion;

  const CompressionScreen({
    super.key,
    required this.files,
    this.compressionPreset = CompressionPreset.smart,
    this.bundleFiles = false,
    this.bulkConversion = false,
  });

  @override
  State<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends State<CompressionScreen> {
  final CompressionService _compressionService = CompressionService();
  final FileService _fileService = FileService();
  final InAppReview _inAppReview = InAppReview.instance;
  
  double _progress = 0.0;
  bool _isCompressing = false;
  bool _isComplete = false;
  bool _reviewShown = false;
  List<FileInfo> _compressedFiles = [];
  String _statusText = 'Preparing...';
  int _currentFileIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCompression();
  }

  Future<void> _startCompression() async {
    // Check if any file is a video to show specific warning
    final hasVideo = widget.files.any((file) => _fileService.isHiddenVideo(file.path));
    
    setState(() {
      _isCompressing = true;
      if (hasVideo) {
        _statusText = 'Preparing video compression...\nThis may take 1-2 minutes, please wait.';
      } else {
        _statusText = 'Preparing files...';
      }
    });

    try {
      final outputDirectory = await _fileService.getOutputDirectory();
      
      final compressed = await _compressionService.compressFiles(
        files: widget.files,
        outputDirectory: outputDirectory,
        preset: widget.compressionPreset,
        bundleFiles: widget.bundleFiles, // Updated parameter name
        onProgress: (currentIndex, total, fileProgress) {
          setState(() {
            _currentFileIndex = currentIndex + 1;
            final overallProgress = (currentIndex + fileProgress) / total;
            _progress = overallProgress;
            // Use widget.bundleFiles and widget.bulkConversion to determine text
            String modeText;
            if (widget.bulkConversion) {
              modeText = 'Bulk Converting';
            } else if (widget.bundleFiles) {
              modeText = 'Bundling';
            } else {
              modeText = 'Compressing';
            }
            _statusText = '$modeText file $_currentFileIndex of $total...';
          });
        },
      );

      setState(() {
        _compressedFiles = compressed;
        _progress = 1.0;
        _compressedFiles = compressed; // Redundant line removed in cleanup ideally
        _isComplete = true;
        _statusText = 'Complete!';
      });

      // Add each compressed file to history
      for (var compressedFile in compressed) {
        final history = CompressionHistory(
          id: const Uuid().v4(),
          files: [compressedFile],
          timestamp: DateTime.now(),
          outputPath: compressedFile.compressedPath!,
          totalOriginalSize: compressedFile.sizeInBytes,
          totalCompressedSize: compressedFile.compressedSizeInBytes!,
        );

        if (!mounted) return;
        await context.read<HistoryService>().addToHistory(history);
      }

      // Request review after successful compression, before enabling open/share
      if (!mounted) return;
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
      if (!mounted) return;
      setState(() {
        _reviewShown = true;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Error: $e';
        _isCompressing = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compression failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _shareFile(FileInfo file) async {
    // Check if user is pro
    final isPro = await RevenueCatService.isPro();
    if (!isPro) {
      // Show paywall, if dismissed stay on compression screen
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(),
        ),
      );
      return;
    }

    try {
      await _fileService.shareFile(file.compressedPath!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  Future<void> _openFile(FileInfo file) async {
    // Check if user is pro
    final isPro = await RevenueCatService.isPro();
    if (!isPro) {
      // Show paywall, if dismissed stay on compression screen
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(),
        ),
      );
      return;
    }

    try {
      await _fileService.openFile(file.compressedPath!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _compressOtherFiles() async {
    // Show modal bottom sheet to choose between Files and Gallery
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondaryDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.folder_open, color: AppColors.primary),
                  title: const Text(
                    'Pick Files',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'files'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text(
                    'Pick from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Images & Videos',
                    style: TextStyle(color: AppColors.textSecondaryDark),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;

    try {
      List<FileInfo> files = [];
      if (choice == 'files') {
        files = await _fileService.pickFiles(multiple: true);
      } else if (choice == 'gallery') {
        files = await _fileService.pickMedia();
      }
      
      if (files.isEmpty) return;
      
      if (!mounted) return;
      
      // Show compression options dialog
      final options = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const CompressionOptionsDialog(),
      );
      
      if (options == null) return;
      
      final preset = options['preset'] as CompressionPreset;
      final bundleFiles = options['bundleFiles'] as bool;
      final bulkConversion = options['bulkConversion'] as bool? ?? false;

      if (!mounted) return;
      
      // Replace current screen with new compression screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CompressionScreen(
            files: files,
            compressionPreset: preset,
            bundleFiles: bundleFiles,
            bulkConversion: bulkConversion,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final cardColor = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Compressing'),
        leading: _isComplete
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: !_isCompressing,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress Indicator
              if (!_isComplete) ...[
                const Spacer(),
                Center(
                  child: CompressionProgressIndicator(
                    progress: _progress,
                    statusText: _statusText,
                  ),
                ),
                const Spacer(),
              ]
              else ...[
                // Success header
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/success.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.success, Color(0xFF66BB6A)],
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 60,
                          color: AppColors.textOnPrimary,
                        ),
                      );
                    },
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),
                Text(
                  'Compression Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 40),
                
                // Compressed files list
                Expanded(
                  child: ListView.builder(
                    itemCount: _compressedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _compressedFiles[index];
                      final savedBytes = file.sizeInBytes - (file.compressedSizeInBytes ?? file.sizeInBytes);
                      final savingPercent = file.compressionRatio ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.archive,
                                    color: AppColors.textOnPrimary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.trending_down,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${savingPercent.toStringAsFixed(1)}% saved',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Before',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: secondaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _fileService.formatFileSize(file.sizeInBytes),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: secondaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'After',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: secondaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _fileService.formatFileSize(file.compressedSizeInBytes ?? 0),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${_fileService.formatFileSize(savedBytes)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _reviewShown ? () => _openFile(file) : null,
                                    icon: const Icon(Icons.folder_open, size: 18),
                                    label: const Text('Open'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _reviewShown ? () => _shareFile(file) : null,
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
                          .slideX(begin: 0.2, end: 0);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Action Button
              if (_isComplete)
                AnimatedButton(
                  text: 'Compress Other Files',
                  onPressed: () => _compressOtherFiles(),
                  isPrimary: false,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
