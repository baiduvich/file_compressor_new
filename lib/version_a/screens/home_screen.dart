import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../models/compression_options.dart';
import '../models/file_info.dart';
import '../widgets/compression_options_dialog.dart';
import '../widgets/file_card.dart';
import 'compression_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FileService _fileService = FileService();
  bool _isLoading = false;

  late AnimationController _savingsController;
  late Animation<double> _savingsAnimation;
  double _displayedSavedMB = 0;
  double _lastAnimatedSavedMB = 0;

  @override
  void initState() {
    super.initState();
    _savingsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final historyService = context.read<HistoryService>();
    await historyService.loadHistory();
    _animateSavings(historyService);
  }

  void _animateSavings(HistoryService historyService) {
    final stats = historyService.getTotalStatistics();
    final targetMB = (stats['totalSaved'] as int) / (1024 * 1024);
    if (targetMB == _lastAnimatedSavedMB) return;
    _lastAnimatedSavedMB = targetMB;

    _savingsAnimation =
        Tween<double>(begin: _displayedSavedMB, end: targetMB).animate(
      CurvedAnimation(parent: _savingsController, curve: Curves.easeOut),
    )..addListener(() {
            if (mounted) setState(() => _displayedSavedMB = _savingsAnimation.value);
          });

    _savingsController.forward(from: 0);
  }

  Future<void> _selectAndCompressFiles() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.folder_open, color: AppColors.primary),
                title: const Text('Pick Files',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('PDF, Audio, Office, Images, Videos & more'),
                onTap: () => Navigator.pop(ctx, 'files'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pick from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Images & Videos'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;
    setState(() => _isLoading = true);

    try {
      List<FileInfo> files = [];
      if (choice == 'files') {
        files = await _fileService.pickFiles(multiple: true);
      } else {
        files = await _fileService.pickMedia();
      }

      if (files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      final options = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const CompressionOptionsDialog(),
      );

      if (options == null) {
        setState(() => _isLoading = false);
        return;
      }

      final preset = options['preset'] as CompressionPreset;
      final bundleFiles = options['bundleFiles'] as bool;
      final bulkConversion = options['bulkConversion'] as bool? ?? false;

      if (!mounted) return;
      await Navigator.push(
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

      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Compressor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Savings dashboard ─────────────────────────────────────
            Consumer<HistoryService>(
              builder: (ctx, historyService, _) {
                final stats = historyService.getTotalStatistics();
                final compressions = stats['totalCompressions'] as int;
                final savedBytes = stats['totalSaved'] as int;
                final avgRatio = stats['averageRatio'] as double;

                if (compressions == 0) {
                  return _buildEmptyStats(isDark, textColor, secondaryColor);
                }

                return _buildLiveSavings(
                  compressions: compressions,
                  savedBytes: savedBytes,
                  avgRatio: avgRatio,
                  isDark: isDark,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Upload button ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _isLoading ? null : _selectAndCompressFiles,
                      child: Container(
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary),
                              )
                            : const Icon(Icons.upload_file,
                                size: 56, color: AppColors.textOnPrimary),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        delay: 3.seconds,
                        duration: 1.5.seconds,
                        color: Colors.white.withOpacity(0.15),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to compress files',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PDF • Images • Video • Audio • Office',
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Recent history ────────────────────────────────────────
            Consumer<HistoryService>(
              builder: (ctx, historyService, _) {
                if (historyService.history.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 12),
                    ...historyService.history.take(3).map((history) {
                      return FileCard(
                        file: FileInfo(
                          name: history.outputPath.split('/').last,
                          path: history.outputPath,
                          sizeInBytes: history.totalOriginalSize,
                          compressedSizeInBytes: history.totalCompressedSize,
                          dateAdded: history.timestamp,
                        ),
                        showCompression: true,
                        onDelete: null,
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStats(bool isDark, Color textColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.compress, size: 36, color: AppColors.primary),
          const SizedBox(height: 10),
          Text('Compress PDF, photos, videos,\naudio & Office files — all on-device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: secondaryColor)),
          const SizedBox(height: 8),
          const Text('Images convert to WebP • Audio to AAC',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildLiveSavings({
    required int compressions,
    required int savedBytes,
    required double avgRatio,
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final savedMB = savedBytes / (1024 * 1024);
    final savedGB = savedMB / 1024;
    final displayValue = savedGB >= 1
        ? '${savedGB.toStringAsFixed(2)} GB'
        : '${_displayedSavedMB.toStringAsFixed(1)} MB';

    final equivalent = _equivalent(savedBytes);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.success.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Big savings number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(' saved',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(equivalent,
              style: TextStyle(fontSize: 13, color: secondaryColor)),

          const SizedBox(height: 16),

          // Stat chips
          Row(
            children: [
              _StatChip(
                  label: 'Sessions',
                  value: '$compressions',
                  color: AppColors.primary),
              const SizedBox(width: 10),
              _StatChip(
                  label: 'Avg Saved',
                  value: '${avgRatio.toStringAsFixed(0)}%',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  String _equivalent(int savedBytes) {
    final savedMB = savedBytes / (1024 * 1024);
    if (savedMB >= 1000) {
      return 'You\'ve freed an entire hard drive worth of space!';
    } else if (savedMB >= 100) {
      return '≈ ${(savedMB / 3.5).round()} songs • ${(savedMB / 8).round()} photos';
    } else if (savedMB >= 1) {
      return '≈ ${(savedMB / 0.025).round()} photos worth of space freed';
    }
    return 'Keep going — every byte counts!';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceDark
        : AppColors.textLight.withOpacity(0.15);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
