import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/compression_service.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../models/compression_history.dart';
import '../models/compression_options.dart';
import '../models/file_info.dart';
import '../widgets/animated_button.dart';
import '../widgets/compression_options_dialog.dart';
import '../widgets/compression_progress_indicator.dart';
import 'paywall_screen.dart';

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

class _CompressionScreenState extends State<CompressionScreen>
    with TickerProviderStateMixin {
  final CompressionService _compressionService = CompressionService();
  final FileService _fileService = FileService();
  final InAppReview _inAppReview = InAppReview.instance;

  double _progress = 0.0;
  bool _isCompressing = false;
  bool _isComplete = false;
  bool _isCancelling = false;
  List<FileInfo> _compressedFiles = [];
  String _statusText = 'Preparing...';
  int _currentFileIndex = 0;
  bool _hasVideo = false;

  // Animated counter for % saved
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;
  double _displayedRatio = 0;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _hasVideo = widget.files.any((f) => _fileService.isHiddenVideo(f.path));
    _startCompression();
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  Future<void> _startCompression() async {
    setState(() {
      _isCompressing = true;
      _statusText = _hasVideo
          ? 'Preparing video...\nThis may take 1-2 minutes, please wait.'
          : 'Preparing files...';
    });

    try {
      final outputDirectory = await _fileService.getOutputDirectory();

      final compressed = await _compressionService.compressFiles(
        files: widget.files,
        outputDirectory: outputDirectory,
        preset: widget.compressionPreset,
        bundleFiles: widget.bundleFiles,
        onProgress: (currentIndex, total, fileProgress) {
          if (!mounted) return;
          setState(() {
            _currentFileIndex = currentIndex + 1;
            _progress = (currentIndex + fileProgress) / total;
            final mode = widget.bulkConversion
                ? 'Converting'
                : widget.bundleFiles
                    ? 'Bundling'
                    : 'Compressing';
            _statusText = '$mode file $_currentFileIndex of $total...';
          });
        },
      );

      // Save to history
      for (final compressedFile in compressed) {
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

      if (!mounted) return;
      setState(() {
        _compressedFiles = compressed;
        _progress = 1.0;
        _isComplete = true;
        _isCompressing = false;
        _statusText = 'Complete!';
      });

      // Animate the counter to the average compression ratio
      final avgRatio = _computeAverageRatio(compressed);
      _counterAnimation = Tween<double>(begin: 0, end: avgRatio).animate(
        CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
      )..addListener(() {
          if (mounted) setState(() => _displayedRatio = _counterAnimation.value);
        });
      _counterController.forward();

      // Fire review prompt asynchronously on 2nd+ compression — never blocks the UI
      _maybeRequestReview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Compression failed';
        _isCompressing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compression failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelVideoCompression() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Fires the in-app review prompt on the 2nd+ compression — doesn't gate any UI
  Future<void> _maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('compression_count') ?? 0;
      await prefs.setInt('compression_count', count + 1);

      if (count >= 1 && await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {}
  }

  double _computeAverageRatio(List<FileInfo> files) {
    if (files.isEmpty) return 0;
    final ratios = files.map((f) => f.compressionRatio ?? 0).toList();
    return ratios.reduce((a, b) => a + b) / ratios.length;
  }

  int _totalSavedBytes(List<FileInfo> files) {
    return files.fold(0, (sum, f) {
      return sum + (f.sizeInBytes - (f.compressedSizeInBytes ?? f.sizeInBytes));
    });
  }

  String _contextualEquivalent(int savedBytes) {
    final savedMB = savedBytes / (1024 * 1024);
    if (savedMB >= 1000) {
      return 'That\'s like ${(savedMB / 1024).toStringAsFixed(1)} GB freed!';
    } else if (savedMB >= 100) {
      return 'Enough for ~${(savedMB / 3.5).round()} more songs';
    } else if (savedMB >= 10) {
      return 'That\'s ~${(savedMB / 0.025).round()} photos worth of space';
    } else if (savedMB >= 1) {
      return 'That\'s ~${(savedMB / 0.025).round()} photos worth of space';
    }
    return 'Every byte counts!';
  }

  Future<void> _shareFile(FileInfo file) async {
    final isPro = await RevenueCatService.isPro();
    if (!isPro) {
      if (!mounted) return;
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    try {
      await _fileService.shareFile(file.compressedPath!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openFile(FileInfo file) async {
    final isPro = await RevenueCatService.isPro();
    if (!isPro) {
      if (!mounted) return;
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    try {
      await _fileService.openFile(file.compressedPath!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _shareStats() async {
    try {
      final savedBytes = _totalSavedBytes(_compressedFiles);
      final avgRatio = _computeAverageRatio(_compressedFiles);
      final fileCount = _compressedFiles.length;

      final text = fileCount == 1
          ? 'I just compressed "${_compressedFiles.first.name}" from '
              '${_fileService.formatFileSize(_compressedFiles.first.sizeInBytes)} to '
              '${_fileService.formatFileSize(_compressedFiles.first.compressedSizeInBytes ?? 0)} '
              '— saved ${avgRatio.toStringAsFixed(0)}%! 🗜️'
          : 'I just compressed $fileCount files and saved '
              '${_fileService.formatFileSize(savedBytes)} '
              '(${avgRatio.toStringAsFixed(0)}% smaller)! 🗜️';

      await Share.share(text);
    } catch (_) {}
  }

  Future<void> _compressOtherFiles() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                title: const Text('Pick Files',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
                onTap: () => Navigator.pop(ctx, 'files'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pick from Gallery',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
                subtitle: const Text('Images & Videos',
                    style: TextStyle(color: AppColors.textSecondaryDark)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    try {
      List<FileInfo> files = [];
      if (choice == 'files') {
        files = await _fileService.pickFiles(multiple: true);
      } else {
        files = await _fileService.pickMedia();
      }
      if (files.isEmpty) return;
      if (!mounted) return;

      final options = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const CompressionOptionsDialog(),
      );
      if (options == null) return;

      final preset = options['preset'] as CompressionPreset;
      final bundleFiles = options['bundleFiles'] as bool;
      final bulkConversion = options['bulkConversion'] as bool? ?? false;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompressionScreen(
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
            backgroundColor: AppColors.error),
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
        title: Text(_isComplete ? 'Results' : 'Compressing'),
        leading: _isComplete
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isComplete
            ? _buildResultsView(isDark, cardColor, textColor, secondaryColor)
            : _buildProgressView(isDark, textColor),
      ),
    );
  }

  // ─── PROGRESS PHASE ───────────────────────────────────────────────────────

  Widget _buildProgressView(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: CompressionProgressIndicator(
              progress: _progress,
              statusText: _statusText,
            ),
          ),
          if (_hasVideo && _isCompressing && !_isCancelling) ...[
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: _cancelVideoCompression,
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: const Text('Cancel',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  // ─── RESULTS PHASE ────────────────────────────────────────────────────────

  Widget _buildResultsView(
      bool isDark, Color cardColor, Color textColor, Color secondaryColor) {
    final savedBytes = _totalSavedBytes(_compressedFiles);
    final avgRatio = _computeAverageRatio(_compressedFiles);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            children: [
              // ── Dramatic headline ──────────────────────────────────────
              _buildHeroStats(avgRatio, savedBytes, textColor, secondaryColor),
              const SizedBox(height: 20),

              // ── File-by-file cards ─────────────────────────────────────
              ...List.generate(_compressedFiles.length, (index) {
                return _buildFileCard(
                    _compressedFiles[index], index, isDark, cardColor, textColor, secondaryColor);
              }),

              const SizedBox(height: 8),
            ],
          ),
        ),

        // ── Bottom actions ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              // Share Stats button (always free)
              if (_compressedFiles.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _shareStats,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share My Savings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                const SizedBox(height: 10),
              ],
              AnimatedButton(
                text: 'Compress Other Files',
                onPressed: _compressOtherFiles,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStats(double avgRatio, int savedBytes,
      Color textColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.success.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Big animated percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayedRatio.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('%',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const Text('Smaller',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success)),
          const SizedBox(height: 16),

          // Saved bytes + contextual
          Text(
            '${_fileService.formatFileSize(savedBytes)} saved',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            _contextualEquivalent(savedBytes),
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),

          const SizedBox(height: 20),

          // Visual bar comparison
          _buildSizeBars(savedBytes),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSizeBars(int savedBytes) {
    final totalOriginal =
        _compressedFiles.fold(0, (sum, f) => sum + f.sizeInBytes);
    final totalCompressed = _compressedFiles
        .fold(0, (sum, f) => sum + (f.compressedSizeInBytes ?? f.sizeInBytes));

    if (totalOriginal == 0) return const SizedBox.shrink();

    final ratio = totalCompressed / totalOriginal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Before',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  LayoutBuilder(builder: (ctx, constraints) {
                    return Container(
                      height: 10,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Text(
                    _fileService.formatFileSize(totalOriginal),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF5350),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('After',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  LayoutBuilder(builder: (ctx, constraints) {
                    return Container(
                      height: 10,
                      width: constraints.maxWidth * ratio.clamp(0.02, 1.0),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Text(
                    _fileService.formatFileSize(totalCompressed),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildFileCard(FileInfo file, int index, bool isDark, Color cardColor,
      Color textColor, Color secondaryColor) {
    final savedBytes =
        file.sizeInBytes - (file.compressedSizeInBytes ?? file.sizeInBytes);
    final savingPercent = file.compressionRatio ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          // File name + format note
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (file.formatNote != null)
                      Row(
                        children: [
                          const Icon(Icons.auto_fix_high,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(file.formatNote!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.trending_down,
                              size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('${savingPercent.toStringAsFixed(1)}% saved',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                  ],
                ),
              ),
              // Savings badge
              if (savingPercent > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '${savingPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success),
                  ),
                ),
            ],
          ),

          ...[
            const SizedBox(height: 12),
            // Before/After row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Before',
                            style: TextStyle(fontSize: 11, color: secondaryColor)),
                        const SizedBox(height: 2),
                        Text(
                          _fileService.formatFileSize(file.sizeInBytes),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 18, color: secondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('After',
                            style: TextStyle(fontSize: 11, color: secondaryColor)),
                        const SizedBox(height: 2),
                        Text(
                          _fileService.formatFileSize(
                              file.compressedSizeInBytes ?? 0),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${_fileService.formatFileSize(savedBytes)}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Open + Share — always enabled (no gate)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openFile(file),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Open'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareFile(file),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + index * 100), duration: 350.ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOut);
  }
}
