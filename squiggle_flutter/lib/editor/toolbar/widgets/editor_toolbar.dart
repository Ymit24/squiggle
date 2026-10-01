import 'package:flutter/material.dart' hide Divider;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/button.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/divider.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/gap.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Floating toolbar overlay, matching rust-version layout and styling.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.read<EditorContext>();
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return Positioned(
      top: spacing.overlayTop,
      left: 0,
      right: 0,
      child: Center(
        child: ListenableBuilder(
          listenable: Listenable.merge([editor.tool, editor.history]),
          builder: (context, _) {
            final activeTool = editor.tool.activeTool;
            return DecoratedBox(
              decoration: theme.decorations.floatingPanel(),
              child: Padding(
                padding: EdgeInsets.all(spacing.toolbarPadding),
                child: SizedBox(
                  height: spacing.toolbarButtonSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Semantics(
                        label: 'Keep drawing tool active',
                        toggled: editor.tool.isLocked,
                        child: Button(
                          icon: editor.tool.isLocked
                              ? LucideIcons.lock
                              : LucideIcons.lockOpen,
                          hotkey: 'Q',
                          isActive: editor.tool.isLocked,
                          onPressed: editor.tool.toggleLock,
                        ),
                      ),
                      const Gap(),
                      const Divider(),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/arrow_selector_tool.svg',
                        hotkey: '1',
                        isActive: activeTool is SelectTool,
                        onPressed: () => editor.setTool(SelectTool()),
                      ),
                      const Gap(),
                      const Divider(),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/crop_square.svg',
                        hotkey: '2',
                        isActive:
                            activeTool is CreateFeatureTool &&
                            activeTool.kind is FeatureKindRectangle,
                        onPressed: () =>
                            editor.setTool(CreateFeatureTool.rect()),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/circle.svg',
                        hotkey: '3',
                        isActive:
                            activeTool is CreateFeatureTool &&
                            activeTool.kind is FeatureKindCircle,
                        onPressed: () =>
                            editor.setTool(CreateFeatureTool.circle()),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/line.svg',
                        hotkey: '4',
                        isActive: activeTool is CreateLineTool,
                        onPressed: () => editor.setTool(CreateLineTool()),
                      ),
                      const Gap(),
                      Button(
                        label: 'A',
                        hotkey: '5',
                        isActive: activeTool is CreateTextTool,
                        onPressed: () => editor.setTool(CreateTextTool()),
                      ),
                      const Gap(),
                      const Divider(),
                      const Gap(),
                      Button(
                        icon: Icons.undo,
                        isActive: false,
                        onPressed: editor.history.canUndo ? editor.undo : null,
                      ),
                      const Gap(),
                      Button(
                        icon: Icons.redo,
                        isActive: false,
                        onPressed: editor.history.canRedo ? editor.redo : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
