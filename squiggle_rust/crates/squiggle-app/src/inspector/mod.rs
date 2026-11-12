//! Inspector panel, brush picker and brush wheel (port of `lib/editor/inspector` and
//! `lib/editor/brush_wheel`).
//!
//! * [`panel`] is the floating inspector (pinned to the editor's top-right; an empty element when
//!   there is nothing to show).
//! * [`overlays`] holds what must cover the whole editor: brush dialogs and the brush wheel.
//!   Render it as the last child of the editor root.
//! * [`brush_wheel::host`] has the open/close/pointer API the key handler drives.

mod alignment_swatch;
mod brush_dropdown;
mod brush_field_reset_button;
mod brush_menu_entry;
mod brush_name_dialog;
pub mod brush_ops;
mod brush_picker;
mod brush_reorder_row;
mod brush_sample;
pub mod brush_wheel;
mod choice_row;
mod color_row;
mod delete_brush_dialog;
mod dialog;
mod drawing_inspector_fields;
mod edits;
mod field_control;
mod field_shell;
mod fill_type_selector;
mod font_size_selector;
mod icons;
mod inspector_fields;
mod layout_actions;
mod layout_swatch;
mod line_end_cap_selector;
mod metrics;
mod node_align_selector;
mod node_distribute_selector;
mod stroke_type_selector;
mod stroke_width_selector;
mod style_swatch;
mod text_auto_width_action;
mod text_horizontal_alignment_selector;
mod text_vertical_alignment_selector;

#[cfg(test)]
mod tests;

use crate::kit::{floating_panel, metrics as kit_metrics};
use crate::state::State;
use rune::{El, ScrollSpec, TextEdit, col, el};
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::geom::Point;

/// Which brush dialog is open; the name field's text is [`InspectorUi::name_edit`].
#[derive(Clone, Debug, PartialEq)]
pub enum BrushDialog {
    /// Creates a brush from `source_id`, unless the active brush changed meanwhile.
    Create { source_id: String },
    Rename { id: String },
    Delete { id: String, name: String },
}

/// A named-brush drag in progress: `from` and `target` index the named brushes (Scratch excluded).
#[derive(Clone, Debug, PartialEq)]
pub struct Reorder {
    pub id: String,
    pub from: usize,
    pub target: usize,
}

/// The open brush wheel.
pub struct WheelState {
    /// Wheel centre in editor points.
    pub center: Point,
    pub kind: FeatureKind,
    /// Slot under the pointer; the add slot is `brushes.len()`.
    pub hovered: Option<usize>,
}

#[derive(Default)]
pub struct InspectorUi {
    pub picker_open: bool,
    pub actions_open: bool,
    pub dialog: Option<BrushDialog>,
    pub name_edit: TextEdit,
    pub reorder: Option<Reorder>,
    pub wheel: Option<WheelState>,
    /// Last pointer position over the editor, for placing the wheel.
    pub pointer: Option<Point>,
}

/// Closes the brush dialog (and nothing else).
pub fn close_dialog(s: &mut State) {
    s.inspector_ui.dialog = None;
}

/// Closes the brush dropdown and management menu; true if one was open (for the editor's
/// Escape handling).
#[allow(dead_code)]
pub fn close_menus(s: &mut State) -> bool {
    let ui = &mut s.inspector_ui;
    let was_open = ui.picker_open || ui.actions_open;
    ui.picker_open = false;
    ui.actions_open = false;
    was_open
}

/// Dialogs and the brush wheel, full-size and absolutely positioned.
pub fn overlays(s: &State) -> El {
    let root = el().key("inspector-overlays").absolute(0.0, 0.0).w_full().h_full();
    let root = match &s.inspector_ui.dialog {
        Some(BrushDialog::Create { .. }) => root.child(name_dialog(s, true)),
        Some(BrushDialog::Rename { .. }) => root.child(name_dialog(s, false)),
        Some(BrushDialog::Delete { name, .. }) => root.child(delete_brush_dialog::delete_brush_dialog(name)),
        None => root,
    };
    root.child(brush_wheel::host::layer(s))
}

fn name_dialog(s: &State, creating: bool) -> El {
    let edit = &s.inspector_ui.name_edit;
    brush_name_dialog::brush_name_dialog(creating, edit.text.trim().is_empty(), edit)
}

/// The floating inspector for the selection, or for the active drawing tool when nothing is
/// selected.
pub fn panel(s: &State) -> El {
    let ctx = &s.ctx;
    let nodes: Vec<_> = ctx.selection.selected_node_ids().iter().filter_map(|&id| ctx.document.node(id)).collect();
    let features: Vec<&Feature> = nodes.iter().filter_map(|n| n.as_feature()).collect();
    let drawing_kind = if nodes.is_empty() { ctx.drawing_inspector_kind() } else { None };
    if nodes.is_empty() && drawing_kind.is_none() {
        return el();
    }

    let available = (ctx.viewport_size.height as f32 - 2.0 * kit_metrics::OVERLAY_TOP).max(0.0);
    let max_height = if available > 0.0 { available } else { 4000.0 };
    let mut sections = col().gap(kit_metrics::PANEL_SECTION_SPACING).padding(kit_metrics::PANEL_PADDING);
    if drawing_kind.is_some() {
        sections = sections.child(brush_picker::brush_picker(s, (max_height - 200.0).max(112.0)));
    }
    if !features.is_empty() {
        sections = sections.child(inspector_fields::inspector_fields(&features));
    }
    if text_auto_width_action::applies_to(&features) {
        sections = sections.child(text_auto_width_action::text_auto_width_action());
    }
    if let Some(kind) = &drawing_kind {
        let overridden: Vec<String> = ctx.document.session.active_brush().values.keys().cloned().collect();
        sections = sections.child(drawing_inspector_fields::drawing_inspector_fields(kind, &overridden));
    }
    if !nodes.is_empty() {
        sections = sections.child(layout_actions::layout_actions(nodes.len()));
    }

    floating_panel()
        .key("inspector")
        .pin(None, Some(kit_metrics::OVERLAY_TOP), Some(kit_metrics::OVERLAY_SIDE), None)
        .w(kit_metrics::MENU_WIDTH)
        .max_h(max_height)
        .clip_soft(0.0)
        .child(col().w_full().max_h(max_height).scroll(ScrollSpec { stick_bottom: false }).child(sections))
}
