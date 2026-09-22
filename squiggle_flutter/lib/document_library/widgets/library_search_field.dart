import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

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
    return SizedBox(
      key: const ValueKey('library-search'),
      height: libraryHeaderControlHeight,
      child: SquiggleTextField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: onTapOutside,
        onChanged: onChanged,
        hintText: 'Search canvases…',
        compact: true,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 17,
          color: theme.colors.subtext0,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: libraryHeaderControlHeight,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: theme.colors.subtext0,
                ),
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
      ),
    );
  }
}
