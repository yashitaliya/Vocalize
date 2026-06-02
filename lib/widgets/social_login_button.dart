import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';

enum SocialLoginType { google, facebook, apple }

/// Social login button with branded icons
class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: type == SocialLoginType.google
            ? Border.all(color: AppColors.inputBorder, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: FaIcon(_getIcon(), color: _getIconColor(), size: 24),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case SocialLoginType.google:
        return AppColors.googleButton;
      case SocialLoginType.facebook:
        return AppColors.facebookButton;
      case SocialLoginType.apple:
        return AppColors.appleButton;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case SocialLoginType.google:
        return FontAwesomeIcons.google;
      case SocialLoginType.facebook:
        return FontAwesomeIcons.facebookF;
      case SocialLoginType.apple:
        return FontAwesomeIcons.apple;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case SocialLoginType.google:
        return AppColors.textPrimary;
      case SocialLoginType.facebook:
        return Colors.white;
      case SocialLoginType.apple:
        return Colors.white;
    }
  }
}
