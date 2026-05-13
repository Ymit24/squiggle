use gpui::*;

#[derive(
    Clone, PartialEq, Debug, serde::Deserialize, serde::Serialize, schemars::JsonSchema, Action,
)]
pub struct CreateDemoRect {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

pub fn toolbar() -> impl IntoElement {
    div()
        .child("Test1")
        .on_mouse_down(MouseButton::Left, |_, window, cx| {
            println!("Click on the toolbar");
            window.dispatch_action(
                Box::new(CreateDemoRect {
                    x: rand::random::<f32>() * 1000.,
                    y: rand::random::<f32>() * 1000.,
                    width: 40.,
                    height: 40.,
                }),
                cx,
            );
        })
        .bg(rgb(0x45475a))
        .text_color(rgb(0xcdd6f4))
        .absolute()
        .top_4()
        .left_1_2()
}
