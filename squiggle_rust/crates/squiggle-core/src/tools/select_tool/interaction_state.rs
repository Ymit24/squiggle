//! The interaction state machine of the select tool (`interaction_state.dart` and
//! `select_tool/interaction_state.dart`).
//!
//! Dart's state objects hold a `parent` tool and call `parent.transition(..)`. Here a state
//! handler returns the [`Transition`] it wants and `SelectTool` applies it (running `on_enter`,
//! and replaying the event on the new state when `forward` is set).

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::editor::history::HistoryError;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::paint::Painter;
use crate::tools::tool::{EditorCursor, KeyInput, Modifiers};

/// A pointer event as seen by a state.
#[derive(Clone, Copy)]
pub struct Ptr {
    pub world: Point,
    pub mods: Modifiers,
}

impl Ptr {
    pub fn shift(&self) -> bool {
        self.mods.shift
    }

    pub fn alt(&self) -> bool {
        self.mods.alt
    }
}

/// The undo transaction a gesture may hold open until pointer-up (`SelectTool._hasTransaction`).
#[derive(Default)]
pub struct Txn {
    active: bool,
}

impl Txn {
    /// Opens a transaction scoped to the container shared by `ids` and watches them.
    pub fn begin(&mut self, ctx: &mut EditorContext, label: &str, ids: &[NodeId]) -> Result<(), HistoryError> {
        let container = shared_container(ctx, ids)?;
        ctx.history.begin(&ctx.document, label, container)?;
        self.active = true;
        ctx.history.edit(&mut ctx.document)?.watch(ids)
    }

    pub fn commit(&mut self, ctx: &mut EditorContext) {
        if std::mem::take(&mut self.active) {
            let _ = ctx.history.commit(&ctx.document);
        }
    }

    /// Rolls the open transaction back; returns whether there was one.
    pub fn cancel(&mut self, ctx: &mut EditorContext) -> bool {
        if !std::mem::take(&mut self.active) {
            return false;
        }
        let _ = ctx.history.cancel(&mut ctx.document);
        true
    }
}

fn shared_container(ctx: &EditorContext, ids: &[NodeId]) -> Result<Option<NodeId>, HistoryError> {
    let first = *ids.first().ok_or_else(|| HistoryError::Custom("No nodes selected".into()))?;
    let container = ctx.document.parent_of(first).ok_or(HistoryError::NotDirectChild(first))?;
    match ids.iter().find(|&&id| ctx.document.parent_of(id) != Some(container)) {
        Some(_) => Err(HistoryError::Custom("Selected nodes must share a container".into())),
        None => Ok(container),
    }
}

/// What a state handler can touch.
pub struct Cx<'a> {
    pub ctx: &'a mut EditorContext,
    pub txn: &'a mut Txn,
}

/// A requested state change.
pub struct Transition {
    pub to: Box<dyn InteractionState>,
    /// Replay the current pointer-move on the new state right after entering it.
    pub forward: bool,
}

impl Transition {
    pub fn to(state: impl InteractionState + 'static) -> Option<Transition> {
        Some(Transition { to: Box::new(state), forward: false })
    }

    pub fn forward(state: impl InteractionState + 'static) -> Option<Transition> {
        Some(Transition { to: Box::new(state), forward: true })
    }
}

/// Input and overlay hooks for the select tool's current interaction.
pub trait InteractionState {
    /// Runs when the state becomes active. Returning false aborts the transition back to idle.
    fn on_enter(&mut self, _cx: &mut Cx) -> bool {
        true
    }

    fn on_pointer_down(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        None
    }

    fn on_pointer_move(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        None
    }

    fn on_pointer_up(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        None
    }

    fn on_double_click(&mut self, _ctx: &mut EditorContext, _world: Point) {}

    /// Selection gestures cancel on Escape unless a state overrides key handling.
    fn cancels_on_escape(&self) -> bool {
        true
    }

    fn on_key(&mut self, _ctx: &mut EditorContext, _key: KeyInput) -> bool {
        false
    }

    fn paint(&self, _camera: &Camera, _painter: &mut Painter) {}

    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point) -> EditorCursor {
        EditorCursor::Basic
    }
}
