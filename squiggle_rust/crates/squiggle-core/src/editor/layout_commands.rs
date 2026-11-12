use super::history::{History, HistoryError};
use crate::document::Document;
use crate::ids::NodeId;

/// Runs `layout` as one undoable "Layout selection" edit. `ids` must be siblings sharing one
/// container; `layout` should only mutate those nodes (e.g. via `node_layout::align_nodes`).
pub fn apply_node_layout(
    doc: &mut Document,
    history: &mut History,
    ids: &[NodeId],
    layout: impl FnOnce(&mut Document),
) -> Result<(), HistoryError> {
    let Some(&first) = ids.first() else { return Ok(()) };
    let container = doc.parent_of(first).ok_or(HistoryError::NotDirectChild(first))?;
    if let Some(&odd) = ids.iter().find(|&&id| doc.parent_of(id) != Some(container)) {
        return Err(HistoryError::Custom(format!("Selected nodes must share a container (node {})", odd.0)));
    }
    history.run(doc, "Layout selection", container, |tx| {
        tx.watch(ids)?;
        layout(tx.doc_mut());
        Ok(())
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::test_util::{ids, rect_at};
    use crate::geom::Point;
    use crate::node_layout::{NodeAlignment, align_nodes};

    #[test]
    fn layout_is_one_undoable_edit() {
        let mut doc = Document::from_nodes([rect_at(0.0, 0.0), rect_at(30.0, 5.0)]);
        let mut history = History::new();
        let all = ids(&doc);
        apply_node_layout(&mut doc, &mut history, &all, |d| {
            let mut nodes: Vec<_> = all.iter().map(|&id| d.node(id).unwrap().clone()).collect();
            align_nodes(&mut nodes, NodeAlignment::Left);
            for n in nodes {
                let id = n.id();
                *d.node_mut(id).unwrap() = n;
            }
        })
        .unwrap();
        assert_eq!(doc.node(all[1]).unwrap().origin(), Point::new(0.0, 5.0));
        history.undo(&mut doc).unwrap();
        assert_eq!(doc.node(all[1]).unwrap().origin(), Point::new(30.0, 5.0));
    }

    #[test]
    fn mixed_containers_are_rejected() {
        let mut doc = Document::from_nodes([rect_at(0.0, 0.0)]);
        let g = doc.insert(None, crate::Group::new(Point::ZERO, vec![rect_at(0.0, 0.0)]).into(), None).unwrap();
        let child = doc.children(Some(g)).unwrap()[0].id();
        let root = doc.nodes()[0].id();
        let mut history = History::new();
        assert!(apply_node_layout(&mut doc, &mut history, &[root, child], |_| {}).is_err());
        assert!(!history.is_active());
    }
}
