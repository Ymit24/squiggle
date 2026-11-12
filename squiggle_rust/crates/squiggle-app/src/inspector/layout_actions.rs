//! Align / distribute for multi-selections (port of `inspector_layout_actions.dart`).

use super::field_shell::field_shell;
use super::metrics::PANEL_SECTION_SPACING;
use super::node_align_selector::node_align_selector;
use super::node_distribute_selector::node_distribute_selector;
use crate::state::State;
use rune::{El, col};
use squiggle_core::editor::layout_commands::apply_node_layout;
use squiggle_core::editor::selection::selected_siblings;
use squiggle_core::node::Node;
use squiggle_core::node_layout::{NodeAlignment, NodeDistribution, align_nodes, distribute_nodes};
use std::rc::Rc;

/// Runs `layout` over the selected siblings as one "Layout selection" edit. Selections that do
/// not share a container are left alone.
fn apply_layout(s: &mut State, layout: impl Fn(&mut [Node])) {
    let ctx = &mut s.ctx;
    let Some((_, ids)) = selected_siblings(&ctx.document, &ctx.selection) else { return };
    let ids_for_closure = ids.clone();
    let _ = apply_node_layout(&mut ctx.document, &mut ctx.history, &ids, |doc| {
        let mut nodes: Vec<Node> = ids_for_closure.iter().filter_map(|&id| doc.node(id).cloned()).collect();
        layout(&mut nodes);
        for node in nodes {
            let id = node.id();
            if let Some(slot) = doc.node_mut(id) {
                *slot = node;
            }
        }
    });
    s.autosave_if_changed();
}

pub fn layout_actions(node_count: usize) -> El {
    let mut sections = col().gap(PANEL_SECTION_SPACING);
    if node_count >= 2 {
        let on_align = Rc::new(|s: &mut State, a: NodeAlignment| apply_layout(s, |n| align_nodes(n, a)));
        sections = sections.child(field_shell("Align", None, node_align_selector(on_align)));
    }
    if node_count >= 3 {
        let on_distribute = Rc::new(|s: &mut State, d: NodeDistribution| apply_layout(s, |n| distribute_nodes(n, d)));
        sections = sections.child(field_shell("Distribute", None, node_distribute_selector(on_distribute)));
    }
    sections
}
