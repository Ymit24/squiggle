//! Snapshot-based document edits: [`Transaction`] records, [`Commit`] replays.
//!
//! A transaction is scoped to one container (`None` = document root). It snapshots the container's
//! affected immediate children (with their subtrees) before their first mutation. Group/ungroup
//! within that scope; transfers between existing containers need separate edits.

use crate::document::{Document, DocumentError};
use crate::ids::{Container, NodeId};
use crate::node::Node;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum HistoryError {
    /// The edit was already committed or cancelled.
    Closed,
    NotDirectChild(NodeId),
    NoSuchContainer(Container),
    /// The container of a replayed commit no longer exists.
    ContainerGone(NodeId),
    AlreadyActive,
    NoActiveTransaction,
    ActiveTransaction,
    NothingToUndo,
    NothingToRedo,
    Document(DocumentError),
    /// Error raised by an editing closure.
    Custom(String),
}

impl std::fmt::Display for HistoryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for HistoryError {}

impl From<DocumentError> for HistoryError {
    fn from(e: DocumentError) -> Self {
        HistoryError::Document(e)
    }
}

/// Saved states of direct children; `None` means "absent".
type States = Vec<(NodeId, Option<Node>)>;

/// Snapshot of `node` without transient state (`Feature::hide_label`), so replay never restores it.
fn snapshot(node: &Node) -> Node {
    let mut copy = node.clone();
    fn clear(node: &mut Node) {
        match node {
            Node::Feature(f) => f.hide_label = false,
            Node::Group(g) => g.children.iter_mut().for_each(clear),
        }
    }
    clear(&mut copy);
    copy
}

/// Equality of persisted state (ignores transient fields such as `hide_label`).
fn same_state(a: &Option<Node>, b: &Option<Node>) -> bool {
    match (a, b) {
        (None, None) => true,
        (Some(a), Some(b)) => a.to_json() == b.to_json(),
        _ => false,
    }
}

/// One in-progress document edit. All methods take the document explicitly; see [`Tx`] for a
/// handle that carries it.
#[derive(Debug)]
pub struct Transaction {
    label: String,
    container: Container,
    before: States,
    order_before: Option<Vec<NodeId>>,
    open: bool,
}

impl Transaction {
    pub fn new(doc: &Document, label: impl Into<String>, container: Container) -> Result<Self, HistoryError> {
        if doc.children(container).is_none() {
            return Err(HistoryError::NoSuchContainer(container));
        }
        Ok(Transaction { label: label.into(), container, before: Vec::new(), order_before: None, open: true })
    }

    pub fn label(&self) -> &str {
        &self.label
    }

    pub fn container(&self) -> Container {
        self.container
    }

    pub fn is_open(&self) -> bool {
        self.open
    }

    fn ensure_open(&self) -> Result<(), HistoryError> {
        if self.open { Ok(()) } else { Err(HistoryError::Closed) }
    }

    fn watch_order(&mut self, doc: &Document) {
        if self.order_before.is_none() {
            self.order_before = Some(Self::capture_order(doc, self.container));
        }
    }

    fn capture_order(doc: &Document, container: Container) -> Vec<NodeId> {
        doc.children(container).map(|c| c.iter().map(Node::id).collect()).unwrap_or_default()
    }

    fn remember(&mut self, id: NodeId, state: impl FnOnce() -> Option<Node>) {
        if !self.before.iter().any(|(i, _)| *i == id) {
            self.before.push((id, state()));
        }
    }

    /// Captures each existing direct child before its first mutation.
    pub fn watch(&mut self, doc: &Document, ids: &[NodeId]) -> Result<(), HistoryError> {
        self.ensure_open()?;
        for &id in ids {
            let node = doc.child_by_id(self.container, id).ok_or(HistoryError::NotDirectChild(id))?;
            self.remember(id, || Some(snapshot(node)));
        }
        Ok(())
    }

    /// Captures the node, then applies `change`.
    pub fn update<R>(
        &mut self,
        doc: &mut Document,
        id: NodeId,
        change: impl FnOnce(&mut Node) -> R,
    ) -> Result<R, HistoryError> {
        self.watch(doc, &[id])?;
        let node = doc.node_mut(id).ok_or(HistoryError::NotDirectChild(id))?;
        Ok(change(node))
    }

    /// Adds a node (subtree) to the scoped container; returns its id.
    pub fn add(&mut self, doc: &mut Document, node: Node, index: Option<usize>) -> Result<NodeId, HistoryError> {
        self.ensure_open()?;
        self.watch_order(doc);
        let id = doc.insert(self.container, node, index)?;
        self.remember(id, || None);
        Ok(id)
    }

    /// Removes direct children; returns the removed nodes in their former order.
    pub fn remove_all(&mut self, doc: &mut Document, ids: &[NodeId]) -> Result<Vec<Node>, HistoryError> {
        self.ensure_open()?;
        let present: Vec<NodeId> =
            ids.iter().copied().filter(|id| doc.child_by_id(self.container, *id).is_some()).collect();
        if present.is_empty() {
            return Ok(Vec::new());
        }
        self.watch_order(doc);
        self.watch(doc, &present)?;
        Ok(doc.remove_all(self.container, &present))
    }

    /// Reorders the scoped container's immediate children (must list every child).
    pub fn reorder(&mut self, doc: &mut Document, ids: &[NodeId]) -> Result<(), HistoryError> {
        self.ensure_open()?;
        self.watch_order(doc);
        Ok(doc.reorder(self.container, ids)?)
    }

    /// Closes the edit and returns its change, or `None` when nothing changed.
    pub fn commit(&mut self, doc: &Document) -> Result<Option<Commit>, HistoryError> {
        self.ensure_open()?;
        let (mut before, mut after) = (Vec::new(), Vec::new());
        for (id, saved) in &self.before {
            let state = doc.child_by_id(self.container, *id).map(snapshot);
            if !same_state(saved, &state) {
                before.push((*id, saved.clone()));
                after.push((*id, state));
            }
        }
        let order_after = self.order_before.as_ref().map(|_| Self::capture_order(doc, self.container));
        let order_changed = self.order_before.is_some() && self.order_before != order_after;
        self.open = false;
        if before.is_empty() && !order_changed {
            return Ok(None);
        }
        let (order_before, order_after) =
            if order_changed { (self.order_before.take(), order_after) } else { (None, None) };
        Ok(Some(Commit {
            label: self.label.clone(),
            container: self.container,
            before,
            after,
            order_before,
            order_after,
        }))
    }

    /// Restores the document to its state before this edit.
    pub fn cancel(&mut self, doc: &mut Document) -> Result<(), HistoryError> {
        self.ensure_open()?;
        apply(doc, self.container, &self.before, self.order_before.as_deref())?;
        self.open = false;
        Ok(())
    }
}

/// An immutable, replayable document change.
#[derive(Clone, Debug)]
pub struct Commit {
    label: String,
    container: Container,
    before: States,
    after: States,
    order_before: Option<Vec<NodeId>>,
    order_after: Option<Vec<NodeId>>,
}

impl Commit {
    pub fn label(&self) -> &str {
        &self.label
    }

    pub fn container(&self) -> Container {
        self.container
    }

    pub fn affected_node_count(&self) -> usize {
        self.before.len()
    }

    pub fn changes_order(&self) -> bool {
        self.order_before.is_some()
    }

    pub fn undo(&self, doc: &mut Document) -> Result<(), HistoryError> {
        self.resolve(doc)?;
        apply(doc, self.container, &self.before, self.order_before.as_deref())
    }

    pub fn redo(&self, doc: &mut Document) -> Result<(), HistoryError> {
        self.resolve(doc)?;
        apply(doc, self.container, &self.after, self.order_after.as_deref())
    }

    fn resolve(&self, doc: &Document) -> Result<(), HistoryError> {
        match self.container {
            Some(id) if doc.children(self.container).is_none() => Err(HistoryError::ContainerGone(id)),
            _ => Ok(()),
        }
    }
}

/// Applies one saved side. Structural replay detaches outgoing subtrees first so
/// grouping/ungrouping can reuse descendant ids without collisions.
fn apply(doc: &mut Document, container: Container, states: &States, order: Option<&[NodeId]>) -> Result<(), HistoryError> {
    let Some(order) = order else { return restore_in_place(doc, container, states) };
    let ids: Vec<NodeId> = states.iter().map(|(id, _)| *id).collect();
    doc.remove_all(container, &ids);
    for node in states.iter().filter_map(|(_, s)| s.as_ref()) {
        doc.insert(container, node.clone(), None)?;
    }
    Ok(doc.reorder(container, order)?)
}

fn restore_in_place(doc: &mut Document, container: Container, states: &States) -> Result<(), HistoryError> {
    let children = doc.children_mut(container).ok_or(HistoryError::NoSuchContainer(container))?;
    for (id, state) in states {
        let Some(state) = state else { continue };
        if let Some(slot) = children.iter_mut().find(|n| n.id() == *id) {
            *slot = state.clone();
        }
    }
    Ok(())
}

/// A transaction paired with the document it edits, for ergonomic use inside closures.
pub struct Tx<'a> {
    tx: &'a mut Transaction,
    doc: &'a mut Document,
}

impl<'a> Tx<'a> {
    pub fn new(tx: &'a mut Transaction, doc: &'a mut Document) -> Self {
        Tx { tx, doc }
    }

    pub fn doc(&self) -> &Document {
        self.doc
    }

    /// Direct document access. Mutate only watched nodes of the scoped container.
    pub fn doc_mut(&mut self) -> &mut Document {
        self.doc
    }

    pub fn label(&self) -> &str {
        self.tx.label()
    }

    pub fn container(&self) -> Container {
        self.tx.container()
    }

    pub fn is_open(&self) -> bool {
        self.tx.is_open()
    }

    pub fn watch(&mut self, ids: &[NodeId]) -> Result<(), HistoryError> {
        self.tx.watch(self.doc, ids)
    }

    pub fn update<R>(&mut self, id: NodeId, change: impl FnOnce(&mut Node) -> R) -> Result<R, HistoryError> {
        self.tx.update(self.doc, id, change)
    }

    pub fn add(&mut self, node: impl Into<Node>, index: Option<usize>) -> Result<NodeId, HistoryError> {
        self.tx.add(self.doc, node.into(), index)
    }

    pub fn remove_all(&mut self, ids: &[NodeId]) -> Result<Vec<Node>, HistoryError> {
        self.tx.remove_all(self.doc, ids)
    }

    pub fn reorder(&mut self, ids: &[NodeId]) -> Result<(), HistoryError> {
        self.tx.reorder(self.doc, ids)
    }
}
