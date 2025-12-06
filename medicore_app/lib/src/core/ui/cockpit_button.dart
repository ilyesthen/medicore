import 'package:flutter/material.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_typography.dart';
import '../theme/medicore_dimensions.dart';

/// Cockpit-style Button - Weighty & Tactile
/// Semi-skeuomorphic with gradient and border
class CockpitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  
  const CockpitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    
    return Container(
      height: MediCoreDimensions.buttonHeight,
      decoration: BoxDecoration(
        gradient: isEnabled 
            ? MediCoreColors.buttonGradient 
            : null,
        color: isEnabled 
            ? null 
            : MediCoreColors.inactiveGrey,
        borderRadius: BorderRadius.circular(MediCoreDimensions.radiusSmall),
        border: Border.all(
          color: isEnabled 
              ? MediCoreColors.deepNavy 
              : MediCoreColors.steelOutline,
          width: MediCoreDimensions.buttonBorderWidth,
        ),
        boxShadow: isEnabled ? MediCoreColors.buttonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MediCoreDimensions.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MediCoreDimensions.buttonPaddingH,
              vertical: MediCoreDimensions.buttonPaddingV,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isEnabled ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(width: MediCoreDimensions.spacingS),
                ],
                Text(
                  label,
                  style: MediCoreTypography.button.copyWith(
                    color: isEnabled ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
