//! Right-click context menu (port of `context_menu.dart`).

use super::command::{Command, is_enabled, run};
use crate::kit::{self, metrics};
use crate::state::State;
use rune::{El, Tx, col, el, text};
use squiggle_core::editor::layer_order_commands::LayerOrder;
use squiggle_core::geom::Point;
use squiggle_core::node::Node;
use squiggle_core::node_layout::{NodeAlignment, NodeDistribution, align_nodes, distribute_nodes};
use squiggle_core::editor::layout_commands::apply_node_layout;
use crate::theme;

fn item(s: &State, key: &str, label: &str, shortcut: &str, cmd: Command) -> El {
    kit::menu_item_tx(key, label, Some(shortcut), is_enabled(s, cmd), move |s: &mut State, tx: &mut Tx| {
        run(s, tx, cmd);
        s.editor_ui.context_menu = None;
    })
}

fn group_label(label: &str) -> El {
    text(label).font(kit::SECTION).color(theme::subtext())
}

fn layout_target(s: &State) -> Option<Vec<squiggle_core::NodeId>> {
    let ids = s.ctx.selection.selected_node_ids();
    let parent = s.ctx.document.parent_of(*ids.first()?)?;
    let same_parent = ids.iter().all(|id| s.ctx.document.parent_of(*id) == Some(parent));
    (ids.len() >= 2 && same_parent).then(|| ids.to_vec())
}

fn layout_item(s: &State, key: &str, label: &str, min: usize, apply: impl Fn(&mut Vec<Node>) + 'static) -> El {
    let ids = layout_target(s).filter(|ids| ids.len() >= min);
    kit::menu_item_tx(key, label, None, ids.is_some(), move |s: &mut State, _tx: &mut Tx| {
        let Some(ids) = layout_target(s) else { return };
        s.ctx.cancel_interaction();
        let State { ctx, .. } = s;
        let _ = apply_node_layout(&mut ctx.document, &mut ctx.history, &ids, |doc| {
            let mut nodes: Vec<Node> = ids.iter().filter_map(|id| doc.node(*id).cloned()).collect();
            apply(&mut nodes);
            for n in nodes {
                if let Some(slot) = doc.node_mut(n.id()) {
                    *slot = n;
                }
            }
        });
        s.editor_ui.context_menu = None;
        s.autosave_if_changed();
    })
}

pub fn view(s: &State) -> El {
    let Some((at, world)) = s.editor_ui.context_menu else { return el() };
    let _: Point = world;
    let mut menu = kit::menu_panel().key("context-menu");
    let history = |m: El| {
        m.child(item(s, "menu-undo", "Undo", "⌘Z", Command::Undo))
            .child(item(s, "menu-redo", "Redo", "⇧⌘Z", Command::Redo))
            .child(kit::divider_horizontal())
    };
    menu = history(menu);
    if s.ctx.selection.is_empty() {
        menu = menu
            .child(item(s, "menu-select-all", "Select All", "⌘A", Command::SelectAll))
            .child(kit::divider_horizontal())
            .child(item(s, "menu-paste", "Paste", "⌘V", Command::Paste));
    } else {
        menu = menu
            .child(item(s, "menu-cut", "Cut", "⌘X", Command::Cut))
            .child(item(s, "menu-duplicate", "Duplicate", "⌘D", Command::Duplicate))
            .child(item(s, "menu-copy", "Copy", "⌘C", Command::Copy))
            .child(item(s, "menu-paste", "Paste", "⌘V", Command::Paste))
            .child(kit::divider_horizontal())
            .child(item(s, "menu-group", "Group", "⌘G", Command::Group))
            .child(item(s, "menu-ungroup", "Ungroup", "⇧⌘G", Command::Ungroup))
            .child(kit::divider_horizontal())
            .child(item(s, "menu-backward", "Bring backward", "⌘[", Command::Reorder(LayerOrder::Backward)))
            .child(item(s, "menu-forward", "Bring forward", "⌘]", Command::Reorder(LayerOrder::Forward)))
            .child(item(s, "menu-back", "Send to Back", "⌘⌥[", Command::Reorder(LayerOrder::Back)))
            .child(item(s, "menu-front", "Bring to Front", "⌘⌥]", Command::Reorder(LayerOrder::Front)))
            .child(kit::divider_horizontal())
            .child(group_label("Align"))
            .child(layout_item(s, "align-left", "Left", 2, |n| align_nodes(n, NodeAlignment::Left)))
            .child(layout_item(s, "align-center", "Center", 2, |n| align_nodes(n, NodeAlignment::CenterHorizontal)))
            .child(layout_item(s, "align-right", "Right", 2, |n| align_nodes(n, NodeAlignment::Right)))
            .child(layout_item(s, "align-top", "Top", 2, |n| align_nodes(n, NodeAlignment::Top)))
            .child(layout_item(s, "align-middle", "Middle", 2, |n| align_nodes(n, NodeAlignment::CenterVertical)))
            .child(layout_item(s, "align-bottom", "Bottom", 2, |n| align_nodes(n, NodeAlignment::Bottom)))
            .child(kit::divider_horizontal())
            .child(group_label("Distribute"))
            .child(layout_item(s, "dist-h", "Horizontally", 3, |n| distribute_nodes(n, NodeDistribution::Horizontal)))
            .child(layout_item(s, "dist-v", "Vertically", 3, |n| distribute_nodes(n, NodeDistribution::Vertical)))
            .child(kit::divider_horizontal())
            .child(item(s, "menu-delete", "Delete", "⌫", Command::Delete));
    }
    // A full-viewport scrim dismisses the menu on any outside click; the menu sits at the click.
    let _ = (col(), metrics::MENU_WIDTH);
    el().key("context-menu-scrim")
        .absolute(0.0, 0.0)
        .w_full()
        .h_full()
        .on_press(|s: &mut State| s.editor_ui.context_menu = None)
        .child(el().absolute(at.x as f32, at.y as f32).child(menu))
}
