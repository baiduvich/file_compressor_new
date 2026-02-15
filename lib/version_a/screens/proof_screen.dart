import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProofScreen extends StatefulWidget {
  final String? title;
  final InlineSpan? titleSpan;
  final List<String> imagePaths;
  final VoidCallback onNext;
  final Color titleColor;

  const ProofScreen({
    super.key,
    this.title,
    this.titleSpan,
    required this.imagePaths,
    required this.onNext,
    this.titleColor = Colors.white,
  }) : assert(title != null || titleSpan != null, 'Either title or titleSpan must be provided');

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Title
              widget.titleSpan != null
                  ? Text.rich(
                      widget.titleSpan!,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      widget.title!,
                style: TextStyle(
                  color: widget.titleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Proof Image(s)
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImageContent(),
                  ),
                ),
              ),
              
              if (widget.imagePaths.length > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imagePaths.length, (index) {
                    final isActive = index == _pageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
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

  Widget _buildImageContent() {
    if (widget.imagePaths.length <= 1) {
      return _buildImage(widget.imagePaths.first);
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _pageIndex = index),
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) => _buildImage(widget.imagePaths[index]),
    );
  }

  Widget _buildImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Proof Image',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
