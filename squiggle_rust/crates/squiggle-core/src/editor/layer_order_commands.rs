use super::history::{History, HistoryError};
use super::selection::{Selection, selected_siblings};
use crate::document::Document;
use crate::ids::{Container, NodeId};
use crate::node::Node;
use std::collections::HashSet;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LayerOrder {
    Backward,
    Forward,
    Back,
    Front,
}

/// The reordered sibling ids for `action`, or `None` when it is invalid or a no-op.
fn new_order(doc: &Document, selection: &Selection, action: LayerOrder) -> Option<(Container, Vec<NodeId>)> {
    let (container, ids) = selected_siblings(doc, selection)?;
    let selected: HashSet<NodeId> = ids.into_iter().collect();
    let current: Vec<NodeId> = doc.children(container)?.iter().map(Node::id).collect();
    let mut order = current.clone();
    match action {
        LayerOrder::Backward => {
            for i in 1..order.len() {
                if selected.contains(&order[i]) && !selected.contains(&order[i - 1]) {
                    order.swap(i, i - 1);
                }
            }
        }
        LayerOrder::Forward => {
            for i in (0..order.len().saturating_sub(1)).rev() {
                if selected.contains(&order[i]) && !selected.contains(&order[i + 1]) {
                    order.swap(i, i + 1);
                }
            }
        }
        LayerOrder::Back | LayerOrder::Front => {
            let (picked, rest): (Vec<_>, Vec<_>) = current.iter().partition(|id| selected.contains(id));
            let (first, second) = if action == LayerOrder::Back { (picked, rest) } else { (rest, picked) };
            order = first.into_iter().chain(second).copied().collect();
        }
    }
    (order != current).then_some((container, order))
}

pub fn can_reorder_selected_nodes(doc: &Document, selection: &Selection, action: LayerOrder) -> bool {
    new_order(doc, selection, action).is_some()
}

/// Reorders the selected siblings as one undoable edit; returns whether anything changed.
pub fn reorder_selected_nodes(
    doc: &mut Document,
    history: &mut History,
    selection: &Selection,
    action: LayerOrder,
) -> Result<bool, HistoryError> {
    let Some((container, order)) = new_order(doc, selection, action) else { return Ok(false) };
    history.run(doc, "Reorder selection", container, |tx| tx.reorder(&order))?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::test_util::{ids, rect_at};
    use crate::geom::Point;
    use crate::group::Group;

    fn make_doc() -> Document {
        Document::from_nodes((0..4).map(|i| rect_at(i as f64 * 10.0, 0.0)))
    }

    #[test]
    fn each_action_preserves_selection_and_supports_undo_redo() {
        let cases = [
            (LayerOrder::Backward, [1, 0, 2, 3]),
            (LayerOrder::Forward, [0, 2, 1, 3]),
            (LayerOrder::Back, [1, 0, 2, 3]),
            (LayerOrder::Front, [0, 2, 3, 1]),
        ];
        for (action, expected) in cases {
            let mut doc = make_doc();
            let (mut history, mut sel) = (History::new(), Selection::new());
            let original = ids(&doc);
            let expected: Vec<_> = expected.iter().map(|&i| original[i]).collect();
            sel.set_selection([original[1]]);
            assert!(can_reorder_selected_nodes(&doc, &sel, action));
            assert!(reorder_selected_nodes(&mut doc, &mut history, &sel, action).unwrap());
            assert_eq!(ids(&doc), expected);
            assert_eq!(sel.selected_node_ids(), &[original[1]]);
            assert!(history.can_undo());
            history.undo(&mut doc).unwrap();
            assert_eq!(ids(&doc), original);
            history.redo(&mut doc).unwrap();
            assert_eq!(ids(&doc), expected);
        }
    }

    #[test]
    fn adjacent_selected_nodes_move_together_in_paint_order() {
        let mut doc = make_doc();
        let (mut history, mut sel) = (History::new(), Selection::new());
        let o = ids(&doc);
        sel.set_selection([o[2], o[1]]);
        reorder_selected_nodes(&mut doc, &mut history, &sel, LayerOrder::Forward).unwrap();
        assert_eq!(ids(&doc), vec![o[0], o[3], o[1], o[2]]);
        reorder_selected_nodes(&mut doc, &mut history, &sel, LayerOrder::Back).unwrap();
        assert_eq!(ids(&doc), vec![o[1], o[2], o[0], o[3]]);
    }

    #[test]
    fn nested_siblings_reorder_without_moving_their_parent() {
        let mut doc = Document::default();
        let children: Vec<Node> = (0..4).map(|i| rect_at(i as f64 * 10.0, 0.0)).collect();
        let group = doc.insert(None, Group::new(Point::ZERO, children).into(), None).unwrap();
        let kids: Vec<_> = doc.children(Some(group)).unwrap().iter().map(Node::id).collect();
        let (mut history, mut sel) = (History::new(), Selection::new());
        sel.set_selection([kids[0]]);
        reorder_selected_nodes(&mut doc, &mut history, &sel, LayerOrder::Front).unwrap();
        let after: Vec<_> = doc.children(Some(group)).unwrap().iter().map(Node::id).collect();
        assert_eq!(after.last(), Some(&kids[0]));
        assert_eq!(ids(&doc), vec![group]);
        history.undo(&mut doc).unwrap();
        let undone: Vec<_> = doc.children(Some(group)).unwrap().iter().map(Node::id).collect();
        assert_eq!(undone, kids);
    }

    #[test]
    fn boundary_and_invalid_selections_create_no_edit() {
        let mut doc = make_doc();
        let (mut history, mut sel) = (History::new(), Selection::new());
        let o = ids(&doc);
        sel.set_selection([o[0]]);
        assert!(!can_reorder_selected_nodes(&doc, &sel, LayerOrder::Backward));
        assert!(!reorder_selected_nodes(&mut doc, &mut history, &sel, LayerOrder::Backward).unwrap());
        assert!(!history.can_undo());
        sel.set_selection(o.clone());
        assert!(!can_reorder_selected_nodes(&doc, &sel, LayerOrder::Front));
        sel.set_selection([o[1], NodeId(999)]);
        assert!(!can_reorder_selected_nodes(&doc, &sel, LayerOrder::Front));
    }
}
