mod dialog;
mod editor;
mod inspector;
mod kit;
mod library;
mod menu;
mod render;
mod state;
mod text_field;
mod theme;
mod viewport;

use rune::{AppSpec, Cx, El, col};
use state::{Page, State};

fn view(s: &State, cx: &mut Cx<State>) -> El {
    match s.page {
        Page::Library => library::view(s, cx),
        Page::Editor => col().w_full().h_full().fill(theme::base()).child(editor::view(s, cx)),
    }
}

fn main() {
    rune::run(AppSpec::new("Squiggle", (1100.0, 760.0), || State::new(State::default_dir()), view));
}
