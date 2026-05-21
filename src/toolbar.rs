use gpui::prelude::FluentBuilder;
use gpui::*;
use gpui_component::{Icon, Sizable};

use crate::tool::Tool;
use crate::tool_store::ToolStore;

actions!(toolbar, [ActivateSelectTool, ActivateCreateRectTool]);

pub fn bind_tool_keys<T: 'static>(cx: &mut Context<T>) {
    cx.bind_keys([
        KeyBinding::new("v", ActivateSelectTool, None),
        KeyBinding::new("r", ActivateCreateRectTool, None),
    ]);
}

pub struct Toolbar {
    tool_store: Entity<ToolStore>,
}

impl Toolbar {
    pub fn new(tool_store: Entity<ToolStore>) -> Self {
        Self { tool_store }
    }
}

fn tool_button<A: Action + Clone + 'static>(
    icon_path: &'static str,
    active: bool,
    action: A,
    cx: &mut Context<Toolbar>,
) -> impl IntoElement {
    let icon = Icon::empty()
        .path(icon_path)
        .with_size(px(20.))
        .text_color(if active {
            rgb(0xcdd6f4)
        } else {
            rgb(0xa6adc8)
        });

    div()
        .flex()
        .items_center()
        .justify_center()
        .size(px(36.))
        .rounded_md()
        .cursor_pointer()
        .child(icon)
        .when(active, |this| this.bg(rgb(0x45475a)))
        .when(!active, |this| {
            this.hover(|style| style.bg(rgb(0x313244)))
        })
        .on_mouse_down(
            MouseButton::Left,
            cx.listener(move |_this, _, window, cx| {
                window.dispatch_action(Box::new(action.clone()), cx);
            }),
        )
}

impl Render for Toolbar {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let tool_store = self.tool_store.read(cx);
        let is_select = matches!(tool_store.tool, Tool::Selection(_));
        let is_create_rect = matches!(tool_store.tool, Tool::CreateRect(_));

        div()
            .absolute()
            .top(px(20.))
            .left_0()
            .right_0()
            .flex()
            .justify_center()
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(2.))
                    .p_1()
                    .bg(rgb(0x181825))
                    .border_1()
                    .border_color(rgb(0x45475a))
                    .rounded_xl()
                    .child(tool_button(
                        "icons/arrow_selector_tool.svg",
                        is_select,
                        ActivateSelectTool,
                        cx,
                    ))
                    .child(
                        div()
                            .w(px(1.))
                            .h(px(20.))
                            .mx(px(2.))
                            .bg(rgb(0x45475a)),
                    )
                    .child(tool_button(
                        "icons/crop_square.svg",
                        is_create_rect,
                        ActivateCreateRectTool,
                        cx,
                    )),
            )
    }
}
