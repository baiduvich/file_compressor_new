import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../widgets/stats_card.dart';
import '../widgets/file_card.dart';
import '../widgets/compression_options_dialog.dart';
import '../models/compression_options.dart';
import '../services/file_service.dart';
import '../services/history_service.dart';
import '../models/file_info.dart';
import 'compression_screen.dart';
import 'history_screen.dart';
import 'paywall_screen.dart';
import '../helpers/paywall_copy_helper.dart';
import '../services/revenue_cat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyService = context.read<HistoryService>();
    await historyService.loadHistory();
  }

  Future<void> _selectAndCompressFiles() async {
    // 1. Check Pro Status
    bool isPro = await RevenueCatService.isPro();
    if (!isPro) {
        if (!mounted) return;
        // Navigate to Paywall
        // Use default options or maybe read from prefs if we had them, but standard is fine
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(
              fileType: FileTypeOption.all, 
              useCase: UseCaseOption.personal, 
              priority: PriorityOption.fastSimple
            ),
          ),
        );
        return; // Don't proceed to compression
    }

    // Show modal bottom sheet to choose between Files and Gallery
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
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
                  title: const Text('Pick Files', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, 'files'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Pick from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Images & Videos'),
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

    setState(() => _isLoading = true);
    try {
      List<FileInfo> files = [];
      if (choice == 'files') {
        files = await _fileService.pickFiles(multiple: true);
      } else if (choice == 'gallery') {
        files = await _fileService.pickMedia();
      }
      
      if (files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      
      if (!mounted) return;
      
      // Show compression options dialog
      final options = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const CompressionOptionsDialog(),
      );
      
      if (options == null) {
        // User cancelled
        setState(() => _isLoading = false);
        return;
      }
      
      final preset = options['preset'] as CompressionPreset;
      final bundleFiles = options['bundleFiles'] as bool;

      if (!mounted) return;
      
      // Navigate to compression screen with options
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompressionScreen(
            files: files,
            compressionPreset: preset,
            bundleFiles: bundleFiles,
          ),
        ),
      );
      
      // Reload history after compression
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'File Compressor',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Statistics Cards
                  Consumer<HistoryService>(
                    builder: (context, historyService, _) {
                      final stats = historyService.getTotalStatistics();
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  title: 'Total Compressed',
                                  value: '${stats['totalCompressions']}',
                                  icon: Icons.archive,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatsCard(
                                  title: 'Space Saved',
                                  value: '${(stats['totalSaved'] / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  icon: Icons.storage,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StatsCard(
                            title: 'Average Compression',
                            value: '${stats['averageRatio'].toStringAsFixed(1)}%',
                            icon: Icons.compress,
                            color: AppColors.accent,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Main Action Button
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: _selectAndCompressFiles,
                              child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.textOnPrimary,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/icons/compress_icon.png',
                                        width: 100,
                                        height: 100,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.compress,
                                            size: 80,
                                            color: AppColors.textOnPrimary,
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tap to Select Files',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms),
                        const SizedBox(height: 8),
                        const Text(
                          'Compress any file type',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryDark,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Recent Compressions
                  Consumer<HistoryService>(
                    builder: (context, historyService, _) {
                      if (historyService.history.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/icons/empty_state.png',
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.folder_open,
                                    size: 80,
                                    color: AppColors.textLight,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No compressions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 400.ms);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Compressions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
