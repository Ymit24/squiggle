//! Editor page: viewport, toolbar, shortcuts, context menu, inline text editing.
//! Owner: editor-chrome. `view` is called by `main.rs` when `Page::Editor` is active.

pub mod command;
pub mod context_menu;
pub mod shortcuts;
pub mod text_overlay;
pub mod toolbar;

use crate::state::State;
use rune::{Cx, El, el};
use squiggle_core::geom::Point;
use squiggle_core::tools::tool::Modifiers;

/// Transient editor-page UI state.
#[derive(Default)]
pub struct EditorUi {
    /// Modifier keys currently held (from `App::on_modifiers`).
    pub mods: Modifiers,
    /// Last pointer position over the viewport, in viewport pixels.
    pub pointer: Point,
    /// Camera location when a pan drag (secondary/middle button) began.
    pub pan_origin: Option<Point>,
    /// Open context menu: (viewport position, world position).
    pub context_menu: Option<(Point, Point)>,
    /// Inertial pan in progress, with the time it started.
    pub fling: Option<(squiggle_core::fling::Fling, f64)>,
    /// Last trackpad-scroll sample (time, velocity px/s), used to start a fling on release.
    pub scroll_velocity: Option<(f64, Point)>,
    /// Seconds since start, from the app's per-frame poll.
    pub now: f64,
    /// The inline text field's content and the core session it was made for.
    pub text: rune::TextEdit,
    /// Whether the freshly opened field has been focused yet.
    pub text_focus_done: bool,
    pub text_session: Option<squiggle_core::editor::text_edit::TextEditSession>,
}

pub fn view(s: &State, _cx: &mut Cx<State>) -> El {
    el()
        .w_full()
        .h_full()
        .on_key_up(|s: &mut State, e: &rune::KeyEvent, _tx| {
            let released_b = e.key == rune::Key::Text("b".into());
            if released_b && crate::inspector::brush_wheel::host::is_open(s) {
                crate::inspector::brush_wheel::host::close(s, true);
            }
            released_b
        })
        .child(crate::viewport::view(s))
        .child(text_overlay::view(s))
        .child(toolbar::view(s))
        .child(crate::inspector::panel(s))
        .child(back_to_content(s))
        .child(context_menu::view(s))
        .child(crate::inspector::overlays(s))
}

/// Window-level key handler: tool/edit shortcuts (installed via `AppSpec::on_key`).
pub fn on_key(s: &mut State, e: &rune::KeyEvent, tx: &mut rune::Tx) -> bool {
    if s.page != crate::state::Page::Editor {
        return false;
    }
    use crate::inspector::{brush_wheel::host, close_menus};
    if host::is_open(s) {
        // The wheel is modal while B is held.
        if e.key == rune::Key::Escape {
            host::close(s, false);
        }
        return true;
    }
    if e.key == rune::Key::Text("b".into()) && !e.mods.cmd && !e.mods.ctrl {
        let held = e.mods.shift || e.mods.alt;
        if host::open(s, held) {
            return true;
        }
    }
    if e.key == rune::Key::Escape && close_menus(s) {
        return true;
    }
    if s.ctx.text_edit.session().is_none() && forward_to_tool(s, e) {
        s.autosave_if_changed();
        return true;
    }
    match shortcuts::command_for(e) {
        Some(cmd) => {
            command::run(s, tx, cmd);
            true
        }
        None => false,
    }
}

fn back_to_content(s: &State) -> El {
    if !s.ctx.content_is_off_screen() {
        return el();
    }
    rune::row().absolute(0.0, 0.0).w_full().h_full().justify_center().items_end().padding(24.0).child(
        crate::kit::button("Back to content", |s: &mut State| s.ctx.jump_back_to_content()).key("back-to-content"),
    )
}

/// Per-frame hook (`AppSpec::poll`): advances an inertial pan. Returns whether state changed.
pub fn poll(s: &mut State, time: f64, _tx: &mut rune::Tx) -> bool {
    s.editor_ui.now = time;
    let Some((mut fling, started)) = s.editor_ui.fling else { return false };
    let t = time - started;
    s.ctx.camera.pan_by_screen_delta(fling.delta_at(t));
    s.editor_ui.fling = (!fling.is_done(t)).then_some((fling, started));
    true
}

/// Gives the active tool first refusal on a key (Enter/Escape finish or cancel a gesture,
/// the select tool handles delete, group and arrows).
fn forward_to_tool(s: &mut State, e: &rune::KeyEvent) -> bool {
    use squiggle_core::tools::tool::{Key, KeyInput};
    let key = match &e.key {
        rune::Key::Escape => Key::Escape,
        rune::Key::Enter => Key::Enter,
        rune::Key::Backspace => Key::Backspace,
        rune::Key::Delete => Key::Delete,
        rune::Key::Tab => Key::Tab,
        rune::Key::Left => Key::Left,
        rune::Key::Right => Key::Right,
        rune::Key::Up => Key::Up,
        rune::Key::Down => Key::Down,
        rune::Key::Command(c) => Key::Char(*c),
        rune::Key::Text(t) if t.chars().count() == 1 => Key::Char(t.chars().next().unwrap()),
        _ => return false,
    };
    let mods = squiggle_core::tools::tool::Modifiers { shift: e.mods.shift, alt: e.mods.alt, command: e.mods.cmd || e.mods.ctrl };
    squiggle_core::editor::tool_model::ToolModel::on_key(&mut s.ctx, KeyInput { key, mods })
}
