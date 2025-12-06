import 'package:flutter/material.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_typography.dart';
import '../theme/medicore_dimensions.dart';

/// Cockpit-style Input Field - Inset Look
/// Background: slightly off-white, bordered, focused state with thick navy border
class CockpitInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool obscureText;
  
  const CockpitInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.enabled = true,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: MediCoreTypography.label,
          ),
          const SizedBox(height: MediCoreDimensions.spacingXs),
        ],
        Container(
          height: maxLines == 1 ? MediCoreDimensions.inputHeight : null,
          decoration: BoxDecoration(
            color: enabled 
                ? MediCoreColors.inputBackground 
                : MediCoreColors.canvasGrey,
            borderRadius: BorderRadius.circular(MediCoreDimensions.radiusSmall),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            obscureText: obscureText,
            style: MediCoreTypography.inputField,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: MediCoreTypography.inputField.copyWith(
                color: Colors.grey[500],
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MediCoreDimensions.inputPaddingH,
                vertical: MediCoreDimensions.spacingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  MediCoreDimensions.radiusSmall,
                ),
                borderSide: const BorderSide(
                  color: MediCoreColors.inputBorder,
                  width: MediCoreDimensions.inputBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  MediCoreDimensions.radiusSmall,
                ),
                borderSide: const BorderSide(
                  color: MediCoreColors.inputBorder,
                  width: MediCoreDimensions.inputBorderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  MediCoreDimensions.radiusSmall,
                ),
                borderSide: const BorderSide(
                  color: MediCoreColors.deepNavy,
                  width: MediCoreDimensions.inputFocusBorderWidth,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  MediCoreDimensions.radiusSmall,
                ),
                borderSide: BorderSide(
                  color: MediCoreColors.steelOutline.withOpacity(0.5),
                  width: MediCoreDimensions.inputBorderWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
