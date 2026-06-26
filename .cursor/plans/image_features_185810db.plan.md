---
name: image features
overview: Add pasted-image features by storing clipboard images as app-data assets and representing each canvas image as a lightweight feature reference. Rendering will resolve those references through an injected image repository with lazy decode/cache behavior.
todos:
  - id: add-deps
    content: Add clipboard and app-data dependencies to the Flutter package.
    status: completed
  - id: image-repo
    content: Implement image asset storage, lazy decode, cache, and repaint notifications.
    status: completed
  - id: feature-kind
    content: Add `FeatureKindImage` and refactor painting to receive `ImageRepository` directly.
    status: completed
  - id: paste-flow
    content: Wire viewport paste shortcuts to import clipboard images and create image features.
    status: completed
  - id: tests
    content: Add focused tests and run analyzer/test suite.
    status: completed
isProject: false
---

# Image Feature Plan

## Recommended Shape

- Add dependencies in [squiggle_flutter/pubspec.yaml](squiggle_flutter/pubspec.yaml):
  - `path_provider` for the platform app-support/app-data directory.
  - `super_clipboard` for desktop image clipboard access, since Flutter's built-in clipboard is not enough for image payloads.
- Store pasted clipboard images as PNG files under an app data subdirectory like `.../Squiggle/images/`.
  - PNG is the safest default for clipboard bitmaps: lossless, preserves alpha, universally decodable by Flutter, and avoids quality surprises.
  - Generate opaque asset ids/filenames such as `img_<timestamp>_<random>.png`; the feature stores only that filename/id.

## Model And Repository

- Add a new feature kind in [squiggle_flutter/lib/models/feature_kinds/feature_kind.dart](squiggle_flutter/lib/models/feature_kinds/feature_kind.dart), for example `FeatureKindImage(imageId: String)`.
- Keep `Feature` unchanged structurally: `origin`, `size`, and `kind` already fit images.
- Add an `ImageRepository` under [squiggle_flutter/lib/repositories/](squiggle_flutter/lib/repositories/) that owns:
  - app image directory creation,
  - clipboard image import to PNG,
  - lazy `ui.Image` decoding from disk,
  - in-memory cache keyed by image id,
  - a repaint/change stream so the canvas repaints when an async decode completes.

## Rendering Flow

- Refactor feature painting from the current no-context call:

```236:252:squiggle_flutter/lib/widgets/document_canvas.dart
void _paintFeatures(Canvas canvas, Document document) {
  final zoom = _camera.zoom;
  if (zoom <= 0) return;

  // ...

  for (final feature in document.features) {
    final worldBounds = feature.bounds();
    if (!worldBounds.overlaps(visibleWorld)) continue;

    feature.paint(canvas);
  }
}
```

- Pass `ImageRepository` directly through `Feature.paint(...)` / `FeatureKind.paint(...)` for now, avoiding a broader paint context until another render dependency makes it worthwhile.
- `FeatureKindImage.paint(...)` should:
  - request the cached/decoded image by id,
  - draw a subtle placeholder while decode is pending or unavailable,
  - call `canvas.drawImageRect(...)` when loaded, fitting into `feature.bounds()`.
- Wire `ImageRepository` into [squiggle_flutter/lib/main.dart](squiggle_flutter/lib/main.dart), [squiggle_flutter/lib/editor/editor.dart](squiggle_flutter/lib/editor/editor.dart), [squiggle_flutter/lib/widgets/document_viewport.dart](squiggle_flutter/lib/widgets/document_viewport.dart), and [squiggle_flutter/lib/widgets/document_canvas.dart](squiggle_flutter/lib/widgets/document_canvas.dart).

## Paste Behavior

- Add `Cmd+V` / `Ctrl+V` image paste handling at the viewport layer, not inside tools, because [squiggle_flutter/lib/widgets/document_viewport.dart](squiggle_flutter/lib/widgets/document_viewport.dart) owns the current camera and can place the image at the visible canvas center.
- On paste:
  - read the first image payload from the clipboard,
  - encode/store it as PNG via `ImageRepository`,
  - derive the feature size from the decoded image dimensions, clamped to a reasonable max world size if very large,
  - create `Feature(kind: FeatureKindImage(imageId), origin: viewportCenter - size / 2, size: size)`,
  - add it through `AddFeatureCommand` so undo/redo works.
- Leave text editing behavior alone: paste should be ignored by the canvas while the text edit overlay is open.

## Tests And Validation

- Add focused unit tests for `FeatureKindImage` geometry/copy/style behavior where practical.
- Add repository tests around image id generation/path resolution using a temp directory-friendly constructor.
- Add a widget/interaction test for `Cmd+V`/`Ctrl+V` dispatch where feasible; if clipboard image mocking is awkward, isolate paste creation behind a method and test that method directly.
- Run Flutter analyzer and the existing tests after implementation.