use gpui::*;

use crate::document::{Command, Document};
use crate::feature::Feature;
use crate::fps_counter::FpsCounter;
use crate::shape_canvas::{ShapeCanvas, ShapeCanvasState};
use crate::toolbar::{CreateDemoRect, toolbar};

pub struct WorkflowApp {
    document: Entity<Document>,
    canvas_state: Entity<ShapeCanvasState>,
    focus_handle: FocusHandle,
    fps_counter: Entity<FpsCounter>,
}

actions!(workflow, [CreateDemoCircle]);

impl WorkflowApp {
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let mut initial_features = vec![
            Feature::Rectangle {
                x: 20.,
                y: 20.,
                w: 100.,
                h: 60.,
            },
            Feature::Circle {
                x: 150.,
                y: 20.,
                r: 30.,
            },
        ];
        // initial features should have 1000 random things
        let size = 1000.;
        for _ in 0..50 {
            if rand::random::<bool>() {
                initial_features.push(Feature::Circle {
                    x: rand::random::<f32>() * size,
                    y: rand::random::<f32>() * size,
                    r: 30.,
                });
            } else {
                initial_features.push(Feature::Rectangle {
                    x: rand::random::<f32>() * size,
                    y: rand::random::<f32>() * size,
                    w: 40.,
                    h: 40.,
                });
            }
        }

        let document = cx.new(|_cx| Document::new(initial_features));

        cx.bind_keys([KeyBinding::new("r", CreateDemoCircle, None)]);

        let focus_handle = cx.focus_handle();
        focus_handle.focus(window, cx);

        Self {
            document,
            canvas_state: cx.new(|_cx| ShapeCanvasState::new()),
            focus_handle,
            fps_counter: cx.new(|_cx| FpsCounter::new()),
        }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let document = self.document.read(cx);

        div()
            .relative()
            .size_full()
            .bg(rgb(0x1e1e2e))
            .track_focus(&self.focus_handle)
            .child(ShapeCanvas::new(
                self.canvas_state.clone(),
                document.features.clone(),
            ))
            .on_action(cx.listener(|this, event: &CreateDemoRect, _, cx| {
                println!("Action! {:?}", event.x);
                this.document.update(cx, |doc, cx| {
                    doc.execute_command(Command::AddFeature(Feature::Rectangle {
                        x: event.x,
                        y: event.y,
                        w: event.width,
                        h: event.height,
                    }));
                    cx.notify();
                });
            }))
            .child(toolbar())
            .child(self.fps_counter.clone())
    }
}
