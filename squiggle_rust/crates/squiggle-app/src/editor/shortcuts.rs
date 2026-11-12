//! Keyboard shortcut table (port of `tool_shortcuts.dart`).

use super::command::Command;
use rune::{Key, KeyEvent};
use squiggle_core::editor::layer_order_commands::LayerOrder;
use squiggle_core::tools::tool::ToolId;

pub fn command_for(e: &KeyEvent) -> Option<Command> {
    let m = e.mods;
    match &e.key {
        Key::Command(c) if !m.alt => command_with_cmd(*c, m.shift),
        Key::Command(c) => reorder_to_extreme(*c),
        Key::Text(t) if !m.cmd && !m.ctrl => plain(t),
        Key::Backspace | Key::Delete => Some(Command::Delete),
        Key::Escape => Some(Command::ClearSelection),
        _ => None,
    }
}

fn command_with_cmd(c: char, shift: bool) -> Option<Command> {
    Some(match c {
        'z' if shift => Command::Redo,
        'z' => Command::Undo,
        'y' => Command::Redo,
        'c' => Command::Copy,
        'x' => Command::Cut,
        'v' => Command::Paste,
        'd' => Command::Duplicate,
        'a' => Command::SelectAll,
        'g' if shift => Command::Ungroup,
        'g' => Command::Group,
        '[' => Command::Reorder(LayerOrder::Backward),
        ']' => Command::Reorder(LayerOrder::Forward),
        '1'..='9' => Command::ActivateBrush(c as usize - '1' as usize),
        _ => return None,
    })
}

fn reorder_to_extreme(c: char) -> Option<Command> {
    match c {
        '[' => Some(Command::Reorder(LayerOrder::Back)),
        ']' => Some(Command::Reorder(LayerOrder::Front)),
        _ => None,
    }
}

fn plain(text: &str) -> Option<Command> {
    Some(match text.to_ascii_lowercase().as_str() {
        "v" | "1" => Command::SetTool(ToolId::Select),
        "r" | "2" => Command::SetTool(ToolId::Rectangle),
        "c" | "3" => Command::SetTool(ToolId::Circle),
        "l" | "4" => Command::SetTool(ToolId::Line),
        "t" | "5" => Command::SetTool(ToolId::Text),
        "q" => Command::ToggleToolLock,
        _ => return None,
    })
}
