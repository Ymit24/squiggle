mod dialog;
mod editor;
mod images;
mod inspector;
mod kit;
mod library;
mod measure;
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

/// Window-level keys: each page handles its own shortcuts.
fn on_key(s: &mut State, e: &rune::KeyEvent, tx: &mut rune::Tx) -> bool {
    editor::on_key(s, e, tx) || library::on_key(s, e, tx)
}

/// `--scene editor`: the editor with a few shapes, one selected (for headless snapshots).
fn editor_scene(s: &mut State) {
    use squiggle_core::feature::Feature;
    use squiggle_core::feature_kind::FeatureKind;
    use squiggle_core::feature_kinds::{CircleKind, PolylineKind, RectangleKind};
    use squiggle_core::geom::{Point, Size};
    s.page = Page::Editor;
    s.ctx.viewport_size = Size::new(1100.0, 760.0);
    s.ctx.camera.location = Point::new(-60.0, -120.0);
    let mut rect = RectangleKind::default();
    rect.style.stroke_color = squiggle_core::Color(0xFF8AB4F8);
    let mut rect = Feature::new(Point::new(120.0, 220.0), Size::new(280.0, 160.0), FeatureKind::Rectangle(rect));
    rect.set_label("Rectangle");
    let circle = Feature::new(Point::new(520.0, 200.0), Size::new(200.0, 200.0), FeatureKind::Circle(CircleKind::default()));
    let line = Feature::new(
        Point::new(200.0, 480.0),
        Size::new(500.0, 120.0),
        FeatureKind::Polyline(PolylineKind::new(vec![Point::new(0.0, 100.0), Point::new(150.0, 0.0), Point::new(300.0, 90.0), Point::new(480.0, 10.0)])),
    );
    let text = s.ctx.new_text_feature(Point::new(420.0, 120.0), "Hello Squiggle", None);
    let mut first = None;
    for f in [rect, circle, line, text] {
        let id = s.ctx.document.insert(None, f.into(), None).unwrap();
        first.get_or_insert(id);
    }
    s.ctx.selection.set_selection(first);
}

fn main() {
    let spec = AppSpec {
        on_key: Some(on_key),
        scenes: &[("editor", editor_scene)],
        poll: Some(editor::poll),
        setup: Some(|s, waker| s.images_store = images::ImageStore::new(waker)),
        ..AppSpec::new("Squiggle", (1100.0, 760.0), || State { page: Page::Library, ..State::new(State::default_dir()) }, view)
    };
    rune::App::new(spec)
        .on_modifiers(|s, mods, tx| {
            s.editor_ui.mods = squiggle_core::tools::tool::Modifiers { shift: mods.shift, alt: mods.alt, command: mods.cmd };
            tx.live_only();
        })
        .run();
}

#[cfg(test)]
mod tests {
    use super::*;
    use rune::{Env, Runtime};

    fn temp_dir(name: &str) -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!("squiggle_app_{name}_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        dir
    }

    fn app(name: &str) -> Runtime<State> {
        let mut rt = Runtime::new(State::new(temp_dir(name)), view, (1100.0, 760.0), Env::new(true, 1.0));
        rt.on_key = Some(on_key);
        rt.frame(0.0);
        rt
    }

    fn click(rt: &mut Runtime<State>, key: &str) {
        let (x, y) = rt.find(key).unwrap_or_else(|| panic!("no element {key}"));
        rt.pointer_move(x, y);
        rt.pointer_down(x, y);
        rt.pointer_up(x, y);
        rt.frame(0.0);
    }

    fn drag(rt: &mut Runtime<State>, from: (f32, f32), to: (f32, f32)) {
        rt.pointer_move(from.0, from.1);
        rt.pointer_down(from.0, from.1);
        rt.pointer_move((from.0 + to.0) / 2.0, (from.1 + to.1) / 2.0);
        rt.pointer_move(to.0, to.1);
        rt.pointer_up(to.0, to.1);
        rt.frame(0.0);
    }

    #[test]
    fn toolbar_rectangle_tool_draws_a_rectangle() {
        let mut rt = app("rect");
        click(&mut rt, "tool-rect");
        drag(&mut rt, (300.0, 300.0), (420.0, 380.0));
        assert_eq!(rt.state.ctx.document.nodes().len(), 1);
        let bounds = rt.state.ctx.document.nodes()[0].local_bounds();
        assert!(bounds.width() > 50.0 && bounds.height() > 30.0, "{bounds:?}");
        assert!(rt.state.ctx.history.can_undo());
    }

    #[test]
    fn keyboard_shortcuts_switch_tools_and_undo() {
        let mut rt = app("keys");
        rt.key(rune::KeyEvent { key: rune::Key::Text("r".into()), mods: rune::Mods::default() });
        rt.frame(0.0);
        assert_eq!(rt.state.ctx.tool.active().unwrap().id(), squiggle_core::tools::tool::ToolId::Rectangle);
        drag(&mut rt, (300.0, 300.0), (420.0, 380.0));
        assert_eq!(rt.state.ctx.document.nodes().len(), 1);
        let undo = rune::KeyEvent { key: rune::Key::Command('z'), mods: rune::Mods { cmd: true, ctrl: true, ..Default::default() } };
        rt.key(undo);
        rt.frame(0.0);
        assert_eq!(rt.state.ctx.document.nodes().len(), 0);
    }

    #[test]
    fn text_tool_creates_text_through_the_inline_editor() {
        let mut rt = app("text");
        rt.key(rune::KeyEvent { key: rune::Key::Text("t".into()), mods: rune::Mods::default() });
        rt.frame(0.0);
        let (x, y) = (400.0, 300.0);
        rt.pointer_move(x, y);
        rt.pointer_down(x, y);
        rt.pointer_up(x, y);
        rt.frame(0.0);
        rt.frame(0.0);
        assert!(rt.state.ctx.text_edit.session().is_some(), "clicking with the text tool opens the editor");
        for ch in ["h", "i"] {
            rt.key(rune::KeyEvent { key: rune::Key::Text(ch.into()), mods: rune::Mods::default() });
            rt.frame(0.0);
        }
        assert_eq!(rt.state.ctx.text_edit.draft, "hi");
        rt.key(rune::KeyEvent { key: rune::Key::Escape, mods: rune::Mods::default() });
        rt.frame(0.0);
        assert!(rt.state.ctx.text_edit.session().is_none());
        assert_eq!(rt.state.ctx.document.nodes().len(), 1);
        let feature = rt.state.ctx.document.nodes()[0].as_feature().unwrap();
        assert_eq!(feature.kind.label(), Some("hi"));
    }

    #[test]
    fn holding_b_opens_the_brush_wheel_for_drawing_tools() {
        use crate::inspector::brush_wheel::host;
        let mut rt = app("wheel");
        let key = |k: &str| rune::KeyEvent { key: rune::Key::Text(k.into()), mods: rune::Mods::default() };
        rt.key(key("b"));
        rt.frame(0.0);
        assert!(!host::is_open(&rt.state), "no wheel with the select tool");
        rt.key(key("r"));
        rt.pointer_move(500.0, 400.0);
        rt.frame(0.0);
        rt.key(key("b"));
        rt.frame(0.0);
        assert!(host::is_open(&rt.state));
        rt.key_up(key("b"));
        rt.frame(0.0);
        assert!(!host::is_open(&rt.state));
    }

    #[test]
    fn enter_finishes_a_polyline_through_the_active_tool() {
        let mut rt = app("line");
        let key = |k: rune::Key| rune::KeyEvent { key: k, mods: rune::Mods::default() };
        rt.key(key(rune::Key::Text("l".into())));
        rt.frame(0.0);
        for (x, y) in [(300.0, 300.0), (400.0, 340.0)] {
            rt.pointer_move(x, y);
            rt.pointer_down(x, y);
            rt.pointer_up(x, y);
            rt.frame(0.0);
        }
        rt.key(key(rune::Key::Enter));
        rt.frame(0.0);
        assert_eq!(rt.state.ctx.document.nodes().len(), 1, "Enter commits the polyline");
    }
}
