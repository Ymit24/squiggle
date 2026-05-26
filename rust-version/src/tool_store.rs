use gpui::*;

use crate::editor::SelectionState;
use crate::tool::Tool;

pub struct ToolStore {
    pub tool: Tool,
    selection_state: Entity<SelectionState>,
}

impl ToolStore {
    pub fn new(selection_state: Entity<SelectionState>) -> Self {
        Self {
            tool: Tool::new_selection(),
            selection_state,
        }
    }

    pub fn set_tool(&mut self, tool: Tool, cx: &mut Context<Self>) {
        self.selection_state.update(cx, |selection_state, _cx| {
            self.tool.deactivate(selection_state);
        });
        self.tool = tool;
        cx.notify();
    }
}
