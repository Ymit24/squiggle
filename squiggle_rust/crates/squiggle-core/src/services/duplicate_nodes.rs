use crate::document::Document;
use crate::editor::history::{History, HistoryError, Tx};
use crate::editor::selection::{Selection, selected_siblings};
use crate::geom::Point;
use crate::ids::NodeId;
use crate::node::Node;

/// Offset (parent coordinates) applied by the duplicate command.
pub const DUPLICATE_OFFSET: Point = Point::new(64.0, 64.0);

/// Copies the nodes `ids` (siblings in the transaction's container) into the supplied edit,
/// applying `offset` in parent coordinates; the copies get fresh ids throughout and become the
/// selection. Returns the new ids in the order of `ids`.
pub fn duplicate_nodes(
    ids: &[NodeId],
    tx: &mut Tx<'_>,
    selection: &mut Selection,
    offset: Point,
) -> Result<Vec<NodeId>, HistoryError> {
    let clones: Vec<Node> = ids
        .iter()
        .filter_map(|&id| tx.doc().node(id))
        .map(|node| {
            let mut clone = node.copy_with(None, true);
            clone.set_origin(node.origin() + offset);
            clone
        })
        .collect();
    let new_ids = clones.into_iter().map(|clone| tx.add(clone, None)).collect::<Result<Vec<_>, _>>()?;
    selection.set_selection(new_ids.iter().copied());
    Ok(new_ids)
}

/// Selected sibling nodes in paint order (not selection order); empty when the selection is
/// empty, stale, or spans several containers.
fn duplicable_selection(doc: &Document, selection: &Selection) -> Vec<NodeId> {
    let Some((container, ids)) = selected_siblings(doc, selection) else { return Vec::new() };
    let children = doc.children(container).unwrap_or_default();
    children.iter().map(Node::id).filter(|id| ids.contains(id)).collect()
}

pub fn can_duplicate_selected_nodes(doc: &Document, selection: &Selection) -> bool {
    !duplicable_selection(doc, selection).is_empty()
}

/// Duplicates sibling nodes in one edit, offset 64 canvas units right and down.
///
/// The caller must first cancel any in-flight interaction (it can restore group children or
/// remove transient drag copies) so the originals are in their committed positions.
pub fn duplicate_selected_nodes(
    doc: &mut Document,
    history: &mut History,
    selection: &mut Selection,
) -> Result<bool, HistoryError> {
    let ids = duplicable_selection(doc, selection);
    let Some(&first) = ids.first() else { return Ok(false) };
    let container = doc.parent_of(first).flatten();
    let mut new_selection = Selection::new();
    history.run(doc, "Duplicate selection", container, |tx| {
        duplicate_nodes(&ids, tx, &mut new_selection, DUPLICATE_OFFSET).map(|_| ())
    })?;
    *selection = new_selection;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::test_util::{rect_at, snapshot};
    use crate::group::Group;

    fn subtree_ids(node: &Node) -> Vec<NodeId> {
        node.subtree().iter().map(|n| n.id()).collect()
    }

    #[test]
    fn duplicates_sibling_trees_in_paint_order_with_fresh_ids_and_one_edit() {
        let nested = Group::new(Point::new(30.0, 40.0), vec![rect_at(10.0, 20.0)]);
        let parent = Group::new(Point::new(300.0, 400.0), vec![nested.into(), rect_at(100.0, 200.0)]);
        let mut doc = Document::default();
        let pid = doc.insert(None, parent.into(), None).unwrap();
        let (nested_id, second_id) = {
            let kids = doc.children(Some(pid)).unwrap();
            (kids[0].id(), kids[1].id())
        };
        let nested_origin = doc.node(nested_id).unwrap().origin();
        let second_origin = doc.node(second_id).unwrap().origin();
        let (mut history, mut sel) = (History::new(), Selection::new());
        let before = snapshot(&doc);
        sel.set_selection([second_id, nested_id]);

        assert!(duplicate_selected_nodes(&mut doc, &mut history, &mut sel).unwrap());

        let kids: Vec<Node> = doc.children(Some(pid)).unwrap().to_vec();
        let clones = &kids[2..];
        assert_eq!(clones.len(), 2);
        assert_eq!(sel.selected_node_ids(), clones.iter().map(Node::id).collect::<Vec<_>>().as_slice());
        assert_eq!(clones[0].origin(), nested_origin + DUPLICATE_OFFSET);
        assert_eq!(clones[1].origin(), second_origin + DUPLICATE_OFFSET);
        let copied_child = &clones[0].as_group().unwrap().children[0];
        assert_eq!(copied_child.origin(), Point::new(10.0, 20.0));
        let original_child = &kids[0].as_group().unwrap().children[0];
        assert_eq!(copied_child.as_feature().unwrap().kind, original_child.as_feature().unwrap().kind);
        assert_eq!(copied_child.as_feature().unwrap().size, original_child.as_feature().unwrap().size);
        let all = subtree_ids(doc.node(pid).unwrap());
        let unique: std::collections::HashSet<_> = all.iter().collect();
        assert_eq!(unique.len(), all.len());
        let after = snapshot(&doc);

        history.undo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), before);
        assert!(!history.can_undo());
        history.redo(&mut doc).unwrap();
        assert_eq!(snapshot(&doc), after);
    }

    #[test]
    fn empty_stale_ancestor_descendant_and_mixed_parent_selections_are_no_ops() {
        let mut doc = Document::default();
        let group = doc.insert(None, Group::new(Point::ZERO, vec![rect_at(0.0, 0.0)]).into(), None).unwrap();
        let child = doc.children(Some(group)).unwrap()[0].id();
        let sibling = doc.insert(None, rect_at(200.0, 0.0), None).unwrap();
        let (mut history, mut sel) = (History::new(), Selection::new());
        let before = snapshot(&doc);
        let cases: [Vec<NodeId>; 4] =
            [vec![], vec![NodeId(999)], vec![child, group], vec![child, sibling]];
        for ids in cases {
            sel.set_selection(ids);
            assert!(!can_duplicate_selected_nodes(&doc, &sel));
            assert!(!duplicate_selected_nodes(&mut doc, &mut history, &mut sel).unwrap());
            assert_eq!(snapshot(&doc), before);
            assert!(!history.can_undo());
        }
    }
}
