//! The tool abstraction (`tools/tool.dart`, `editor_interaction.dart`, `editor_cursor.dart`).

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::feature_kind::FeatureKind;
use crate::geom::Point;
use crate::paint::Painter;

/// Tool-layer cursor intent; mapped to a platform cursor in the viewport.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum EditorCursor {
    #[default]
    Basic,
    Grab,
    Grabbing,
    ResizeUpLeft,
    ResizeUp,
    ResizeUpRight,
    ResizeRight,
    ResizeDownRight,
    ResizeDown,
    ResizeDownLeft,
    ResizeLeft,
    Crosshair,
}

/// Modifier keys held during a pointer event.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Modifiers {
    pub shift: bool,
    pub alt: bool,
    /// Ctrl, or Cmd on macOS.
    pub command: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Key {
    Escape,
    Enter,
    Backspace,
    Delete,
    Tab,
    Left,
    Right,
    Up,
    Down,
    Char(char),
}

/// A key-down event delivered to the active tool.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct KeyInput {
    pub key: Key,
    pub mods: Modifiers,
}

/// Identifies a tool for toolbar highlighting and shortcuts.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ToolId {
    Select,
    Rectangle,
    Circle,
    Line,
    Text,
}

/// Active editor tool: pointer handling and ephemeral overlay painting. Handlers return `true`
/// when they consumed the event. Tools read and mutate the document via [`EditorContext`];
/// gesture mutations commit to the undo history only when the gesture completes.
///
/// While a handler runs the tool has been taken out of `ctx.tool`, so `ctx.set_tool(..)` from
/// inside a handler is queued and applied after the handler returns (see `ToolModel`).
pub trait Tool {
    fn id(&self) -> ToolId;

    fn on_pointer_down(&mut self, _ctx: &mut EditorContext, _world: Point, _camera: &Camera, _mods: Modifiers) -> bool {
        false
    }

    fn on_pointer_move(&mut self, _ctx: &mut EditorContext, _world: Point, _camera: &Camera, _mods: Modifiers) -> bool {
        false
    }

    fn on_pointer_up(&mut self, _ctx: &mut EditorContext, _world: Point, _camera: &Camera, _mods: Modifiers) -> bool {
        false
    }

    fn on_pointer_hover(&mut self, _ctx: &mut EditorContext, _world: Point, _camera: &Camera, _mods: Modifiers) -> bool {
        false
    }

    fn on_double_click(&mut self, _ctx: &mut EditorContext, _world: Point, _camera: &Camera) -> bool {
        false
    }

    fn on_key(&mut self, _ctx: &mut EditorContext, _key: KeyInput) -> bool {
        false
    }

    /// Called when this tool stops being the active tool.
    fn deactivate(&mut self, _ctx: &mut EditorContext) {}

    /// Cancels the current gesture without committing it.
    fn cancel_interaction(&mut self, _ctx: &mut EditorContext) {}

    /// Paints tool overlays in world space (appended to `painter`). Selection and vertex handles
    /// use `camera` for screen-constant sizing.
    fn paint(&self, _ctx: &EditorContext, _camera: &Camera, _painter: &mut Painter) {}

    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point, _camera: &Camera) -> EditorCursor {
        EditorCursor::Basic
    }

    /// `DrawingTool`: fresh style defaults for the drawing inspector, never a mutable template.
    fn create_drawing_kind(&self) -> Option<FeatureKind> {
        None
    }

    /// `BrushPreviewTool`: an unfinished drawing should follow the (changed) active brush.
    fn refresh_brush_preview(&mut self, _ctx: &mut EditorContext) {}
}
