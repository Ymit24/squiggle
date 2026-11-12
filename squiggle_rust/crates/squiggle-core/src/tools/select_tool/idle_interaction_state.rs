//! Nothing is being dragged; decides what a press starts (`idle_interaction_state.dart`).

use super::click_canvas_state::ClickCanvasState;
use super::click_node_state::ClickNodeState;
use super::drag_polyline_handle_state::DragPolylineHandleState;
use super::helpers::{cursor_for_resize_handle, target_under_cursor};
use super::hit_target::HitTarget;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::resize_state::ResizeState;
use crate::editor::context::EditorContext;
use crate::editor::grouping_commands::{group_selected_nodes, ungroup_selected_nodes};
use crate::editor::text_edit::TextEditSession;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::tools::tool::{EditorCursor, Key, KeyInput};

#[derive(Default)]
pub struct IdleInteractionState;

impl InteractionState for IdleInteractionState {
    fn cancels_on_escape(&self) -> bool {
        false
    }

    fn resolve_cursor(&self, ctx: &EditorContext, world: Point) -> EditorCursor {
        match target_under_cursor(ctx, world) {
            HitTarget::ResizeHandle(h) => cursor_for_resize_handle(h.handle),
            HitTarget::PolylineHandle(_) | HitTarget::Node(_) => EditorCursor::Grab,
            HitTarget::Canvas => EditorCursor::Basic,
        }
    }

    fn on_pointer_down(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        let ctx = &mut *cx.ctx;
        match target_under_cursor(ctx, ev.world) {
            HitTarget::ResizeHandle(handle) => Transition::to(ResizeState::new(handle, ev.world, &ctx.document)?),
            HitTarget::PolylineHandle(handle) => Transition::to(DragPolylineHandleState::new(handle)),
            HitTarget::Node(chase) => {
                let selected: Vec<NodeId> = ctx
                    .selection
                    .selected_node_ids()
                    .iter()
                    .copied()
                    .filter(|id| ctx.document.node(*id).is_some())
                    .collect();
                Transition::to(ClickNodeState::new(ev.world, chase, selected, ev.shift()))
            }
            HitTarget::Canvas => Transition::to(ClickCanvasState::new(ev.world)),
        }
    }

    fn on_double_click(&mut self, ctx: &mut EditorContext, world: Point) {
        match target_under_cursor(ctx, world) {
            HitTarget::Node(id) => edit_label(ctx, id),
            HitTarget::Canvas => ctx.start_create_text(world, None),
            _ => {}
        }
    }

    fn on_key(&mut self, ctx: &mut EditorContext, key: KeyInput) -> bool {
        if ctx.selection.is_empty() {
            return false;
        }
        match key.key {
            Key::Delete | Key::Backspace => {
                delete_selected(ctx);
                true
            }
            Key::Char(c) if c.eq_ignore_ascii_case(&'g') && key.mods.command => {
                // Like Dart, a failing command leaves the document unchanged.
                if key.mods.shift {
                    let _ = ungroup_selected_nodes(&mut ctx.document, &mut ctx.history, &mut ctx.selection);
                } else {
                    let _ = group_selected_nodes(&mut ctx.document, &mut ctx.history, &mut ctx.selection);
                }
                true
            }
            _ => false,
        }
    }
}

/// Starts editing the label of a label-capable feature and selects it.
fn edit_label(ctx: &mut EditorContext, id: NodeId) {
    let Some(feature) = ctx.document.feature(id) else { return };
    let (Some(contents), Some(layout)) = (feature.kind.label().map(str::to_owned), feature.label_layout()) else {
        return;
    };
    let container = ctx.document.parent_of(id).flatten();
    let layout = layout.shifted(ctx.document.global_origin(container));
    ctx.selection.set_selection([id]);
    ctx.start_text_edit(TextEditSession::edit(id, contents, layout.bounds));
}

/// Deletes the selection as one undo entry. On failure the selection is restored (minus nodes
/// that are gone) and the document is left as it was.
fn delete_selected(ctx: &mut EditorContext) {
    let ids = ctx.selection.selected_node_ids().to_vec();
    let Some(container) = ids.first().and_then(|id| ctx.document.parent_of(*id)) else { return };
    ctx.selection.clear_selection();
    let result = ctx.history.run(&mut ctx.document, "Delete Selected Nodes", container, |tx| {
        tx.remove_all(&ids).map(|_| ())
    });
    if result.is_err() {
        let alive: Vec<NodeId> = ids.into_iter().filter(|id| ctx.document.node(*id).is_some()).collect();
        ctx.selection.set_selection(alive);
    }
}
