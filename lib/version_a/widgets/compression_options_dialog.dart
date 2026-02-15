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
          color: AppColors.surfaceDark, // Fixed: Force Dark Background
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Darker shadow
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
                color: AppColors.textPrimaryDark, // Fixed: Light text
              ),
            ),
            const SizedBox(height: 24),
            
            // Preset Selection (3 Cards)
            ...CompressionPreset.values.map((preset) => _buildPresetCard(preset)),
            
            const SizedBox(height: 16),
            
            // Archive Toggle
            SwitchListTile.adaptive(
              title: const Text('Create a ZIP File', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
              subtitle: const Text('Useful for sharing multiple files', style: TextStyle(color: AppColors.textSecondaryDark)),
              value: _bundleFiles,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _bundleFiles = val),
            ),
            
            const SizedBox(height: 12),
            
            // Bulk Conversion Toggle
            SwitchListTile.adaptive(
              title: const Text('Bulk Conversion', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
              subtitle: const Text('Process all files in one batch operation', style: TextStyle(color: AppColors.textSecondaryDark)),
              value: _bulkConversion,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _bulkConversion = val),
            ),

            const SizedBox(height: 24),
            
            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark, // Fixed: Dark background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: AppColors.success),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'All compression happens on-device. Your files never leave this phone.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Compress Button
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    switch (preset) {
      case CompressionPreset.smart: icon = Icons.auto_awesome; break;
      case CompressionPreset.highQuality: icon = Icons.high_quality; break;
      case CompressionPreset.maxCompression: icon = Icons.compress; break;
    }
  
    return GestureDetector(
      onTap: () => setState(() => _selectedPreset = preset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondaryDark, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
