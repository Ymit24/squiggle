import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DocumentPreviewPlaceholder extends StatefulWidget {
  const DocumentPreviewPlaceholder({super.key});

  @override
  State<DocumentPreviewPlaceholder> createState() =>
      _DocumentPreviewPlaceholderState();
}

class _DocumentPreviewPlaceholderState extends State<DocumentPreviewPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ColoredBox(
            color: Color.lerp(colors.base, colors.surface0, _controller.value)!,
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
