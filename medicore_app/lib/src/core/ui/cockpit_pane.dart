import 'package:flutter/material.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_typography.dart';
import '../theme/medicore_dimensions.dart';

/// Cockpit Pane - Rigid bordered section with title bar
/// Key visual element: visible 1px borders around every pane
class CockpitPane extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBorder;
  
  const CockpitPane({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder ? Border.all(
          color: MediCoreColors.steelOutline,
          width: MediCoreDimensions.paneBorderWidth,
        ) : null,
        color: MediCoreColors.paperWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Bar
          Container(
            height: MediCoreDimensions.paneTitleBarHeight,
            decoration: const BoxDecoration(
              color: MediCoreColors.paneTitleBar,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: MediCoreDimensions.paneTitleBarBottomBorder,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MediCoreDimensions.spacingM,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: MediCoreTypography.paneTitleBar,
                ),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          // Content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
