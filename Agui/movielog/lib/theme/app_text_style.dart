import 'package:flutter/material.dart';

import 'app_colors.dart';

/// MovieLog typography tokens from the Figma Typography Guide.
///
/// Values in the guide are expressed as `fontSize / lineHeight /
/// letterSpacing`. Flutter's [TextStyle.height] is a multiplier, so the
/// line-height values are converted to the corresponding ratios below.
abstract final class AppTextStyles {
  static const textTheme = TextTheme(
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    labelLarge: labelLarge,
    labelSmall: labelSmall,

    // Existing app aliases.
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodySmall: bodySmall,
  );

  // Title Large (Headline Large): 28px / 36px / 0px
  static const headlineLargeBold = TextStyle(
    fontSize: 28,
    height: 1.2857142857,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const headlineLargeSemiBold = TextStyle(
    fontSize: 28,
    height: 1.2857142857,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const headlineLargeMedium = TextStyle(
    fontSize: 28,
    height: 1.2857142857,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const headlineLargeRegular = TextStyle(
    fontSize: 28,
    height: 1.2857142857,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  // Title Medium (Headline Medium): 24px / 32px / 0px
  static const headlineMediumBold = TextStyle(
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const headlineMediumSemiBold = TextStyle(
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const headlineMediumMedium = TextStyle(
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const headlineMediumRegular = TextStyle(
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  // Body Large: 16px / 24px / 0.5px
  static const bodyLargeBold = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const bodyLargeSemiBold = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const bodyLargeMedium = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const bodyLargeRegular = TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  // Body Medium: 14px / 20px / 0.25px
  static const bodyMediumBold = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const bodyMediumSemiBold = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const bodyMediumMedium = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const bodyMediumRegular = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  // Label Large (Button Label): 14px / 20px / 0.1px
  static const labelLargeBold = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const labelLargeSemiBold = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const labelLargeMedium = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const labelLargeRegular = TextStyle(
    fontSize: 14,
    height: 1.4285714286,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  // Label Small (Metadata & Captions): 11px / 16px / 0.5px
  static const labelSmallBold = TextStyle(
    fontSize: 11,
    height: 1.4545454545,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.gray,
  );

  static const labelSmallSemiBold = TextStyle(
    fontSize: 11,
    height: 1.4545454545,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
    color: AppColors.gray,
  );

  static const labelSmallMedium = TextStyle(
    fontSize: 11,
    height: 1.4545454545,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: AppColors.gray,
  );

  static const labelSmallRegular = TextStyle(
    fontSize: 11,
    height: 1.4545454545,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );

  // Semantic defaults used by TextTheme.
  static const headlineLarge = headlineLargeBold;
  static const headlineMedium = headlineMediumSemiBold;
  static const bodyLarge = bodyLargeRegular;
  static const bodyMedium = bodyMediumRegular;
  static const labelLarge = labelLargeMedium;
  static const labelSmall = labelSmallRegular;

  // Backwards-compatible aliases for existing screens.
  static const titleLarge = headlineLarge;
  static const titleMedium = headlineMedium;
  static const bodySmall = labelSmall;
}
