use crate::feature::Feature;
use crate::geom::{Point, Rect};
use crate::group::Group;
use crate::ids::{NO_ID, NodeId};
use crate::paint::Painter;
use serde_json::Value;

/// A document tree node. Core code is agnostic of feature kinds; see `FeatureKind`.
#[derive(Clone, Debug, PartialEq)]
pub enum Node {
    Feature(Feature),
    Group(Group),
}

impl From<Feature> for Node {
    fn from(f: Feature) -> Self {
        Node::Feature(f)
    }
}

impl From<Group> for Node {
    fn from(g: Group) -> Self {
        Node::Group(g)
    }
}

impl Node {
    pub fn from_json(json: &Value) -> Result<Self, String> {
        match json.get("type").and_then(Value::as_str) {
            Some("feature") => Feature::from_json(json).map(Node::Feature),
            Some("group") => Group::from_json(json).map(Node::Group),
            other => Err(format!("Unknown node type: {other:?}")),
        }
    }

    pub fn to_json(&self) -> Value {
        match self {
            Node::Feature(f) => f.to_json(),
            Node::Group(g) => g.to_json(),
        }
    }

    pub fn id(&self) -> NodeId {
        match self {
            Node::Feature(f) => f.id,
            Node::Group(g) => g.id,
        }
    }

    pub fn set_id(&mut self, id: NodeId) {
        match self {
            Node::Feature(f) => f.id = id,
            Node::Group(g) => g.id = id,
        }
    }

    /// Relative to the parent container.
    pub fn origin(&self) -> Point {
        match self {
            Node::Feature(f) => f.origin,
            Node::Group(g) => g.origin,
        }
    }

    pub fn set_origin(&mut self, origin: Point) {
        match self {
            Node::Feature(f) => f.origin = origin,
            Node::Group(g) => g.origin = origin,
        }
    }

    pub fn as_feature(&self) -> Option<&Feature> {
        if let Node::Feature(f) = self { Some(f) } else { None }
    }

    pub fn as_feature_mut(&mut self) -> Option<&mut Feature> {
        if let Node::Feature(f) = self { Some(f) } else { None }
    }

    pub fn as_group(&self) -> Option<&Group> {
        if let Node::Group(g) = self { Some(g) } else { None }
    }

    pub fn as_group_mut(&mut self) -> Option<&mut Group> {
        if let Node::Group(g) = self { Some(g) } else { None }
    }

    /// Bounds in the parent container's coordinate space.
    pub fn local_bounds(&self) -> Rect {
        match self {
            Node::Feature(f) => f.local_bounds(),
            Node::Group(g) => g.local_bounds(),
        }
    }

    pub fn center(&self) -> Point {
        self.local_bounds().center()
    }

    /// Union of `nodes` bounds in their shared parent space; `Rect::ZERO` when empty.
    pub fn local_bounds_of_nodes(nodes: &[Node]) -> Rect {
        Rect::union_all(&nodes.iter().map(Node::local_bounds).collect::<Vec<_>>())
    }

    /// `point` is in the parent container's space.
    pub fn hit_test(&self, point: Point) -> bool {
        match self {
            Node::Feature(f) => f.hit_test(point),
            Node::Group(g) => g.hit_test(point),
        }
    }

    pub fn intersects_rect(&self, rect: &Rect) -> bool {
        match self {
            Node::Feature(f) => f.intersects_rect(rect),
            Node::Group(g) => g.intersects_rect(rect),
        }
    }

    /// Resizes to `bounds` (parent space). Content-sized nodes may land near rather than on it.
    pub fn resize(&mut self, bounds: Rect) {
        match self {
            Node::Feature(f) => f.resize(bounds),
            Node::Group(g) => g.resize(bounds),
        }
    }

    pub fn paint(&self, painter: &mut Painter) {
        match self {
            Node::Feature(f) => f.paint(painter),
            Node::Group(g) => g.paint(painter),
        }
    }

    /// Deep copy keeping ids (`reset_ids == false`) or clearing them all to `NO_ID`
    /// (`reset_ids == true`), as for duplicates and paste.
    pub fn copy_with(&self, id: Option<NodeId>, reset_ids: bool) -> Node {
        let id = if reset_ids { Some(NO_ID) } else { id };
        match self {
            Node::Feature(f) => Node::Feature(f.copy_with_id(id)),
            Node::Group(g) => Node::Group(g.copy_with(id, reset_ids)),
        }
    }

    /// This node and all descendants, depth-first, parents first.
    pub fn subtree(&self) -> Vec<&Node> {
        let mut out = vec![self];
        if let Node::Group(g) = self {
            for c in &g.children {
                out.extend(c.subtree());
            }
        }
        out
    }
}
