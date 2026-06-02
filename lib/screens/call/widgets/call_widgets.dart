import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../models/call_models.dart';

/// Animated glowing avatar with pulsing ring
class GlowingAvatar extends StatefulWidget {
  final String? imageUrl;
  final String level;
  final double size;

  const GlowingAvatar({
    super.key,
    this.imageUrl,
    required this.level,
    this.size = 140,
  });

  @override
  State<GlowingAvatar> createState() => _GlowingAvatarState();
}

class _GlowingAvatarState extends State<GlowingAvatar>
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated outer ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: widget.size + 20,
              height: widget.size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(
                    alpha:
                        0.3 + 0.3 * math.sin(_controller.value * 2 * math.pi),
                  ),
                  width: 3,
                ),
              ),
            );
          },
        ),
        // Static inner ring
        Container(
          width: widget.size + 8,
          height: widget.size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
        ),
        // Avatar
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
            image: widget.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.imageUrl == null
              ? const Icon(Icons.person, size: 60, color: Colors.grey)
              : null,
        ),
        // Level badge
        if (widget.level.isNotEmpty)
          Positioned(
            right: 0,
            top: widget.size / 2 - 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.level,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Status badge pill (e.g., "🇪🇸 Spanish Speaker")
class StatusBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color? backgroundColor;

  const StatusBadge({
    super.key,
    required this.emoji,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress status item for finding match
class ProgressStatusItem extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isCompleted;

  const ProgressStatusItem({
    super.key,
    required this.text,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isCompleted) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green;
      borderColor = Colors.green;
    } else if (isActive) {
      bgColor = const Color(0xFF1E293B);
      textColor = Colors.white70;
      borderColor = Colors.transparent;
    } else {
      bgColor = const Color(0xFF1E293B);
      textColor = Colors.white54;
      borderColor = Colors.transparent;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check, color: Colors.green, size: 18)
          else if (isActive)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translation overlay card for video call
class TranslationOverlay extends StatelessWidget {
  final TranslationMessage message;

  const TranslationOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${message.speakerName} says:',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            message.originalText,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"${message.translatedText}"',
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Call control button
class CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool isActive;
  final Widget? child;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
    this.isActive = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child:
            child ??
            Icon(icon, color: iconColor ?? Colors.white, size: size * 0.4),
      ),
    );
  }
}

/// Tip card widget
class TipCard extends StatelessWidget {
  final String tip;

  const TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: GoogleFonts.inter(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative animated circles for background
class DecorativeCircles extends StatefulWidget {
  const DecorativeCircles({super.key});

  @override
  State<DecorativeCircles> createState() => _DecorativeCirclesState();
}

class _DecorativeCirclesState extends State<DecorativeCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CirclesPainter(_controller.value),
        );
      },
    );
  }
}

class CirclesPainter extends CustomPainter {
  final double animationValue;

  CirclesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw multiple decorative circles
    final circles = [
      {'center': Offset(size.width * 0.2, size.height * 0.25), 'radius': 100.0},
      {'center': Offset(size.width * 0.8, size.height * 0.35), 'radius': 80.0},
      {'center': Offset(size.width * 0.5, size.height * 0.45), 'radius': 150.0},
    ];

    for (var i = 0; i < circles.length; i++) {
      final circle = circles[i];
      final offset = math.sin(animationValue * 2 * math.pi + i) * 10;
      paint.color = AppColors.primary.withValues(
        alpha: 0.15 + 0.1 * math.sin(animationValue * 2 * math.pi + i),
      );
      canvas.drawCircle(
        (circle['center'] as Offset) + Offset(offset, offset * 0.5),
        (circle['radius'] as double),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
