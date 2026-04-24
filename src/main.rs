use gpui::*;
use gpui_component::{button::{Button, ButtonVariants}, tag::Tag, Root, Sizable};
use gpui_flow::*;

pub struct WorkflowApp {
    flow_graph: Entity<FlowGraph>,
    minimap: Entity<Minimap>,
    controls: Entity<Controls>,
}

impl WorkflowApp {
    pub fn new(cx: &mut App) -> Self {
        let nodes = vec![
            FlowNode::new("schedule", 50.0, 150.0)
                .label("On Schedule")
                .node_type("trigger")
                .size(200.0, 110.0)
                .handles(vec![HandleDef::source(HandlePosition::Right)]),
            FlowNode::new("fetch", 320.0, 150.0)
                .label("Fetch Data")
                .node_type("action")
                .size(200.0, 110.0)
                .handles(vec![
                    HandleDef::target(HandlePosition::Left),
                    HandleDef::source(HandlePosition::Right),
                ]),
            FlowNode::new("validate", 590.0, 150.0)
                .label("Validate?")
                .node_type("condition")
                .size(200.0, 110.0)
                .handles(vec![
                    HandleDef::target(HandlePosition::Left),
                    HandleDef::source(HandlePosition::Right),
                ]),
            FlowNode::new("email", 860.0, 70.0)
                .label("Send Email")
                .node_type("action")
                .size(200.0, 110.0)
                .handles(vec![HandleDef::target(HandlePosition::Left)]),
            FlowNode::new("success", 860.0, 260.0)
                .label("Success")
                .node_type("output")
                .size(180.0, 90.0)
                .handles(vec![HandleDef::target(HandlePosition::Left)]),
        ];

        let edges = vec![
            FlowEdge::new("e1", "schedule", "fetch")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0x6366f1)
                .stroke_width(2.0),
            FlowEdge::new("e2", "fetch", "validate")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0x6366f1)
                .stroke_width(2.0),
            FlowEdge::new("e3", "validate", "email")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0x22c55e)
                .stroke_width(2.0)
                .label("yes"),
            FlowEdge::new("e4", "validate", "success")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0xef4444)
                .stroke_width(2.0)
                .label("no"),
        ];

        let state = cx.new(|_| FlowState::new(nodes, edges));

        let flow_graph = cx.new(|cx| {
            FlowGraph::new(state.clone(), cx)
                .bg_color(0x0a0a0f)
                .grid_color(0x1a1a23)
                .bg_pattern(BackgroundPattern::Cross)
                .node_bg_color(0x111118)
                .node_border_color(0x27273a)
                .node_renderer("trigger", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .rounded_lg()
                        .shadow_md()
                        .overflow_hidden()
                        .border_1()
                        .border_color(gpui::rgb(0x27273a))
                        .child(
                            div()
                                .h(px(3.0))
                                .w_full()
                                .bg(gpui::rgb(0x8b5cf6)),
                        )
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .gap_2()
                                .p_3()
                                .bg(gpui::rgb(0x111118))
                                .child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .justify_between()
                                        .child(
                                            div()
                                                .text_base()
                                                .font_weight(FontWeight::SEMIBOLD)
                                                .text_color(gpui::rgb(0xeae6ff))
                                                .child(node.label.to_string()),
                                        )
                                        .child(
                                            Tag::new()
                                                .small()
                                                .outline()
                                                .child("Trigger"),
                                        ),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(gpui::rgb(0x6b6680))
                                        .child("Fires at 9:00 AM daily"),
                                )
                                .child(
                                    div()
                                        .mt_1()
                                        .child(
                                            Button::new("run_trigger")
                                                .xsmall()
                                                .ghost()
                                                .label("Run Now")
                                                .on_click(|_, _, _| println!("Trigger fired!")),
                                        ),
                                ),
                        )
                        .into_any_element()
                })
                .node_renderer("action", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .rounded_lg()
                        .shadow_md()
                        .overflow_hidden()
                        .border_1()
                        .border_color(gpui::rgb(0x27273a))
                        .child(
                            div()
                                .h(px(3.0))
                                .w_full()
                                .bg(gpui::rgb(0x3b82f6)),
                        )
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .gap_2()
                                .p_3()
                                .bg(gpui::rgb(0x111118))
                                .child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .justify_between()
                                        .child(
                                            div()
                                                .text_base()
                                                .font_weight(FontWeight::SEMIBOLD)
                                                .text_color(gpui::rgb(0xdbeafe))
                                                .child(node.label.to_string()),
                                        )
                                        .child(
                                            Tag::new()
                                                .small()
                                                .outline()
                                                .child("Action"),
                                        ),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(gpui::rgb(0x6b7a90))
                                        .child("Execute API request"),
                                )
                                .child(
                                    div()
                                        .mt_1()
                                        .child(
                                            Button::new("run_action")
                                                .xsmall()
                                                .ghost()
                                                .label("Execute")
                                                .on_click(|_, _, _| println!("Action running!")),
                                        ),
                                ),
                        )
                        .into_any_element()
                })
                .node_renderer("condition", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .rounded_lg()
                        .shadow_md()
                        .overflow_hidden()
                        .border_1()
                        .border_color(gpui::rgb(0x27273a))
                        .child(
                            div()
                                .h(px(3.0))
                                .w_full()
                                .bg(gpui::rgb(0xf59e0b)),
                        )
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .gap_2()
                                .p_3()
                                .bg(gpui::rgb(0x111118))
                                .child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .justify_between()
                                        .child(
                                            div()
                                                .text_base()
                                                .font_weight(FontWeight::SEMIBOLD)
                                                .text_color(gpui::rgb(0xfef3c7))
                                                .child(node.label.to_string()),
                                        )
                                        .child(
                                            Tag::new()
                                                .small()
                                                .outline()
                                                .child("Condition"),
                                        ),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(gpui::rgb(0x8b7d6b))
                                        .child("Check response validity"),
                                )
                                .child(
                                    div()
                                        .mt_1()
                                        .child(
                                            Button::new("check_condition")
                                                .xsmall()
                                                .ghost()
                                                .label("Evaluate")
                                                .on_click(|_, _, _| println!("Condition checked!")),
                                        ),
                                ),
                        )
                        .into_any_element()
                })
                .node_renderer("output", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .rounded_lg()
                        .shadow_md()
                        .overflow_hidden()
                        .border_1()
                        .border_color(gpui::rgb(0x27273a))
                        .child(
                            div()
                                .h(px(3.0))
                                .w_full()
                                .bg(gpui::rgb(0x22c55e)),
                        )
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .gap_2()
                                .p_3()
                                .bg(gpui::rgb(0x111118))
                                .child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .justify_between()
                                        .child(
                                            div()
                                                .text_base()
                                                .font_weight(FontWeight::SEMIBOLD)
                                                .text_color(gpui::rgb(0xdcfce7))
                                                .child(node.label.to_string()),
                                        )
                                        .child(
                                            Tag::new()
                                                .small()
                                                .outline()
                                                .child("Output"),
                                        ),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(gpui::rgb(0x6b8f6b))
                                        .child("Final result endpoint"),
                                )
                                .child(
                                    div()
                                        .mt_1()
                                        .child(
                                            Button::new("publish_output")
                                                .xsmall()
                                                .ghost()
                                                .label("Publish")
                                                .on_click(|_, _, _| println!("Output published!")),
                                        ),
                                ),
                        )
                        .into_any_element()
                })
        });

        let minimap = cx.new(|_| Minimap::new(state.clone()).container_bounds(1024.0, 768.0));
        let controls = cx.new(|_| Controls::new(state.clone()).container_size(1024.0, 768.0));

        WorkflowApp {
            flow_graph,
            minimap,
            controls,
        }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .child(self.flow_graph.clone())
            .child(
                div()
                    .absolute()
                    .bottom_4()
                    .left_4()
                    .child(self.minimap.clone()),
            )
            .child(
                div()
                    .absolute()
                    .bottom_4()
                    .right_4()
                    .child(self.controls.clone()),
            )
    }
}

fn main() {
    gpui_platform::application().run(move |cx| {
        gpui_component::init(cx);

        cx.spawn(async move |cx| {
            cx.open_window(WindowOptions::default(), |window, cx| {
                let view = cx.new(|cx| WorkflowApp::new(cx));
                cx.new(|cx| Root::new(view, window, cx))
            })
            .expect("Failed to open window");
        })
        .detach();
    });
}
