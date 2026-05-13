use gpui::*;
use gpui_component::Root;

use crate::app::WorkflowApp;

mod app;
mod camera;
mod document;
mod feature;
mod fps_counter;
mod shape_canvas;
mod toolbar;

fn main() {
    gpui_platform::application()
        .with_assets(gpui_component_assets::Assets)
        .run(move |cx| {
            gpui_component::init(cx);

            cx.spawn(async move |cx| {
                cx.open_window(WindowOptions::default(), |window, cx| {
                    let view = cx.new(|cx| WorkflowApp::new(window, cx));
                    cx.new(|cx| Root::new(view, window, cx))
                })
                .expect("Failed to open window");
            })
            .detach();
        });
}
