use gpui::*;

use crate::tool::Tool;

pub struct ToolStore {
    pub tool: Tool,
}

impl ToolStore {
    pub fn new() -> Self {
        Self {
            tool: Tool::new_create_rect(),
        }
    }

    pub fn set_tool(&mut self, tool: Tool, cx: &mut Context<Self>) {
        self.tool = tool;
        cx.notify();
    }
}

actions!(tool_store, [ActivateSelectTool, ActivateCreateRectTool]);
