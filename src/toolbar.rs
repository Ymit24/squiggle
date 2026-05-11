use gpui::*;

pub fn toolbar() -> impl IntoElement {
    div()
        .child("Test1")
        .bg(rgb(0x45475a))
        .text_color(rgb(0xcdd6f4))
        .absolute()
        .top_4()
        .left_1_2()
}