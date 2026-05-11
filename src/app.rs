use gpui::*;

use crate::feature::Feature;
use crate::shape_canvas::{ShapeCanvas, ShapeCanvasState};
use crate::toolbar::toolbar;

pub struct WorkflowApp {
    features: Vec<Entity<Feature>>,
    canvas_state: Entity<ShapeCanvasState>,
}

impl WorkflowApp {
    pub fn new(_window: &mut Window, cx: &mut Context<Self>) -> Self {
        let initial_features = vec![
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
        Self {
            features: initial_features
                .into_iter()
                .map(|feature| cx.new(|_cx| feature))
                .collect(),
            canvas_state: cx.new(|_cx| ShapeCanvasState {
                camera_x: 0.0,
                camera_y: 0.0,
                camera_zoom: 1.0,
            }),
        }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let features: Vec<Feature> = self
            .features
            .iter()
            .map(|entity| *entity.read(cx))
            .collect();

        div()
            .size_full()
            .bg(rgb(0x1e1e2e))
            .child(toolbar())
            .child(ShapeCanvas::new(self.canvas_state.clone(), features))
    }
}
