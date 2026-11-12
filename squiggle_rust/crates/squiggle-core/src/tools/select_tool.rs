//! STUB: replaced by the full select tool port (see `tools/select_tool/`).
use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::tool::{Modifiers, Tool};

#[derive(Default)]
pub struct SelectTool;

impl Tool for SelectTool {
    fn on_pointer_down(&mut self, _ctx: &mut EditorContext, _w: Point, _c: &Camera, _m: Modifiers) -> bool {
        false
    }
}
