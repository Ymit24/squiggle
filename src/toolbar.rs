use gpui::*;
use gpui::prelude::FluentBuilder;

use crate::tool::Tool;
use crate::tool_store::{ActivateCreateRectTool, ActivateSelectTool, ToolStore};

pub struct Toolbar {
    tool_store: Entity<ToolStore>,
}

impl Toolbar {
    pub fn new(tool_store: Entity<ToolStore>) -> Self {
        Self { tool_store }
    }
}

impl Render for Toolbar {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let tool_store = self.tool_store.read(cx);
        let is_select = matches!(tool_store.tool, Tool::Selection(_));
        let is_create_rect = matches!(tool_store.tool, Tool::CreateRect(_));

        div()
            .flex()
            .gap_1()
            .px_2()
            .py_1()
            .child(
                div()
                    .px_3()
                    .py_1()
                    .child("Select")
                    .when(is_select, |this| this.bg(rgb(0x6c7086)))
                    .when(!is_select, |this| this.bg(rgb(0x45475a)))
                    .text_color(rgb(0xcdd6f4))
                    .cursor_pointer()
                    .on_mouse_down(MouseButton::Left, cx.listener(|_this, _, window, cx| {
                        window.dispatch_action(Box::new(ActivateSelectTool), cx);
                    })),
            )
            .child(
                div()
                    .px_3()
                    .py_1()
                    .child("Create Rect")
                    .when(is_create_rect, |this| this.bg(rgb(0x6c7086)))
                    .when(!is_create_rect, |this| this.bg(rgb(0x45475a)))
                    .text_color(rgb(0xcdd6f4))
                    .cursor_pointer()
                    .on_mouse_down(MouseButton::Left, cx.listener(|_this, _, window, cx| {
                        window.dispatch_action(Box::new(ActivateCreateRectTool), cx);
                    })),
            )
            .bg(rgb(0x313244))
            .rounded_md()
            .absolute()
            .top_4()
            .left_1_2()
    }
}
