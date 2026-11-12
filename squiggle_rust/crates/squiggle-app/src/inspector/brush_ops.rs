//! Brush mutations through the core controller. Like Dart's `_onBrushChanged`, a change
//! refreshes the active drawing tool's preview.

use serde_json::Value;
use squiggle_core::editor::context::EditorContext;
use squiggle_core::session::BrushProfile;

fn changing(ctx: &mut EditorContext, f: impl FnOnce(&mut EditorContext)) {
    let before = ctx.brushes.revision();
    f(ctx);
    if ctx.brushes.revision() != before {
        ctx.refresh_brush_preview();
    }
}

pub fn activate(ctx: &mut EditorContext, id: &str) {
    changing(ctx, |c| c.brushes.activate(&mut c.document.session, id));
}

pub fn create(ctx: &mut EditorContext, name: &str) -> Result<BrushProfile, String> {
    let mut out = Err(String::new());
    changing(ctx, |c| out = c.brushes.create(&mut c.document.session, name));
    out
}

pub fn rename(ctx: &mut EditorContext, id: &str, name: &str) {
    changing(ctx, |c| c.brushes.rename(&mut c.document.session, id, name));
}

pub fn delete(ctx: &mut EditorContext, id: &str) {
    changing(ctx, |c| c.brushes.delete(&mut c.document.session, id));
}

pub fn move_brush(ctx: &mut EditorContext, id: &str, to_index: usize) {
    changing(ctx, |c| c.brushes.move_brush(&mut c.document.session, id, to_index));
}

pub fn set_field(ctx: &mut EditorContext, key: &str, value: Value) {
    changing(ctx, |c| c.brushes.set_field(&mut c.document.session, key, value));
}

pub fn clear_field(ctx: &mut EditorContext, key: &str) {
    changing(ctx, |c| c.brushes.clear_field(&mut c.document.session, key));
}
