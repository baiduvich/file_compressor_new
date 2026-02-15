import 'package:flutter/material.dart';
import '../helpers/paywall_copy_helper.dart';
import '../../core/constants/app_colors.dart';
import 'paywall_screen.dart';
import 'proof_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  // Selections
  FileTypeOption? _selectedType;
  UseCaseOption? _selectedUseCase;
  PriorityOption? _selectedPriority;

  void _nextPage() {
    if (_currentIndex == 0) {
      _showSelectionProofScreen();
      return;
    }

    if (_currentIndex == 1) {
      setState(() {
        _currentIndex = 2;
      });
      return;
    }

    // After last onboarding, show proof screen before paywall
    _showFinalProofScreen();
  }

  void _showSelectionProofScreen() {
    if (_selectedType == null) return;

    final List<String> imagePaths;
    final String fileTypeName;

    switch (_selectedType!) {
      case FileTypeOption.pdf:
        imagePaths = ['assets/images/proof1_pdf.jpg'];
        fileTypeName = 'PDF';
        break;
      case FileTypeOption.documents:
        imagePaths = ['assets/images/proof1_pdf.jpg'];
        fileTypeName = 'Documents';
        break;
      case FileTypeOption.images:
        imagePaths = ['assets/images/proof1_jpg.jpg'];
        fileTypeName = 'Images';
        break;
      case FileTypeOption.videos:
        imagePaths = ['assets/images/proof1_mp4.jpg'];
        fileTypeName = 'Videos';
        break;
      case FileTypeOption.all:
        imagePaths = [
          'assets/images/proof1_pdf.jpg',
          'assets/images/proof1_mp4.jpg',
          'assets/images/proof1_jpg.jpg',
        ];
        fileTypeName = 'All Files';
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofScreen(
          titleSpan: TextSpan(
            style: const TextStyle(fontSize: 28, height: 1.2),
            children: [
              const TextSpan(
                text: 'Compress ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: fileTypeName,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: ' Easily!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          imagePaths: imagePaths,
          onNext: () {
            Navigator.of(context).pop();
            setState(() {
              _currentIndex = 1;
            });
          },
        ),
      ),
    );
  }

  void _showFinalProofScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofScreen(
          title: "We got you covered!",
          imagePaths: const ['assets/images/proof3.png'], // User will add this
          titleColor: Colors.white,
          onNext: () {
            Navigator.of(context).pop();
            _finishOnboarding();
          },
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    // Navigate to Paywall
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentIndex
                            ? AppColors.primary
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Expanded(child: _buildCurrentPage()),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentIndex == 2 ? 'Continue' : 'Next',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentIndex == 0) return _selectedType != null;
    if (_currentIndex == 1) return _selectedUseCase != null;
    if (_currentIndex == 2) return _selectedPriority != null;
    return false;
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildQuestion2Part(
          "What do you ",
          "compress the most?",
          [
          _Option(
            "PDF",
            FileTypeOption.pdf,
            _selectedType == FileTypeOption.pdf,
            Icons.picture_as_pdf,
          ),
          _Option(
            "Images",
            FileTypeOption.images,
            _selectedType == FileTypeOption.images,
            Icons.image,
          ),
          _Option(
            "Videos",
            FileTypeOption.videos,
            _selectedType == FileTypeOption.videos,
            Icons.videocam,
          ),
          _Option(
            "Documents",
            FileTypeOption.documents,
            _selectedType == FileTypeOption.documents,
            Icons.description,
          ),
          _Option(
            "All Types",
            FileTypeOption.all,
            _selectedType == FileTypeOption.all,
            Icons.folder,
          ),
          ],
          (val) => setState(() => _selectedType = val),
        );
      case 1:
        return _buildQuestion2Part(
          "What's your ",
          "main use case?",
          [
          _Option(
            "Work",
            UseCaseOption.work,
            _selectedUseCase == UseCaseOption.work,
            Icons.business,
          ),
          _Option(
            "School",
            UseCaseOption.school,
            _selectedUseCase == UseCaseOption.school,
            Icons.school,
          ),
          _Option(
            "Personal Documents",
            UseCaseOption.personal,
            _selectedUseCase == UseCaseOption.personal,
            Icons.person,
          ),
          ],
          (val) => setState(() => _selectedUseCase = val),
        );
      case 2:
        return _buildQuestion3Part(
          "What matters ",
          "THE MOST",
          " to you?",
          [
          _Option(
            "High Quality",
            PriorityOption.highQuality,
            _selectedPriority == PriorityOption.highQuality,
            Icons.high_quality,
          ),
          _Option(
            "Smallest File Size",
            PriorityOption.smallestSize,
            _selectedPriority == PriorityOption.smallestSize,
            Icons.compress,
          ),
          _Option(
            "Fast & Simple",
            PriorityOption.fastSimple,
            _selectedPriority == PriorityOption.fastSimple,
            Icons.flash_on,
          ),
          ],
          (val) => setState(() => _selectedPriority = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestion2Part<T>(
    String prefix,
    String highlight,
    List<_Option<T>> options,
    Function(T) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 28, height: 1.2),
            children: [
              TextSpan(
                text: prefix,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: highlight,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ...options
            .map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onSelect(opt.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: opt.isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: opt.isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          opt.icon,
                          color: opt.isSelected
                              ? AppColors.primary
                              : Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (opt.isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        else
                          Icon(Icons.circle_outlined, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildQuestion3Part<T>(
    String prefix,
    String highlight,
    String suffix,
    List<_Option<T>> options,
    Function(T) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 28, height: 1.2),
            children: [
              TextSpan(
                text: prefix,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: highlight,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: suffix,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ...options
            .map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onSelect(opt.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: opt.isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: opt.isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          opt.icon,
                          color: opt.isSelected
                              ? AppColors.primary
                              : Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (opt.isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        else
                          Icon(Icons.circle_outlined, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}

class _Option<T> {
  final String label;
  final T value;
  final bool isSelected;
  final IconData icon;

  _Option(this.label, this.value, this.isSelected, this.icon);
}
