use gpui::*;

use crate::feature::Feature;

pub struct WorkflowApp {
    features: Vec<Entity<Feature>>,
}

impl WorkflowApp {
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let initial_features = vec![Feature::Rectangle { x: 20, y: 20, w: 10,h: 10 }];
        Self { features:  }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        // PLACEHOLDER FOR UI
        div().child("Hello world")
    }
}
