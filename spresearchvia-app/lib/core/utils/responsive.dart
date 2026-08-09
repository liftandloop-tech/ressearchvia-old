import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;
  late final double _screenWidth;
  late final double _screenHeight;
  late final Orientation _orientation;

  Responsive(this.context) {
    _mediaQuery = MediaQuery.of(context);
    _screenWidth = _mediaQuery.size.width;
    _screenHeight = _mediaQuery.size.height;
    _orientation = _mediaQuery.orientation;
  }

  double get width => _screenWidth;
  double get height => _screenHeight;
  double get aspectRatio => _screenWidth / _screenHeight;
  Orientation get orientation => _orientation;
  bool get isPortrait => _orientation == Orientation.portrait;
  bool get isLandscape => _orientation == Orientation.landscape;

  bool get isMobile => _screenWidth < 600;
  bool get isTablet => _screenWidth >= 600 && _screenWidth < 900;
  bool get isDesktop => _screenWidth >= 900;
  bool get isSmallPhone => _screenWidth < 360;
  bool get isMediumPhone => _screenWidth >= 360 && _screenWidth < 400;
  bool get isLargePhone => _screenWidth >= 400 && _screenWidth < 600;

  double wp(double percentage) => _screenWidth * percentage / 100;
  double hp(double percentage) => _screenHeight * percentage / 100;

  double sp(double size) {
    const baseWidth = 375.0;
    final scale = _screenWidth / baseWidth;
    return size * scale.clamp(0.8, 1.3);
  }

  double spacing(double base) {
    if (isSmallPhone) return base * 0.8;
    if (isTablet) return base * 1.2;
    if (isDesktop) return base * 1.5;
    return base;
  }

  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: spacing(left ?? horizontal ?? all ?? 0),
      top: spacing(top ?? vertical ?? all ?? 0),
      right: spacing(right ?? horizontal ?? all ?? 0),
      bottom: spacing(bottom ?? vertical ?? all ?? 0),
    );
  }

  double radius(double base) => spacing(base);

  EdgeInsets get safeAreaPadding => _mediaQuery.padding;
  double get topSafeArea => _mediaQuery.padding.top;
  double get bottomSafeArea => _mediaQuery.padding.bottom;

  double get textScaleFactor =>
      _mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.3);

  double get pixelRatio => _mediaQuery.devicePixelRatio;

  static Responsive of(BuildContext context) => Responsive(context);
}

extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
