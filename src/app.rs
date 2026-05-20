use gpui::*;

use crate::document::Document;
use crate::feature::Feature;
use crate::feature_id::FeatureId;
use crate::fps_counter::FpsCounter;
use crate::shape_canvas::ShapeCanvas;
use crate::toolbar::Toolbar;
use crate::tool_store::{ActivateCreateRectTool, ActivateSelectTool, ToolStore};

pub struct SelectionState {
    pub selected_features: Vec<FeatureId>,
}

impl SelectionState {
    pub fn new() -> Self {
        Self {
            selected_features: Vec::new(),
        }
    }
}

pub struct WorkflowApp {
    shape_canvas: Entity<ShapeCanvas>,
    toolbar: Entity<Toolbar>,
    focus_handle: FocusHandle,
    fps_counter: Entity<FpsCounter>,
    tool_store: Entity<ToolStore>,
}

impl WorkflowApp {
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let mut initial_features = vec![
            Feature::new_rectangle(px(20.), px(20.), px(100.), px(60.)),
            Feature::new_circle(px(150.), px(20.), px(30.)),
        ];

        let size = 1000.;
        for _ in 0..100 {
            if rand::random::<bool>() {
                initial_features.push(Feature::new_circle(
                    px(rand::random::<f32>() * size),
                    px(rand::random::<f32>() * size),
                    px(30.),
                ));
            } else {
                initial_features.push(Feature::new_rectangle(
                    px(rand::random::<f32>() * size),
                    px(rand::random::<f32>() * size),
                    px(40.),
                    px(40.),
                ));
            }
        }

        let document = cx.new(|_cx| Document::new(initial_features));
        let selection_state = cx.new(|_cx| SelectionState::new());
        let tool_store = cx.new(|_cx| ToolStore::new());

        cx.bind_keys([
            KeyBinding::new("v", ActivateSelectTool, None),
            KeyBinding::new("r", ActivateCreateRectTool, None),
        ]);

        let focus_handle = cx.focus_handle();
        focus_handle.focus(window, cx);

        let shape_canvas =
            cx.new(|_cx| ShapeCanvas::new(document.clone(), selection_state.clone(), tool_store.clone()));
        let toolbar = cx.new(|_cx| Toolbar::new(tool_store.clone()));

        Self {
            shape_canvas,
            toolbar,
            focus_handle,
            fps_counter: cx.new(|_cx| FpsCounter::new()),
            tool_store,
        }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .relative()
            .size_full()
            .bg(rgb(0x1e1e2e))
            .track_focus(&self.focus_handle)
            .on_action(cx.listener(|this, _: &ActivateSelectTool, _, cx| {
                this.tool_store.update(cx, |tool_store, cx| {
                    tool_store.set_tool(crate::tool::Tool::new_selection(), cx);
                });
            }))
            .on_action(cx.listener(|this, _: &ActivateCreateRectTool, _, cx| {
                this.tool_store.update(cx, |tool_store, cx| {
                    tool_store.set_tool(crate::tool::Tool::new_create_rect(), cx);
                });
            }))
            .child(self.shape_canvas.clone())
            .child(self.toolbar.clone())
            .child(self.fps_counter.clone())
    }
}
