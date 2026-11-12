//! Floating tool bar (port of `editor_toolbar.dart`).

use super::command::{Command, is_enabled, run};
use crate::kit::{self, metrics};
use crate::state::State;
use crate::theme;
use rune::{El, LineCap, Shape, Tx, canvas, row, text};
use squiggle_core::tools::tool::ToolId;

const ICON: f32 = 20.0;

fn ink(active: bool) -> rune::Color {
    if active { theme::text() } else { theme::subtext() }
}

/// Tool glyphs drawn as vector shapes in a 20×20 box.
fn glyph(tool: ToolId, color: rune::Color) -> El {
    let outline = |s: Shape| s.view_box(ICON, ICON);
    let shape = match tool {
        ToolId::Select => Shape::new()
            .fill(vec![[5.0, 3.0], [5.0, 16.0], [8.5, 12.5], [11.0, 17.5], [13.0, 16.5], [10.5, 11.5], [15.0, 11.5]], color),
        ToolId::Rectangle => Shape::new().stroke_with(vec![[4.0, 5.0], [16.0, 5.0], [16.0, 15.0], [4.0, 15.0]], true, 1.6, LineCap::Round, color),
        ToolId::Circle => {
            let pts: Vec<[f32; 2]> = (0..48)
                .map(|i| {
                    let a = i as f32 / 48.0 * std::f32::consts::TAU;
                    [10.0 + 6.5 * a.cos(), 10.0 + 6.5 * a.sin()]
                })
                .collect();
            Shape::new().stroke_with(pts, true, 1.6, LineCap::Round, color)
        }
        ToolId::Line => Shape::new().line([4.0, 16.0], [16.0, 4.0], 1.8, LineCap::Round, color),
        ToolId::Text => return text("A").font(kit::BODY).color(color),
    };
    canvas(outline(shape)).size(ICON, ICON)
}

fn undo_glyph(color: rune::Color, flip: bool) -> El {
    let x = |v: f32| if flip { 20.0 - v } else { v };
    let shape = Shape::new()
        .stroke(vec![[x(7.0), 5.0], [x(3.5), 8.5], [x(7.0), 12.0]], 1.6, color)
        .stroke(vec![[x(3.5), 8.5], [x(12.0), 8.5], [x(16.0), 11.0], [x(16.0), 14.5]], 1.6, color);
    canvas(shape.view_box(ICON, ICON)).size(ICON, ICON)
}

fn lock_glyph(locked: bool, color: rune::Color) -> El {
    let body = Shape::new().stroke_with(vec![[5.0, 9.0], [15.0, 9.0], [15.0, 16.0], [5.0, 16.0]], true, 1.6, LineCap::Round, color);
    let shackle = if locked {
        vec![[7.0, 9.0], [7.0, 6.0], [13.0, 6.0], [13.0, 9.0]]
    } else {
        vec![[7.0, 9.0], [7.0, 6.0], [13.0, 6.0], [13.0, 7.0]]
    };
    canvas(body.stroke(shackle, 1.6, color).view_box(ICON, ICON)).size(ICON, ICON)
}

fn tool_button(s: &State, id: ToolId, key: &str) -> El {
    let active = s.ctx.tool.active().is_some_and(|t| t.id() == id);
    kit::toolbar_button(key, active, true, glyph(id, ink(active)), move |s: &mut State| {
        s.ctx.set_tool(super::command::tool_for(id));
    })
}

fn command_button(key: &str, cmd: Command, enabled: bool, content: El) -> El {
    kit::toolbar_button_tx(key, false, enabled, content, move |s: &mut State, tx: &mut Tx| run(s, tx, cmd))
}

pub fn view(s: &State) -> El {
    let locked = s.ctx.tool.is_locked();
    let enabled = |c| is_enabled(s, c);
    let library = kit::toolbar_button("library", false, true, text("☰").font(kit::BODY).color(ink(false)), |s: &mut State| {
        crate::library::open_library(s);
    });
    let bar = row()
        .items_center()
        .gap(metrics::TOOLBAR_GAP)
        .padding(metrics::TOOLBAR_PADDING)
        .child(library)
        .child(kit::divider_vertical())
        .child(kit::toolbar_button("lock", locked, true, lock_glyph(locked, ink(locked)), |s: &mut State| s.ctx.tool.toggle_lock()))
        .child(kit::divider_vertical())
        .child(tool_button(s, ToolId::Select, "tool-select"))
        .child(kit::divider_vertical())
        .child(tool_button(s, ToolId::Rectangle, "tool-rect"))
        .child(tool_button(s, ToolId::Circle, "tool-circle"))
        .child(tool_button(s, ToolId::Line, "tool-line"))
        .child(tool_button(s, ToolId::Text, "tool-text"))
        .child(kit::divider_vertical())
        .child(command_button("undo", Command::Undo, enabled(Command::Undo), undo_glyph(ink(enabled(Command::Undo)), false)))
        .child(command_button("redo", Command::Redo, enabled(Command::Redo), undo_glyph(ink(enabled(Command::Redo)), true)));
    row()
        .key("toolbar-row")
        .absolute(0.0, metrics::OVERLAY_TOP)
        .w_full()
        .justify_center()
        .child(kit::floating_panel().key("toolbar").child(bar))
}
