import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

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
    final screenW = Responsive.width(context);
    final outer = screenW * 0.55;
    final pulseSize = outer * (180 / 200);
    final progressSize = outer * (160 / 200);
    final strokeWidth = 12 * (outer / 200);
    final centerIconSize = 48 * (outer / 200);
    final centerFontSize =
        Responsive.fontSize(context, ratio: 0.10, min: 32, max: 56);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: outer,
          height: outer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pulsing circle
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final pulse =
                      pulseSize +
                      (math.sin(_controller.value * 2 * math.pi) *
                          (10 * outer / 200));
                  return Container(
                    width: pulse,
                    height: pulse,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  );
                },
              ),
              SizedBox(
                width: progressSize,
                height: progressSize,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: widget.progress,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
              
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.progress <= 0) ...[
                    // Loading State
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: centerIconSize,
                      color: AppColors.primary,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 2000.ms, curve: Curves.easeInOut),

                    const SizedBox(height: 12),

                    Text(
                      'Processing...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.title(context),
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
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ).createShader(bounds),
                      child: Text(
                        '${(widget.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: centerFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (widget.statusText != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.statusText!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.body(context),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _CircularProgressPainter({required this.progress, this.strokeWidth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final inset = strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.textLight.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - inset, backgroundPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - inset),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
