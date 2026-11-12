use rune::tok;
use rune::{AppSpec, Cx, El, col, text};

struct State;

fn view(_: &State, _: &mut Cx<State>) -> El {
    let t = tok::theme(true);
    col().w_full().h_full().center().fill(t.bg).child(text("Squiggle").color(t.text))
}

fn main() {
    rune::run(AppSpec::new("Squiggle", (800.0, 600.0), || State, view));
}
