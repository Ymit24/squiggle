import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_menu_entry.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_name_dialog.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/delete_brush_dialog.dart';
import 'package:squiggle_flutter/models/document_session.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

class BrushPicker extends StatefulWidget {
  const BrushPicker({
    super.key,
    required this.editorContext,
    required this.imageRepository,
  });
  final EditorContext editorContext;
  final ImageRepository imageRepository;

  @override
  State<BrushPicker> createState() => _BrushPickerState();
}

class _BrushPickerState extends State<BrushPicker> {
  final _picker = MenuController();
  final _actions = MenuController();

  Future<void> _create() async {
    final editor = widget.editorContext;
    final sourceId = editor.activeBrush.id;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const BrushNameDialog(creating: true),
    );
    if (!mounted ||
        name == null ||
        editor.activeBrush.id != sourceId ||
        !editor.document.session.canCreateBrush) {
      return;
    }
    editor.createBrush(name);
  }

  Future<void> _rename() async {
    final editor = widget.editorContext;
    final brush = editor.activeBrush;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => BrushNameDialog(creating: false, initialName: brush.name),
    );
    if (!mounted || name == null) return;
    editor.renameBrush(brush.id, name);
  }

  Future<void> _delete() async {
    final editor = widget.editorContext;
    final brush = editor.activeBrush;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteBrushDialog(name: brush.name),
    );
    if (mounted && confirmed == true) editor.deleteBrush(brush.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final editor = widget.editorContext;
    final brush = editor.activeBrush;
    final width = theme.spacing.menuWidth;
    final buttonStyle = theme.menuItemStyle().copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: theme.colors.surface1)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brush'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: MenuAnchor(
                controller: _picker,
                consumeOutsideTap: false,
                alignmentOffset: Offset(-theme.spacing.panelPadding, 2),
                style: theme.menuStyle().copyWith(
                  fixedSize: WidgetStatePropertyAll(Size.fromWidth(width)),
                ),
                menuChildren: [
                  for (final (index, item)
                      in editor.document.session.brushes.indexed)
                    BrushMenuEntry(
                      brush: item,
                      shortcutNumber: index < DocumentSession.maxBrushes
                          ? index + 1
                          : null,
                      selected: item.id == brush.id,
                      imageRepository: widget.imageRepository,
                      onPressed: () => editor.activateBrush(item.id),
                    ),
                  const Divider(height: 12),
                  SquiggleMenuItem(
                    label: 'Create brush',
                    icon: Icons.add,
                    onPressed: editor.document.session.canCreateBrush
                        ? _create
                        : null,
                  ),
                ],
                builder: (context, controller, _) => TextButton(
                  key: const ValueKey('brush-picker-trigger'),
                  style: buttonStyle,
                  onPressed: () {
                    _actions.close();
                    controller.isOpen ? controller.close() : controller.open();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          brush.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            if (!brush.isScratch) ...[
              const SizedBox(width: 4),
              MenuAnchor(
                controller: _actions,
                consumeOutsideTap: false,
                style: theme.menuStyle(),
                menuChildren: [
                  SquiggleMenuItem(
                    label: 'Rename…',
                    icon: Icons.edit_outlined,
                    onPressed: _rename,
                  ),
                  SquiggleMenuItem(
                    label: 'Delete brush',
                    icon: Icons.delete_outline,
                    danger: true,
                    onPressed: _delete,
                  ),
                ],
                builder: (context, controller, _) => Tooltip(
                  message: 'Manage active brush',
                  child: SizedBox(
                    width: 28,
                    child: TextButton(
                      key: const ValueKey('brush-actions-trigger'),
                      style: buttonStyle,
                      onPressed: () {
                        _picker.close();
                        controller.isOpen
                            ? controller.close()
                            : controller.open();
                      },
                      child: const Icon(Icons.more_horiz, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
