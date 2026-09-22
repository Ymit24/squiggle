import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// A text field with the bordered treatment used by library controls.
class SquiggleTextField extends StatelessWidget {
  const SquiggleTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.selectAllOnFocus = false,
    this.onTapOutside,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.hintText,
    this.hintStyle,
    this.contentPadding,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.focusBorderSide,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool selectAllOnFocus;
  final VoidCallback? onTapOutside;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final String? hintText;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final BorderSide? focusBorderSide;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.colors.surface1),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      selectAllOnFocus: selectAllOnFocus,
      onTapOutside: onTapOutside == null ? null : (_) => onTapOutside!(),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style ?? theme.typography.inputText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        isDense: true,
        filled: true,
        fillColor: theme.colors.surface0,
        contentPadding: contentPadding,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide:
              focusBorderSide ??
              BorderSide(color: theme.colors.accent.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
