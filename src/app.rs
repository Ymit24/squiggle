use gpui::*;

use crate::colors;
use crate::document::Document;
use crate::editor::Editor;
use crate::feature::Feature;
use crate::fps_counter::FpsCounter;

pub struct WorkflowApp {
    editor: Entity<Editor>,
    fps_counter: Entity<FpsCounter>,
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
        let editor = cx.new(|cx| Editor::new(document, cx));
        editor.update(cx, |editor, cx| {
            editor.request_focus(window, cx);
        });

        Self {
            editor,
            fps_counter: cx.new(|_cx| FpsCounter::new()),
        }
    }
}

impl Render for WorkflowApp {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .relative()
            .size_full()
            .bg(colors::base())
            .child(self.editor.clone())
            .child(self.fps_counter.clone())
    }
}
