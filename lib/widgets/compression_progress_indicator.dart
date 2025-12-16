import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../core/constants/app_colors.dart';

class CompressionProgressIndicator extends StatefulWidget {
  final double progress;
  final String? statusText;
  
  const CompressionProgressIndicator({
    super.key,
    required this.progress,
    this.statusText,
  });

  @override
  State<CompressionProgressIndicator> createState() => _CompressionProgressIndicatorState();
}

class _CompressionProgressIndicatorState extends State<CompressionProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pulsing circle
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 180 + (math.sin(_controller.value * 2 * math.pi) * 10),
                    height: 180 + (math.sin(_controller.value * 2 * math.pi) * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  );
                },
              ),
              
              // Progress Circle
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: widget.progress,
                  ),
                ),
              ),
              
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.progress <= 0) ...[
                    // Loading State
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 48,
                      color: AppColors.primary,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 2000.ms, curve: Curves.easeInOut),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Processing...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .fadeIn(duration: 800.ms)
                     .then()
                     .fadeOut(duration: 800.ms),
                  ] else ...[
                    // Progress State
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ).createShader(bounds),
                      child: Text(
                        '${(widget.progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  
                  if (widget.statusText != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.statusText!,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = AppColors.textLight.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 6, backgroundPaint);
    
    // Progress arc with gradient effect
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
