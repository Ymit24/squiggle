use crate::document::Document;
use crate::ids::{Container, NodeId};

/// Ordered set of selected node ids, top-most selection last.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Selection {
    ids: Vec<NodeId>,
}

impl Selection {
    pub fn new() -> Self {
        Selection::default()
    }

    pub fn selected_node_ids(&self) -> &[NodeId] {
        &self.ids
    }

    pub fn is_empty(&self) -> bool {
        self.ids.is_empty()
    }

    pub fn is_not_empty(&self) -> bool {
        !self.ids.is_empty()
    }

    pub fn len(&self) -> usize {
        self.ids.len()
    }

    /// The most recently selected id.
    pub fn topmost(&self) -> Option<NodeId> {
        self.ids.last().copied()
    }

    /// Selects `id`, moving it to the top if already selected.
    pub fn select_node(&mut self, id: NodeId) {
        self.ids.retain(|i| *i != id);
        self.ids.push(id);
    }

    pub fn deselect_node(&mut self, id: NodeId) {
        self.ids.retain(|i| *i != id);
    }

    pub fn clear_selection(&mut self) {
        self.ids.clear();
    }

    /// Replaces the selection, keeping the given order verbatim.
    pub fn set_selection(&mut self, ids: impl IntoIterator<Item = NodeId>) {
        self.ids = ids.into_iter().collect();
    }

    pub fn is_node_selected(&self, id: NodeId) -> bool {
        self.ids.contains(&id)
    }
}

/// The container shared by every selected node and the selected ids (deduplicated, selection
/// order). `None` when nothing is selected, any id is stale, or the nodes have different parents.
pub fn selected_siblings(doc: &Document, selection: &Selection) -> Option<(Container, Vec<NodeId>)> {
    let mut ids: Vec<NodeId> = Vec::new();
    for &id in selection.selected_node_ids() {
        if !ids.contains(&id) {
            ids.push(id);
        }
    }
    let container = doc.parent_of(*ids.first()?)?;
    let same_parent = ids.iter().all(|&id| doc.parent_of(id) == Some(container));
    same_parent.then_some((container, ids))
}

#[cfg(test)]
mod tests {
    use super::*;

    const A: NodeId = NodeId(0);
    const B: NodeId = NodeId(1);

    #[test]
    fn can_select_and_deselect() {
        let mut s = Selection::new();
        s.select_node(A);
        assert_eq!(s.selected_node_ids(), &[A]);
        s.deselect_node(A);
        assert!(s.is_empty());
    }

    #[test]
    fn can_clear_selection() {
        let mut s = Selection::new();
        s.select_node(A);
        s.select_node(B);
        s.clear_selection();
        assert!(s.selected_node_ids().is_empty());
    }

    #[test]
    fn does_not_duplicate_on_select() {
        let mut s = Selection::new();
        s.select_node(A);
        s.select_node(A);
        assert_eq!(s.len(), 1);
    }

    #[test]
    fn reselecting_moves_to_top() {
        let mut s = Selection::new();
        s.select_node(A);
        s.select_node(B);
        s.select_node(A);
        assert_eq!(s.selected_node_ids(), &[B, A]);
        assert_eq!(s.topmost(), Some(A));
    }

    #[test]
    fn can_check_if_selected() {
        let mut s = Selection::new();
        s.select_node(A);
        assert!(s.is_node_selected(A));
        assert!(!s.is_node_selected(B));
    }

    #[test]
    fn tracks_each_mutation_in_order() {
        let mut s = Selection::new();
        let mut seen = Vec::new();
        s.select_node(A);
        seen.push(s.selected_node_ids().to_vec());
        s.select_node(B);
        seen.push(s.selected_node_ids().to_vec());
        s.deselect_node(A);
        seen.push(s.selected_node_ids().to_vec());
        s.clear_selection();
        seen.push(s.selected_node_ids().to_vec());
        assert_eq!(seen, vec![vec![A], vec![A, B], vec![B], vec![]]);
    }
}
