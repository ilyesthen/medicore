import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/medicore_dimensions.dart';

/// Fixed Canvas Scaler - "The Cockpit" Design System
/// Scales entire app based on master resolution (1440x900)
/// Everything zooms proportionally - no reflowing or layout shifts
class CanvasScaler extends StatelessWidget {
  final Widget child;
  
  const CanvasScaler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        MediCoreDimensions.designWidth,
        MediCoreDimensions.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return child!;
      },
      child: child,
    );
  }
}

/// Extension for responsive sizing using .w, .h, .sp
/// Usage: 
/// - width: 200.w  (200px on 1440px screen, scales proportionally)
/// - height: 50.h
/// - fontSize: 14.sp
extension ResponsiveExt on num {
  double get w => ScreenUtil().setWidth(this);
  double get h => ScreenUtil().setHeight(this);
  double get sp => ScreenUtil().setSp(this);
  double get r => ScreenUtil().radius(this);
}
