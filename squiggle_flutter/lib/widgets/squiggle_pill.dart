import 'package:flutter/material.dart';

class SquigglePill extends StatelessWidget {
  const SquigglePill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.borderColor,
    this.boxShadow,
    this.leading,
  });

  final String label;
  final Color backgroundColor;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: textStyle);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: boxShadow,
      ),
      child: leading == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [leading!, const SizedBox(width: 6), text],
            ),
    );
  }
}
