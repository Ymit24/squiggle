//! Inline text editor laid exactly over the canvas text it edits (port of `text_edit_overlay.dart`
//! and `inline_text_editor.dart`). Escape, Cmd/Ctrl+Enter, or a press anywhere else commits.

use crate::state::State;
use crate::theme::{self, rune_color};
use rune::tok::TextStyle;
use rune::{Align, El, Key, KeyEvent, Tx, col, edit_access, el, text_input};
use squiggle_core::editor::text_edit::{TextEditKind, TextEditSession};
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::geom::Point;
use squiggle_core::label_layout::LabelLayout;
use squiggle_core::text_alignment::TextHorizontalAlignment;

fn edited_feature<'a>(s: &'a State, session: &'a TextEditSession) -> Option<&'a Feature> {
    match &session.kind {
        TextEditKind::Create { draft } => Some(draft),
        TextEditKind::Edit { feature_id } => s.ctx.document.feature(*feature_id),
    }
}

/// Edited text follows its feature, so anything that changes the feature mid-edit cannot leave
/// the field behind. Coordinates are root world space.
fn layout(s: &State, session: &TextEditSession) -> Option<LabelLayout> {
    let feature = edited_feature(s, session)?;
    let contents = &s.editor_ui.text.text;
    let layout = match &feature.kind {
        FeatureKind::Text(k) => k.label_layout_for(feature, contents),
        other => other.label_layout(feature)?,
    };
    let origin = match &session.kind {
        TextEditKind::Create { .. } => Point::ZERO,
        TextEditKind::Edit { feature_id } => {
            s.ctx.document.global_origin(s.ctx.document.parent_of(*feature_id).flatten())
        }
    };
    Some(layout.shifted(origin))
}

fn commit_on_key(s: &mut State, e: &KeyEvent, _tx: &mut Tx) -> bool {
    let commit = e.key == Key::Escape || (e.key == Key::Enter && (e.mods.cmd || e.mods.ctrl));
    if commit {
        s.ctx.commit_text_edit(None, true);
        s.autosave_if_changed();
    }
    commit
}

pub fn view(s: &State) -> El {
    let Some(session) = s.ctx.text_edit.session() else { return el() };
    let Some(layout) = layout(s, session) else { return el() };
    let cam = s.ctx.camera;
    let origin = cam.world_to_screen(layout.text_origin(&s.editor_ui.text.text));
    // Wider than the text by the caret so it wraps like the painter, and never zero-sized.
    let width = (cam.world_length_to_screen_length(layout.bounds.width()) as f32 + 3.0).max(12.0);
    let size = cam.world_length_to_screen_length(layout.font_size) as f32;
    let color = rune_color(layout.color);
    let field = text_input(&s.editor_ui.text, TextStyle::new(size, 400.0))
        .key("text-edit")
        .color(color)
        .caret(color, theme::accent().alpha(0.4))
        .align(match layout.horizontal_alignment {
            TextHorizontalAlignment::Left => Align::Start,
            TextHorizontalAlignment::Center => Align::Center,
            TextHorizontalAlignment::Right => Align::End,
        })
        .w(width)
        .on_edit(edit_access(|s: &mut State| &mut s.editor_ui.text))
        .on_input_change(|s: &mut State, _tx: &mut Tx| s.ctx.text_edit.draft = s.editor_ui.text.text.clone())
        .on_input_key(commit_on_key)
        // The field mounts after the click that opened it; focus it once it is on screen.
        .on_layout(|s: &mut State, _| {
            if !s.editor_ui.text_focus_done {
                s.editor_ui.text_focus_done = true;
                s.editor_ui.text.focused = true;
            }
        });
    let outlined = !matches!(&session.kind, TextEditKind::Edit { .. })
        || edited_feature(s, session).is_some_and(|f| matches!(f.kind, FeatureKind::Text(_)));
    let frame = if outlined { col().border(1.0, theme::accent()).padding(3.0) } else { col() };
    el().key("text-edit-layer")
        .absolute(0.0, 0.0)
        .w_full()
        .h_full()
        .child(frame.absolute(origin.x as f32 - 4.0, origin.y as f32 - 4.0).child(field))
}
