import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';

class LibraryContentBounds extends StatelessWidget {
  const LibraryContentBounds({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final horizontal = libraryHorizontalPadding(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxLibraryWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
          child: child,
        ),
      ),
    );
  }
}
