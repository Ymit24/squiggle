use gpui::*;
use gpui_component::Root;

use crate::app::WorkflowApp;

mod app;
mod assets;
mod camera;
mod document;
mod feature;
mod feature_id;
mod fps_counter;
mod colors;
mod shape_canvas;
mod tool;
mod tool_store;
mod toolbar;
mod tools;

fn main() {
    gpui_platform::application()
        .with_assets(assets::Assets)
        .run(move |cx| {
            gpui_component::init(cx);
            cx.activate(true);

            let window_options = WindowOptions {
                window_bounds: Some(WindowBounds::centered(size(px(640.), px(480.)), cx)),
                ..Default::default()
            };

            cx.spawn(async move |cx| {
                cx.open_window(window_options, |window, cx| {
                    window.activate_window();
                    let view = cx.new(|cx| WorkflowApp::new(window, cx));
                    cx.new(|cx| Root::new(view, window, cx))
                })
                .expect("Failed to open window");
            })
            .detach();
        });
}
