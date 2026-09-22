import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
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
      style: theme.typography.inputText.copyWith(
        fontSize: compact ? 13.5 : 14.5,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colors.subtext0.withValues(alpha: compact ? 0.7 : 0.6),
          fontSize: compact ? 13.5 : null,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colors.surface0,
        contentPadding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        prefixIcon: prefixIcon,
        prefixIconConstraints: compact
            ? const BoxConstraints(minWidth: 36, minHeight: 38)
            : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: compact
            ? const BoxConstraints(minWidth: 42, minHeight: 38)
            : null,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: theme.colors.accent.withValues(alpha: compact ? 0.6 : 0.7),
            width: compact ? 1 : 1.4,
          ),
        ),
      ),
    );
  }
}
