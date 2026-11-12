# Porting Squiggle (Flutter → Rust + Rune)

Source of truth for behaviour: `../squiggle_flutter` (Dart). Target: this Cargo workspace.

```
crates/squiggle-core   pure logic, NO ui deps (serde_json only). Everything testable with `cargo test -p squiggle-core`.
crates/squiggle-app    Rune (https://github.com/anomalyco/rune) UI: pages, widgets, canvas rendering.
```

## Architecture rules

* **Core never imports Rune.** Rendering is a toolkit-independent display list (`paint.rs`:
  `DrawCmd::{Stroke, Fill, Text, Image}` in *world* coordinates). Kinds/tools emit it through
  `Painter`; the app rasterises it. Expand dashes/dots/hatching/ellipses to polylines/polygons in
  core; the renderer only knows strokes, polygon fills, text runs and images.
* **Tree model.** `Node = Feature | Group` is an owned value tree (no parent pointers, no
  `Rc<RefCell>`). Containers are addressed by `Container = Option<NodeId>` (`None` = document
  root). Lookup/parent/global-origin helpers are on `Document`.
* **Feature kinds** are a closed enum (`FeatureKind`) with one struct per kind in
  `feature_kinds/`. The enum dispatches; per-kind behaviour lives in the kind struct. Persisted JSON
  format must stay byte-compatible with the Dart app (`version: 2`, same field names/values) so
  existing documents open.
* **Dart `ChangeNotifier`s** become plain structs with a `revision`/dirty counter or just plain
  mutable state; the Rune view function re-reads state each frame. No listeners/callbacks.
* **Dart `Tool`/`InteractionState`** become a Rust trait / enum state machine. Tools take
  `&mut EditorContext`; the active tool is temporarily taken out of the context while it runs
  (`Option::take`) to satisfy the borrow checker.
* **Text measurement** goes through `text_measure::measure_text` (pluggable; heuristic default).
* **Images** are referenced by id; bytes live in an image repository (not in the document JSON
  unless the Dart format does — read `image_repository.dart` / `feature_kind_image.dart`).
* **No `unwrap()` on fallible user data** (JSON, files); return `Result<_, String>` or a typed error.
* Idiomatic, concise Rust; follow the Dart repo's AGENTS.md spirit: short methods, low nesting,
  one responsibility per file. `cargo clippy` clean where practical.
* **Tests:** port the matching Dart tests in `../squiggle_flutter/test/**` as `#[cfg(test)]`
  modules (or `tests/*.rs`). Preserve what each test asserts. Widget tests (Flutter-specific UI
  tests) are only ported once the Rune UI exists.

## Foundation already written (do not redesign; extend carefully)

`geom` (Point/Size/Rect, Flutter semantics), `color` (ARGB u32), `camera`, `ids`, `node`,
`feature` (`Feature::resize` swaps a default kind in while the real kind's `apply_bounds` runs),
`group`, `document` (insert/remove_all/reorder/parent_of/global_origin/...), `session`
(`DocumentSession`, `BrushProfile`), `paint` (display list + `Painter`), `text_measure`.

Feature kind structs in `feature_kinds/*.rs` are **stubs** holding raw JSON until ported.

## Ownership (to avoid merge conflicts, edit only your files)

| Area | Files |
|------|-------|
| Kinds & painting | `feature_kind.rs`, `feature_kinds/**`, `painting/**`, enums (`fill_type`, `stroke_type`, `line_end_cap`, `stroke_width`, `font_size_preset`, `text_alignment`, `text_sizing`), `label_layout`, `feature_geometry`, `style_values` (style_value_serialization), `inspector/**` (inspector fields), `brush_apply` |
| History & commands | `editor/history/**`, `editor/selection.rs`, `editor/*_commands.rs`, `services/duplicate_nodes.rs`, `brush_controller.rs`, `text_edit_model.rs` |
| Persistence | `repositories/**`, `services/clipboard.rs` |
| Tools / EditorContext | `tools/**`, `editor/context.rs`, `editor/tool_model.rs` |
| UI | `crates/squiggle-app/**` |

Each owner appends `pub mod` lines for new top-level modules to `lib.rs` in the block
`// --- <area> modules ---` reserved for them; the integrator resolves any merge noise.
