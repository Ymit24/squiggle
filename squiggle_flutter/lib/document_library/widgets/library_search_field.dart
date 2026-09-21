import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onTapOutside,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTapOutside;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.colors.surface1),
    );

    return SizedBox(
      key: const ValueKey('library-search'),
      height: libraryHeaderControlHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: (_) => onTapOutside(),
        onChanged: onChanged,
        style: theme.typography.inputText.copyWith(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search canvases…',
          hintStyle: TextStyle(
            color: theme.colors.subtext0.withValues(alpha: 0.7),
            fontSize: 13.5,
          ),
          isDense: true,
          filled: true,
          fillColor: theme.colors.surface0,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 17,
            color: theme.colors.subtext0,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: libraryHeaderControlHeight,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: libraryHeaderControlHeight,
          ),
          suffixIcon: query.isNotEmpty
              ? SquiggleButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 15),
                  tooltip: 'Clear search',
                  variant: SquiggleButtonVariant.ghost,
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colors.surface1,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          '⌘/',
                          style: theme.typography.hotkey.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(
              color: theme.colors.accent.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
