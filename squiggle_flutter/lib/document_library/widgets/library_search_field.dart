import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: focusNode.requestFocus,
        child: Container(
          key: const ValueKey('library-search'),
          height: libraryHeaderControlHeight,
          decoration: BoxDecoration(
            color: theme.colors.surface0,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: focusNode.hasFocus
                  ? theme.colors.accent.withValues(alpha: 0.6)
                  : theme.colors.surface1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(
                Icons.search_rounded,
                size: 17,
                color: theme.colors.subtext0,
              ),
              const SizedBox(width: 8),
              Expanded(
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
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (query.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: theme.colors.subtext0,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.surface1,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: theme.colors.surface1),
                    ),
                    child: Text(
                      '⌘/',
                      style: theme.typography.hotkey.copyWith(fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
