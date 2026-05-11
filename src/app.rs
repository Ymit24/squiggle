use gpui::*;

use crate::feature::Feature;

pub struct WorkflowApp {
    features: Vec<Entity<Feature>>,
}

impl WorkflowApp {
    pub fn new(_window: &mut Window, cx: &mut Context<Self>) -> Self {
        let initial_features = vec![Feature::Rectangle {
            x: 20.,
            y: 20.,
            w: 10.,
            h: 10.,
        }];
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
        // PLACEHOLDER FOR UI
        div()
            .child("Hello world")
            .children(
                self.features
                    .clone()
                    .iter()
                    .map(|feature| match feature.read(cx) {
                        Feature::Rectangle { x, y, w, h } => {
                            div().child(format!("RECTANGLE: {} {} {} {}", x, y, w, h))
                        }
                        Feature::Circle { x, y, r } => {
                            div().child(format!("CIRCLE {} {} {}", x, y, r))
                        }
                    }),
            )
    }
}
