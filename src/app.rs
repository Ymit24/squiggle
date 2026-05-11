use gpui::*;

use crate::feature::Feature;
use crate::shape_canvas::shape_canvas;
use crate::toolbar::toolbar;

pub struct WorkflowApp {
    features: Vec<Entity<Feature>>,
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
            .child(shape_canvas(features))
    }
}
