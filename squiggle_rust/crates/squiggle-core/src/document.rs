use crate::geom::{Point, Rect};
use crate::ids::{Container, NO_ID, NodeId};
use crate::node::Node;
use crate::session::DocumentSession;
use serde_json::{Value, json};
use std::collections::HashSet;

pub const FORMAT_VERSION: u64 = 2;

/// Editable document tree with document-wide node ids.
///
/// Root nodes are stored in paint order; descendants belong to their group's child list. A
/// [`Container`] names where children live: `None` is the root, `Some(id)` a group. Undo/redo
/// bookkeeping lives in the editor's history layer.
#[derive(Clone, Debug, PartialEq)]
pub struct Document {
    pub name: String,
    pub session: DocumentSession,
    nodes: Vec<Node>,
    next_id: u32,
}

impl Default for Document {
    fn default() -> Self {
        Document::new("Untitled")
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum DocumentError {
    DuplicateId(NodeId),
    NoSuchContainer(Container),
    IndexOutOfRange { index: usize, len: usize },
    /// Order passed to `reorder` was not a permutation of the children.
    BadOrder,
    /// Inserting a group into itself or its own descendant.
    Cycle,
}

impl std::fmt::Display for DocumentError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for DocumentError {}

fn find<'a>(nodes: &'a [Node], id: NodeId) -> Option<&'a Node> {
    for n in nodes {
        if n.id() == id {
            return Some(n);
        }
        if let Node::Group(g) = n
            && let Some(found) = find(&g.children, id)
        {
            return Some(found);
        }
    }
    None
}

fn find_mut<'a>(nodes: &'a mut [Node], id: NodeId) -> Option<&'a mut Node> {
    for n in nodes {
        if n.id() == id {
            return Some(n);
        }
        if let Node::Group(g) = n
            && let Some(found) = find_mut(&mut g.children, id)
        {
            return Some(found);
        }
    }
    None
}

impl Document {
    pub fn new(name: impl Into<String>) -> Self {
        Document { name: name.into(), session: DocumentSession::default(), nodes: Vec::new(), next_id: 1 }
    }

    pub fn from_nodes(nodes: impl IntoIterator<Item = Node>) -> Self {
        let mut doc = Document::default();
        for n in nodes {
            doc.insert(None, n, None).expect("fresh ids are unique");
        }
        doc
    }

    // --- persistence -------------------------------------------------------------------

    pub fn from_json(json: &Value) -> Result<Self, String> {
        if json.get("version").and_then(Value::as_u64) != Some(FORMAT_VERSION) {
            return Err(format!("Unsupported document version: {:?}", json.get("version")));
        }
        let mut doc = Document::new(json.get("name").and_then(Value::as_str).unwrap_or("Untitled"));
        if let Some(session) = json.get("session").filter(|s| s.is_object()) {
            doc.session = DocumentSession::from_json(session)?;
        }
        for n in json.get("nodes").and_then(Value::as_array).ok_or("nodes")? {
            doc.insert(None, Node::from_json(n)?, None).map_err(|e| e.to_string())?;
        }
        Ok(doc)
    }

    pub fn decode(text: &str) -> Result<Self, String> {
        Self::from_json(&serde_json::from_str(text).map_err(|e| e.to_string())?)
    }

    pub fn to_json(&self) -> Value {
        json!({
            "version": FORMAT_VERSION,
            "name": self.name,
            "nodes": self.nodes.iter().map(Node::to_json).collect::<Vec<_>>(),
            "session": self.session.to_json(),
        })
    }

    pub fn encode(&self) -> String {
        self.to_json().to_string()
    }

    // --- lookup --------------------------------------------------------------------------

    /// Root nodes in paint order.
    pub fn nodes(&self) -> &[Node] {
        &self.nodes
    }

    pub fn next_id(&self) -> u32 {
        self.next_id
    }

    pub fn generate_id(&mut self) -> NodeId {
        let id = NodeId(self.next_id);
        self.next_id += 1;
        id
    }

    pub fn node(&self, id: NodeId) -> Option<&Node> {
        find(&self.nodes, id)
    }

    pub fn node_mut(&mut self, id: NodeId) -> Option<&mut Node> {
        find_mut(&mut self.nodes, id)
    }

    pub fn require_node(&self, id: NodeId) -> &Node {
        self.node(id).unwrap_or_else(|| panic!("Node with id {} does not exist", id.0))
    }

    pub fn feature(&self, id: NodeId) -> Option<&crate::feature::Feature> {
        self.node(id).and_then(Node::as_feature)
    }

    pub fn feature_mut(&mut self, id: NodeId) -> Option<&mut crate::feature::Feature> {
        self.node_mut(id).and_then(Node::as_feature_mut)
    }

    /// Children of `container` in paint order; `None` when the group does not exist.
    pub fn children(&self, container: Container) -> Option<&[Node]> {
        match container {
            None => Some(&self.nodes),
            Some(id) => self.node(id).and_then(Node::as_group).map(|g| g.children.as_slice()),
        }
    }

    pub fn children_mut(&mut self, container: Container) -> Option<&mut Vec<Node>> {
        match container {
            None => Some(&mut self.nodes),
            Some(id) => self.node_mut(id).and_then(Node::as_group_mut).map(|g| &mut g.children),
        }
    }

    /// Direct child of `container` with `id`.
    pub fn child_by_id(&self, container: Container, id: NodeId) -> Option<&Node> {
        self.children(container)?.iter().find(|n| n.id() == id)
    }

    /// Container holding `id`; `None` when the node is not in the document.
    pub fn parent_of(&self, id: NodeId) -> Option<Container> {
        fn walk(nodes: &[Node], parent: Container, id: NodeId) -> Option<Container> {
            for n in nodes {
                if n.id() == id {
                    return Some(parent);
                }
                if let Node::Group(g) = n
                    && let Some(found) = walk(&g.children, Some(n.id()), id)
                {
                    return Some(found);
                }
            }
            None
        }
        walk(&self.nodes, None, id)
    }

    /// Sum of group origins from the root down to and including `container`.
    pub fn global_origin(&self, container: Container) -> Point {
        let mut origin = Point::ZERO;
        let mut current = container;
        while let Some(id) = current {
            let Some(node) = self.node(id) else { break };
            origin = origin + node.origin();
            current = self.parent_of(id).flatten();
        }
        origin
    }

    pub fn node_global_origin(&self, id: NodeId) -> Point {
        let Some(node) = self.node(id) else { return Point::ZERO };
        node.origin() + self.global_origin(self.parent_of(id).flatten())
    }

    /// Bounds of `id` in world space.
    pub fn global_bounds(&self, id: NodeId) -> Option<Rect> {
        let node = self.node(id)?;
        let parent = self.parent_of(id)?;
        Some(node.local_bounds().shift(self.global_origin(parent)))
    }

    /// Top-most root node containing `world_point`.
    pub fn node_at_point(&self, world_point: Point) -> Option<&Node> {
        self.nodes.iter().rev().find(|n| n.hit_test(world_point))
    }

    /// Root nodes whose bounds overlap `world_bounds`.
    pub fn nodes_in_bounds(&self, world_bounds: &Rect) -> Vec<&Node> {
        self.nodes.iter().filter(|n| n.local_bounds().overlaps(world_bounds)).collect()
    }

    // --- mutation -------------------------------------------------------------------------

    /// Inserts `node` (a whole subtree) into `container` at `index` (default: end). Nodes with
    /// `NO_ID` get fresh ids; the id counter moves past any explicit ids.
    pub fn insert(
        &mut self,
        container: Container,
        mut node: Node,
        index: Option<usize>,
    ) -> Result<NodeId, DocumentError> {
        let len = self.children(container).ok_or(DocumentError::NoSuchContainer(container))?.len();
        let position = index.unwrap_or(len);
        if position > len {
            return Err(DocumentError::IndexOutOfRange { index: position, len });
        }
        if let Some(cid) = container
            && node.subtree().iter().any(|n| n.id() == cid)
        {
            return Err(DocumentError::Cycle);
        }
        self.register_subtree(&mut node)?;
        let id = node.id();
        self.children_mut(container).expect("checked above").insert(position, node);
        Ok(id)
    }

    fn register_subtree(&mut self, root: &mut Node) -> Result<(), DocumentError> {
        let mut seen = HashSet::new();
        for n in root.subtree() {
            let id = n.id();
            if id == NO_ID {
                continue;
            }
            if self.node(id).is_some() || !seen.insert(id) {
                return Err(DocumentError::DuplicateId(id));
            }
        }
        if let Some(max) = seen.iter().map(|i| i.0).max() {
            self.next_id = self.next_id.max(max + 1);
        }
        fn assign(doc: &mut Document, node: &mut Node) {
            if node.id() == NO_ID {
                let id = doc.generate_id();
                node.set_id(id);
            }
            if let Node::Group(g) = node {
                for c in &mut g.children {
                    assign(doc, c);
                }
            }
        }
        assign(self, root);
        Ok(())
    }

    /// Removes the direct children of `container` listed in `ids`; returns the removed nodes in
    /// their former order.
    pub fn remove_all(&mut self, container: Container, ids: &[NodeId]) -> Vec<Node> {
        let Some(children) = self.children_mut(container) else { return Vec::new() };
        let set: HashSet<NodeId> = ids.iter().copied().collect();
        let mut removed = Vec::new();
        let mut kept = Vec::with_capacity(children.len());
        for n in children.drain(..) {
            if set.contains(&n.id()) { removed.push(n) } else { kept.push(n) }
        }
        *children = kept;
        removed
    }

    pub fn remove(&mut self, id: NodeId) -> Option<Node> {
        let parent = self.parent_of(id)?;
        self.remove_all(parent, &[id]).pop()
    }

    /// Reorders `container`'s children; `order` must list every child exactly once.
    pub fn reorder(&mut self, container: Container, order: &[NodeId]) -> Result<(), DocumentError> {
        let children = self.children_mut(container).ok_or(DocumentError::NoSuchContainer(container))?;
        let unique: HashSet<_> = order.iter().collect();
        if order.len() != children.len()
            || unique.len() != order.len()
            || !order.iter().all(|id| children.iter().any(|c| c.id() == *id))
        {
            return Err(DocumentError::BadOrder);
        }
        let mut old: Vec<Option<Node>> = children.drain(..).map(Some).collect();
        for id in order {
            let slot = old.iter_mut().find(|n| n.as_ref().is_some_and(|n| n.id() == *id)).unwrap();
            children.push(slot.take().unwrap());
        }
        Ok(())
    }

    /// Replaces this document's contents with a copy of `other` (ids preserved).
    pub fn replace_from(&mut self, other: &Document) {
        *self = other.clone();
    }

    /// Whole-document paint into a display list (world space).
    pub fn paint(&self) -> crate::paint::DisplayList {
        let mut painter = crate::paint::Painter::new();
        for n in &self.nodes {
            n.paint(&mut painter);
        }
        painter.commands
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::feature::Feature;
    use crate::feature_kind::FeatureKind;
    use crate::geom::Size;
    use crate::group::Group;

    fn feat(x: f64, y: f64) -> Node {
        Feature::new(Point::new(x, y), Size::new(10.0, 10.0), FeatureKind::default()).into()
    }

    #[test]
    fn assigns_ids_and_tracks_counter() {
        let mut doc = Document::default();
        let a = doc.insert(None, feat(0.0, 0.0), None).unwrap();
        let b = doc.insert(None, feat(5.0, 0.0), None).unwrap();
        assert_eq!((a, b), (NodeId(1), NodeId(2)));
        let mut explicit = feat(0.0, 0.0);
        explicit.set_id(NodeId(10));
        doc.insert(None, explicit, None).unwrap();
        assert_eq!(doc.generate_id(), NodeId(11));
    }

    #[test]
    fn rejects_duplicate_ids() {
        let mut doc = Document::default();
        let id = doc.insert(None, feat(0.0, 0.0), None).unwrap();
        let mut dup = feat(1.0, 1.0);
        dup.set_id(id);
        assert_eq!(doc.insert(None, dup, None), Err(DocumentError::DuplicateId(id)));
    }

    #[test]
    fn groups_nest_and_resolve_origins() {
        let mut doc = Document::default();
        let g = doc
            .insert(None, Group::new(Point::new(100.0, 50.0), vec![feat(1.0, 2.0)]).into(), None)
            .unwrap();
        let child = doc.children(Some(g)).unwrap()[0].id();
        assert_eq!(doc.parent_of(child), Some(Some(g)));
        assert_eq!(doc.global_origin(Some(g)), Point::new(100.0, 50.0));
        assert_eq!(doc.global_bounds(child).unwrap().top_left(), Point::new(101.0, 52.0));
    }

    #[test]
    fn reorder_requires_permutation() {
        let mut doc = Document::default();
        let a = doc.insert(None, feat(0.0, 0.0), None).unwrap();
        let b = doc.insert(None, feat(0.0, 0.0), None).unwrap();
        assert!(doc.reorder(None, &[a]).is_err());
        doc.reorder(None, &[b, a]).unwrap();
        assert_eq!(doc.nodes()[0].id(), b);
    }

    #[test]
    fn json_round_trip() {
        let mut doc = Document::new("Sketch");
        doc.insert(None, Group::new(Point::ZERO, vec![feat(1.0, 2.0)]).into(), None).unwrap();
        let again = Document::decode(&doc.encode()).unwrap();
        assert_eq!(again.name, "Sketch");
        assert_eq!(again.nodes().len(), 1);
    }

    #[test]
    fn unsupported_version_is_error() {
        assert!(Document::decode(r#"{"version":1,"nodes":[]}"#).is_err());
    }
}
