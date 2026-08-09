import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.all,
    this.horizontal,
    this.vertical,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    
    return Padding(
      padding: responsive.padding(
        all: all,
        horizontal: horizontal,
        vertical: vertical,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: child,
    );
  }
}
