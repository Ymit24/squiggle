//! Holds the active tool and routes input to it (`tool_model.dart`).

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::select_tool::SelectTool;
use crate::tools::tool::{EditorCursor, KeyInput, Modifiers, Tool};

pub struct ToolModel {
    /// `None` only while a handler of the active tool is running (the tool is taken out).
    active: Option<Box<dyn Tool>>,
    /// A tool requested during a handler; installed when the handler returns.
    pending: Option<Box<dyn Tool>>,
    locked: bool,
    revision: u64,
}

impl Default for ToolModel {
    fn default() -> Self {
        ToolModel::new(Box::new(SelectTool::default()))
    }
}

impl ToolModel {
    pub fn new(initial: Box<dyn Tool>) -> Self {
        ToolModel { active: Some(initial), pending: None, locked: false, revision: 0 }
    }

    pub fn revision(&self) -> u64 {
        self.revision
    }

    /// The active tool; `None` only inside a tool handler.
    pub fn active(&self) -> Option<&dyn Tool> {
        self.active.as_deref()
    }

    pub fn is_locked(&self) -> bool {
        self.locked
    }

    pub fn toggle_lock(&mut self) {
        self.locked = !self.locked;
        self.revision += 1;
    }

    /// Runs `f` with the active tool taken out of the context, then restores it (or installs a
    /// tool that was requested meanwhile, deactivating the old one first).
    pub fn with_active<R>(ctx: &mut EditorContext, f: impl FnOnce(&mut dyn Tool, &mut EditorContext) -> R) -> Option<R> {
        let mut tool = ctx.tool.active.take()?;
        let result = f(tool.as_mut(), ctx);
        match ctx.tool.pending.take() {
            Some(next) => {
                tool.deactivate(ctx);
                ctx.tool.active = Some(next);
            }
            None => ctx.tool.active = Some(tool),
        }
        ctx.tool.revision += 1;
        Some(result)
    }

    /// Switches tool. Inside a handler the switch is deferred until the handler returns.
    pub fn set_tool(ctx: &mut EditorContext, tool: Box<dyn Tool>) {
        if ctx.tool.active.is_none() {
            ctx.tool.pending = Some(tool);
            return;
        }
        if let Some(mut old) = ctx.tool.active.take() {
            old.deactivate(ctx);
        }
        ctx.tool.active = Some(tool);
        ctx.tool.revision += 1;
    }

    /// Returns to selection after creation unless automatic switching is locked.
    pub fn reset_to_select_tool(ctx: &mut EditorContext) {
        if !ctx.tool.locked {
            Self::set_tool(ctx, Box::new(SelectTool::default()));
        }
    }

    pub fn on_pointer_down(ctx: &mut EditorContext, world: Point, camera: &Camera, mods: Modifiers) -> bool {
        Self::with_active(ctx, |t, c| t.on_pointer_down(c, world, camera, mods)).unwrap_or(false)
    }

    pub fn on_pointer_move(ctx: &mut EditorContext, world: Point, camera: &Camera, mods: Modifiers) -> bool {
        Self::with_active(ctx, |t, c| t.on_pointer_move(c, world, camera, mods)).unwrap_or(false)
    }

    pub fn on_pointer_up(ctx: &mut EditorContext, world: Point, camera: &Camera, mods: Modifiers) -> bool {
        Self::with_active(ctx, |t, c| t.on_pointer_up(c, world, camera, mods)).unwrap_or(false)
    }

    pub fn on_pointer_hover(ctx: &mut EditorContext, world: Point, camera: &Camera, mods: Modifiers) -> bool {
        Self::with_active(ctx, |t, c| t.on_pointer_hover(c, world, camera, mods)).unwrap_or(false)
    }

    pub fn on_double_click(ctx: &mut EditorContext, world: Point, camera: &Camera) -> bool {
        Self::with_active(ctx, |t, c| t.on_double_click(c, world, camera)).unwrap_or(false)
    }

    pub fn on_key(ctx: &mut EditorContext, key: KeyInput) -> bool {
        Self::with_active(ctx, |t, c| t.on_key(c, key)).unwrap_or(false)
    }

    pub fn cancel_interaction(ctx: &mut EditorContext) {
        Self::with_active(ctx, |t, c| t.cancel_interaction(c));
    }

    pub fn resolve_cursor(ctx: &EditorContext, world: Point, camera: &Camera) -> EditorCursor {
        ctx.tool.active().map(|t| t.resolve_cursor(ctx, world, camera)).unwrap_or_default()
    }
}
