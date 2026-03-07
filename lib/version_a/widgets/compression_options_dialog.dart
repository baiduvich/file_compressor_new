import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../models/compression_options.dart';

class CompressionOptionsDialog extends StatefulWidget {
  const CompressionOptionsDialog({super.key});

  @override
  State<CompressionOptionsDialog> createState() => _CompressionOptionsDialogState();
}

class _CompressionOptionsDialogState extends State<CompressionOptionsDialog> {
  CompressionPreset _selectedPreset = CompressionPreset.smart;
  bool _bundleFiles = false;
  bool _bulkConversion = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compression Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Images convert to WebP • Audio converts to AAC',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),

            ...CompressionPreset.values.map((preset) => _buildPresetCard(preset)),

            const SizedBox(height: 16),

            SwitchListTile.adaptive(
              title: const Text('Create a ZIP File',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
              subtitle: const Text('Bundle multiple files into one archive',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              value: _bundleFiles,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _bundleFiles = val),
            ),

            const SizedBox(height: 8),

            SwitchListTile.adaptive(
              title: const Text('Bulk Conversion',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
              subtitle: const Text('Process all selected files in one batch',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              value: _bulkConversion,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _bulkConversion = val),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 20, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All compression happens on-device. Your files never leave this phone.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'preset': _selectedPreset,
                    'bundleFiles': _bundleFiles,
                    'bulkConversion': _bulkConversion,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Compression',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPresetCard(CompressionPreset preset) {
    final isSelected = _selectedPreset == preset;

    IconData icon;
    Color accentColor;
    switch (preset) {
      case CompressionPreset.smart:
        icon = Icons.auto_awesome;
        accentColor = AppColors.primary;
        break;
      case CompressionPreset.highQuality:
        icon = Icons.high_quality;
        accentColor = const Color(0xFF4CAF50);
        break;
      case CompressionPreset.maxCompression:
        icon = Icons.compress;
        accentColor = const Color(0xFFFF9800);
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPreset = preset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.12) : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : AppColors.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : AppColors.textSecondaryDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? accentColor : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.expectedSavings,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accentColor, size: 22),
          ],
        ),
      ),
    );
  }
}
