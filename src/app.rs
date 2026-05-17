use gpui::*;

use crate::document::{Command, Document};
use crate::feature::Feature;
use crate::feature_id::FeatureId;
use crate::fps_counter::FpsCounter;
use crate::shape_canvas::ShapeCanvas;
use crate::toolbar::{CreateDemoRect, toolbar};

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
    document: Entity<Document>,
    selection_state: Entity<SelectionState>,
    shape_canvas: Entity<ShapeCanvas>,
    focus_handle: FocusHandle,
    fps_counter: Entity<FpsCounter>,
}

actions!(workflow, [CreateDemoCircle]);

impl WorkflowApp {
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let mut initial_features = vec![
            Feature::new_rectangle(px(20.), px(20.), px(100.), px(60.)),
            Feature::new_circle(px(150.), px(20.), px(30.)),
        ];

        let size = 1000.;
        for _ in 0..50 {
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

        cx.bind_keys([KeyBinding::new("r", CreateDemoCircle, None)]);

        let focus_handle = cx.focus_handle();
        focus_handle.focus(window, cx);

        let shape_canvas = cx.new(|_cx| ShapeCanvas::new(document.clone(), selection_state.clone()));

        Self {
            document,
            selection_state,
            shape_canvas,
            focus_handle,
            fps_counter: cx.new(|_cx| FpsCounter::new()),
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
            .child(self.shape_canvas.clone())
            .on_action(cx.listener(|this, event: &CreateDemoRect, _, cx| {
                println!("Action! {:?}", event.x);
                this.document
                    .update(cx, |doc: &mut Document, cx: &mut Context<Document>| {
                        doc.execute_command(Command::AddFeature(Feature::new_rectangle(
                            px(event.x),
                            px(event.y),
                            px(event.width),
                            px(event.height),
                        )));
                        cx.notify();
                    });
            }))
            .child(toolbar())
            .child(self.fps_counter.clone())
    }
}