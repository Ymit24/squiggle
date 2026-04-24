use gpui::*;
use gpui_component::{button::Button, Root, Sizable};
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
                .size(160.0, 80.0)
                .handles(vec![HandleDef::source(HandlePosition::Right)]),
            FlowNode::new("fetch", 300.0, 150.0)
                .label("Fetch Data")
                .node_type("action")
                .size(160.0, 80.0)
                .handles(vec![
                    HandleDef::target(HandlePosition::Left),
                    HandleDef::source(HandlePosition::Right),
                ]),
            FlowNode::new("validate", 550.0, 150.0)
                .label("Validate?")
                .node_type("condition")
                .size(160.0, 80.0)
                .handles(vec![
                    HandleDef::target(HandlePosition::Left),
                    HandleDef::source(HandlePosition::Right),
                ]),
            FlowNode::new("email", 800.0, 80.0)
                .label("Send Email")
                .node_type("action")
                .size(160.0, 80.0)
                .handles(vec![HandleDef::target(HandlePosition::Left)]),
            FlowNode::new("success", 800.0, 240.0)
                .label("Success")
                .node_type("output")
                .size(140.0, 60.0)
                .handles(vec![HandleDef::target(HandlePosition::Left)]),
        ];

        let edges = vec![
            FlowEdge::new("e1", "schedule", "fetch")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0x3b82f6)
                .stroke_width(2.0),
            FlowEdge::new("e2", "fetch", "validate")
                .edge_type(EdgeType::Bezier { curvature: 0.25 })
                .color(0x3b82f6)
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
                .bg_color(0x09090b)
                .grid_color(0x18181b)
                .bg_pattern(BackgroundPattern::Cross)
                .node_renderer("trigger", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .gap_1()
                        .p_2()
                        .rounded_md()
                        .border_1()
                        .border_color(gpui::rgb(0x7c3aed))
                        .bg(gpui::rgb(0x1e1b4b))
                        .child(
                            div()
                                .text_sm()
                                .font_weight(FontWeight::SEMIBOLD)
                                .text_color(gpui::rgb(0xc4b5fd))
                                .child(node.label.to_string()),
                        )
                        .child(
                            Button::new("run_trigger")
                                .small()
                                .label("Run")
                                .on_click(|_, _, _| println!("Trigger fired!")),
                        )
                        .into_any_element()
                })
                .node_renderer("action", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .gap_1()
                        .p_2()
                        .rounded_md()
                        .border_1()
                        .border_color(gpui::rgb(0x3b82f6))
                        .bg(gpui::rgb(0x172554))
                        .child(
                            div()
                                .text_sm()
                                .font_weight(FontWeight::SEMIBOLD)
                                .text_color(gpui::rgb(0x93c5fd))
                                .child(node.label.to_string()),
                        )
                        .child(
                            Button::new("run_action")
                                .small()
                                .label("Execute")
                                .on_click(|_, _, _| println!("Action running!")),
                        )
                        .into_any_element()
                })
                .node_renderer("condition", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .gap_1()
                        .p_2()
                        .rounded_md()
                        .border_1()
                        .border_color(gpui::rgb(0xeab308))
                        .bg(gpui::rgb(0x422006))
                        .child(
                            div()
                                .text_sm()
                                .font_weight(FontWeight::SEMIBOLD)
                                .text_color(gpui::rgb(0xfde047))
                                .child(node.label.to_string()),
                        )
                        .child(
                            Button::new("check_condition")
                                .small()
                                .label("Check")
                                .on_click(|_, _, _| println!("Condition checked!")),
                        )
                        .into_any_element()
                })
                .node_renderer("output", |node, _window, _cx| {
                    div()
                        .flex()
                        .flex_col()
                        .gap_1()
                        .p_2()
                        .rounded_md()
                        .border_1()
                        .border_color(gpui::rgb(0x22c55e))
                        .bg(gpui::rgb(0x052e16))
                        .child(
                            div()
                                .text_sm()
                                .font_weight(FontWeight::SEMIBOLD)
                                .text_color(gpui::rgb(0x86efac))
                                .child(node.label.to_string()),
                        )
                        .child(
                            Button::new("publish_output")
                                .small()
                                .label("Publish")
                                .on_click(|_, _, _| println!("Output published!")),
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
