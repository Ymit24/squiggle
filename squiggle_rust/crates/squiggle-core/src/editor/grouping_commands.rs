use super::history::{History, HistoryError};
use super::selection::{Selection, selected_siblings};
use crate::document::Document;
use crate::group::Group;
use crate::ids::{Container, NodeId};
use crate::node::Node;
use std::collections::HashSet;

/// Whether the selection contains at least two direct siblings.
pub fn can_group_selected_nodes(doc: &Document, selection: &Selection) -> bool {
    matches!(selected_siblings(doc, selection), Some((_, ids)) if ids.len() >= 2)
}

/// Selected groups that share a container; non-group nodes in a mixed selection do not affect
/// ungroup eligibility.
fn selected_groups(doc: &Document, selection: &Selection) -> Option<(Container, Vec<NodeId>)> {
    let ids: Vec<NodeId> = selection
        .selected_node_ids()
        .iter()
        .copied()
        .filter(|&id| doc.node(id).is_some_and(|n| n.as_group().is_some()))
        .collect();
    let container = doc.parent_of(*ids.first()?)?;
    ids.iter().all(|&id| doc.parent_of(id) == Some(container)).then_some((container, ids))
}

pub fn can_ungroup_selected_nodes(doc: &Document, selection: &Selection) -> bool {
    selected_groups(doc, selection).is_some()
}

/// Wraps the selected siblings in a new group placed at the top-most selected position.
/// Returns the new group's id, or `None` when the selection cannot be grouped.
pub fn group_selected_nodes(
    doc: &mut Document,
    history: &mut History,
    selection: &mut Selection,
) -> Result<Option<NodeId>, HistoryError> {
    let Some((container, ids)) = selected_siblings(doc, selection).filter(|(_, ids)| ids.len() >= 2) else {
        return Ok(None);
    };
    let selected: HashSet<NodeId> = ids.iter().copied().collect();
    let siblings: Vec<NodeId> = doc.children(container).unwrap_or_default().iter().map(Node::id).collect();
    let topmost = siblings.iter().rposition(|id| selected.contains(id)).unwrap_or(0);
    let insertion_index = siblings[..topmost].iter().filter(|id| !selected.contains(id)).count();

    let group_id = history.run(doc, "Group Selected Nodes", container, |tx| {
        let mut nodes = tx.remove_all(&ids)?;
        let center = Node::local_bounds_of_nodes(&nodes).center();
        for node in &mut nodes {
            node.set_origin(node.origin() - center);
        }
        tx.add(Group::new(center, nodes), Some(insertion_index))
    })?;
    selection.set_selection([group_id]);
    Ok(Some(group_id))
}

/// Replaces each selected group with its children (in place, in paint order) and selects them.
/// Returns the freed children's ids.
pub fn ungroup_selected_nodes(
    doc: &mut Document,
    history: &mut History,
    selection: &mut Selection,
) -> Result<Vec<NodeId>, HistoryError> {
    let Some((container, group_ids)) = selected_groups(doc, selection) else { return Ok(Vec::new()) };
    let original_order: Vec<NodeId> = doc.children(container).unwrap_or_default().iter().map(Node::id).collect();
    let new_selection = history.run(doc, "Ungroup Selected Nodes", container, |tx| {
        let mut replacements: Vec<(NodeId, Vec<NodeId>)> = Vec::new();
        let mut freed = Vec::new();
        for node in tx.remove_all(&group_ids)? {
            let Node::Group(group) = node else { continue };
            let mut child_ids = Vec::new();
            for mut child in group.children {
                child.set_origin(child.origin() + group.origin);
                child_ids.push(tx.add(child, None)?);
            }
            freed.extend(&child_ids);
            replacements.push((group.id, child_ids));
        }
        let order: Vec<NodeId> = original_order
            .iter()
            .flat_map(|id| match replacements.iter().find(|(g, _)| g == id) {
                Some((_, children)) => children.clone(),
                None => vec![*id],
            })
            .collect();
        tx.reorder(&order)?;
        Ok(freed)
    })?;
    selection.set_selection(new_selection.iter().copied());
    Ok(new_selection)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::test_util::{ids, rect_at, snapshot};
    use crate::geom::{Point, Rect};

    fn doc_of(n: usize) -> Document {
        Document::from_nodes((0..n).map(|i| rect_at(i as f64 * 100.0, 0.0)))
    }

    fn gbounds(doc: &Document) -> Vec<Rect> {
        doc.nodes().iter().map(|n| doc.global_bounds(n.id()).unwrap()).collect()
    }

    #[test]
    fn group_then_ungroup_with_history() {
        let mut doc = doc_of(3);
        let (mut history, mut sel) = (History::new(), Selection::new());
        let all = ids(&doc);
        let bounds = gbounds(&doc);
        let before = snapshot(&doc);
        sel.set_selection(all.clone());

        let group = group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap().unwrap();
        assert_eq!(sel.selected_node_ids(), &[group]);
        assert_eq!(doc.nodes().len(), 1);
        let g = doc.node(group).unwrap().as_group().unwrap();
        assert_eq!(g.children.iter().map(Node::id).collect::<Vec<_>>(), all);
        let child_bounds: Vec<_> = all.iter().map(|&id| doc.global_bounds(id).unwrap()).collect();
        assert_eq!(child_bounds, bounds);
        let grouped = snapshot(&doc);

        history.undo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), before);
        assert!(!history.can_undo());
        history.redo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), grouped);

        sel.set_selection([group]);
        ungroup_selected_nodes(&mut doc, &mut history, &mut sel).unwrap();
        assert_eq!(ids(&doc), all);
        assert_eq!(gbounds(&doc), bounds);
        assert_eq!(sel.selected_node_ids(), all.as_slice());
        assert!(doc.nodes().iter().all(|n| doc.parent_of(n.id()) == Some(None)));
        let ungrouped = snapshot(&doc);
        history.undo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), grouped);
        history.redo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), ungrouped);
    }

    #[test]
    fn empty_and_single_selections_are_unchanged() {
        let mut doc = doc_of(3);
        let (mut history, mut sel) = (History::new(), Selection::new());
        let before = snapshot(&doc);
        assert!(!can_group_selected_nodes(&doc, &sel));
        assert_eq!(group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap(), None);
        sel.select_node(doc.nodes()[0].id());
        assert!(!can_group_selected_nodes(&doc, &sel));
        assert_eq!(group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap(), None);
        assert!(!can_ungroup_selected_nodes(&doc, &sel));
        assert!(ungroup_selected_nodes(&mut doc, &mut history, &mut sel).unwrap().is_empty());
        assert_eq!(snapshot(&doc), before);
        assert!(!history.can_undo());
    }

    #[test]
    fn grouping_preserves_sibling_and_child_paint_order() {
        let mut doc = doc_of(2);
        let all = ids(&doc);
        let third = doc.insert(None, rect_at(400.0, 0.0), None).unwrap();
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection([all[1], all[0]]);

        group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap();
        let group = doc.nodes()[0].as_group().unwrap();
        assert_eq!(group.children.iter().map(Node::id).collect::<Vec<_>>(), all);
        assert_eq!(doc.nodes()[1].id(), third);
        history.undo(&mut doc).unwrap();
        assert_eq!(ids(&doc), vec![all[0], all[1], third]);
    }

    #[test]
    fn group_lands_at_topmost_selected_position() {
        let mut doc = doc_of(4);
        let all = ids(&doc);
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection([all[0], all[2]]);
        let group = group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap().unwrap();
        assert_eq!(ids(&doc), vec![all[1], group, all[3]]);
    }

    #[test]
    fn ungrouping_multiple_groups_is_one_undo_entry() {
        let mut doc = Document::default();
        let a = doc.insert(None, Group::new(Point::ZERO, vec![rect_at(0.0, 0.0)]).into(), None).unwrap();
        let b = doc.insert(None, Group::new(Point::ZERO, vec![rect_at(50.0, 0.0)]).into(), None).unwrap();
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection([a, b]);
        assert!(can_ungroup_selected_nodes(&doc, &sel));

        ungroup_selected_nodes(&mut doc, &mut history, &mut sel).unwrap();
        assert!(doc.nodes().iter().all(|n| n.as_group().is_none()));
        assert!(history.can_undo());
        history.undo(&mut doc).unwrap();
        assert_eq!(doc.nodes().iter().filter(|n| n.as_group().is_some()).count(), 2);
        assert!(!history.can_undo());
    }

    #[test]
    fn mixed_selection_ungroups_only_groups() {
        let mut doc = Document::default();
        let g = doc.insert(None, Group::new(Point::ZERO, vec![rect_at(0.0, 0.0)]).into(), None).unwrap();
        let f = doc.insert(None, rect_at(300.0, 0.0), None).unwrap();
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection([f, g]);
        assert!(can_ungroup_selected_nodes(&doc, &sel));
        ungroup_selected_nodes(&mut doc, &mut history, &mut sel).unwrap();
        assert_eq!(doc.nodes().len(), 2);
        assert_eq!(doc.nodes()[1].id(), f);
    }

    #[test]
    fn nested_groups_use_their_own_container() {
        let mut doc = Document::default();
        let outer = doc
            .insert(None, Group::new(Point::new(10.0, 10.0), vec![rect_at(0.0, 0.0), rect_at(50.0, 0.0)]).into(), None)
            .unwrap();
        let kids: Vec<_> = doc.children(Some(outer)).unwrap().iter().map(Node::id).collect();
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection(kids.clone());
        let g = group_selected_nodes(&mut doc, &mut history, &mut sel).unwrap().unwrap();
        assert_eq!(doc.nodes().len(), 1);
        assert_eq!(doc.parent_of(g), Some(Some(outer)));
        history.undo(&mut doc).unwrap();
        assert_eq!(doc.children(Some(outer)).unwrap().iter().map(Node::id).collect::<Vec<_>>(), kids);
    }
}
