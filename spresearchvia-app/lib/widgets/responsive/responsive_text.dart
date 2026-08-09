import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool autoScale;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.autoScale = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    
    if (!autoScale || style == null) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final scaledStyle = style!.copyWith(
      fontSize: style!.fontSize != null ? responsive.sp(style!.fontSize!) : null,
    );

    return Text(
      text,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
