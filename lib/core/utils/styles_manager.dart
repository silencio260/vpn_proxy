import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'font_manager.dart';

class StylesManager {
  static TextStyle title({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: FontSize.s20,
        fontWeight: AppFontWeight.bold,
        color: color,
      );

  static TextStyle subtitle({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontSize: FontSize.s14,
        fontWeight: AppFontWeight.medium,
        color: color,
      );

  static TextStyle body({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: FontSize.s16,
        fontWeight: AppFontWeight.regular,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontSize: FontSize.s12,
        fontWeight: AppFontWeight.medium,
        color: color,
      );

  static TextStyle label({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: FontSize.s13,
        fontWeight: AppFontWeight.medium,
        color: color,
      );
}
