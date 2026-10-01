import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_panel.dart';

/// Opens a positioned menu on the root navigator with no transition or scrim.
Future<void> showSquiggleContextMenu({
  required BuildContext context,
  required WidgetBuilder builder,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  PageRouteBuilder<void>(
    barrierDismissible: true,
    opaque: false,
    barrierColor: null,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => Stack(children: [builder(context)]),
  ),
);

class SquiggleContextMenu extends StatefulWidget {
  const SquiggleContextMenu({
    super.key,
    required this.position,
    required this.children,
  });

  final Offset position;
  final List<Widget> children;

  @override
  State<SquiggleContextMenu> createState() => _SquiggleContextMenuState();
}

class _SquiggleContextMenuState extends State<SquiggleContextMenu> {
  final GlobalKey _key = GlobalKey();
  Offset _position = Offset.zero;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final screenSize = MediaQuery.sizeOf(context);
      final padding = context.squiggleTheme.spacing.panelPadding;
      setState(() {
        _position = Offset(
          widget.position.dx.clamp(
            padding,
            (screenSize.width - box.size.width - padding).clamp(
              padding,
              double.infinity,
            ),
          ),
          widget.position.dy.clamp(
            padding,
            (screenSize.height - box.size.height - padding).clamp(
              padding,
              double.infinity,
            ),
          ),
        );
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: _position.dx,
    top: _position.dy,
    child: Opacity(
      opacity: _visible ? 1 : 0,
      child: SquiggleMenuPanel(key: _key, children: widget.children),
    ),
  );
}
