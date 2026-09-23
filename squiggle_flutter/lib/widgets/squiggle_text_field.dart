import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

typedef _FieldStyle = ({
  double fontSize,
  double hintOpacity,
  double? hintFontSize,
  EdgeInsetsGeometry contentPadding,
  BoxConstraints? prefixIconConstraints,
  BoxConstraints? suffixIconConstraints,
  double focusOpacity,
  double focusWidth,
});

_FieldStyle _resolveStyles(bool compact) {
  if (compact) {
    return (
      fontSize: 13.5,
      hintOpacity: 0.7,
      hintFontSize: 13.5,
      contentPadding: EdgeInsets.zero,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 38),
      suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
      focusOpacity: 0.6,
      focusWidth: 1,
    );
  }
  return (
    fontSize: 14.5,
    hintOpacity: 0.6,
    hintFontSize: null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    prefixIconConstraints: null,
    suffixIconConstraints: null,
    focusOpacity: 0.7,
    focusWidth: 1.4,
  );
}

/// A bordered text field for dialogs and compact library controls.
class SquiggleTextField extends StatelessWidget {
  const SquiggleTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.onTapOutside,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;

  /// Autofocused fields select their initial text for easy replacement.
  final bool autofocus;
  final VoidCallback? onTapOutside;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// Uses the library header's smaller text, padding, and focus ring.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final fieldStyle = _resolveStyles(compact);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(theme.radii.input),
      borderSide: BorderSide(color: theme.colors.surface1),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      selectAllOnFocus: autofocus,
      onTapOutside: onTapOutside == null ? null : (_) => onTapOutside!(),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: theme.typography.inputText.copyWith(fontSize: fieldStyle.fontSize),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colors.subtext0.withValues(
            alpha: fieldStyle.hintOpacity,
          ),
          fontSize: fieldStyle.hintFontSize,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colors.surface0,
        contentPadding: fieldStyle.contentPadding,
        prefixIcon: prefixIcon,
        prefixIconConstraints: fieldStyle.prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: fieldStyle.suffixIconConstraints,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: theme.colors.accent.withValues(
              alpha: fieldStyle.focusOpacity,
            ),
            width: fieldStyle.focusWidth,
          ),
        ),
      ),
    );
  }
}
