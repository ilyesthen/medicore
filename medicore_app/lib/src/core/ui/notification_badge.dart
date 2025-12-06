import 'package:flutter/material.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_typography.dart';

/// Enterprise-grade notification badge for unread message counts
class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : count.toString();
    final bgColor = backgroundColor ?? MediCoreColors.criticalRed;
    final fgColor = textColor ?? Colors.white;

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.3,
        vertical: size * 0.15,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayCount,
        style: MediCoreTypography.button.copyWith(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          color: fgColor,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Notification badge positioned over a button
class BadgedButton extends StatelessWidget {
  final Widget child;
  final int badgeCount;
  final Alignment badgeAlignment;
  final Color? badgeColor;

  const BadgedButton({
    super.key,
    required this.child,
    required this.badgeCount,
    this.badgeAlignment = Alignment.topRight,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount > 0) {
      print('🔴 RENDERING BADGE with count: $badgeCount');
    }
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (badgeCount > 0)
          Positioned(
            right: badgeAlignment == Alignment.topRight ? -8 : null,
            top: badgeAlignment == Alignment.topRight ? -8 : null,
            left: badgeAlignment == Alignment.topLeft ? -8 : null,
            child: NotificationBadge(count: badgeCount, backgroundColor: badgeColor),
          ),
      ],
    );
  }
}
