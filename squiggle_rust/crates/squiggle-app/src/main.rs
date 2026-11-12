mod editor;
mod inspector;
mod kit;
mod library;
mod render;
mod state;
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
    rune::App::new(AppSpec::new("Squiggle", (1100.0, 760.0), || State::new(State::default_dir()), view))
        .on_modifiers(|s, mods, tx| {
            s.editor_ui.mods = squiggle_core::tools::tool::Modifiers { shift: mods.shift, alt: mods.alt, command: mods.cmd };
            tx.live_only();
        })
        .run();
}
