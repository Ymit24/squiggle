use crate::geom::{Point, Rect};
use crate::ids::{NO_ID, NodeId};
use crate::node::Node;
use crate::paint::Painter;
use serde_json::{Value, json};

/// An ordered collection of child nodes positioned relative to `origin`.
#[derive(Clone, Debug, PartialEq)]
pub struct Group {
    pub id: NodeId,
    pub origin: Point,
    pub children: Vec<Node>,
}

impl Group {
    pub fn new(origin: Point, children: Vec<Node>) -> Self {
        Group { id: NO_ID, origin, children }
    }

    pub fn from_json(json: &Value) -> Result<Self, String> {
        let num = |k: &str| json.get(k).and_then(Value::as_f64).ok_or(format!("group.{k}"));
        let children = json
            .get("children")
            .and_then(Value::as_array)
            .ok_or("group.children")?
            .iter()
            .map(Node::from_json)
            .collect::<Result<Vec<_>, _>>()?;
        Ok(Group {
            id: NodeId(json.get("id").and_then(Value::as_u64).ok_or("group.id")? as u32),
            origin: Point::new(num("originX")?, num("originY")?),
            children,
        })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "type": "group",
            "id": self.id.0,
            "originX": self.origin.x,
            "originY": self.origin.y,
            "children": self.children.iter().map(Node::to_json).collect::<Vec<_>>(),
        })
    }

    /// Bounds in the parent's space (children bounds shifted by `origin`).
    pub fn local_bounds(&self) -> Rect {
        Node::local_bounds_of_nodes(&self.children).shift(self.origin)
    }

    pub fn intersects_rect(&self, rect: &Rect) -> bool {
        self.local_bounds().overlaps(rect)
    }

    pub fn hit_test(&self, point: Point) -> bool {
        self.local_bounds().contains(point)
    }

    pub fn paint(&self, painter: &mut Painter) {
        painter.translated(self.origin, |p| {
            for child in &self.children {
                child.paint(p);
            }
        });
    }

    /// Scales children so their union fills `bounds`, then moves the group there.
    pub fn resize(&mut self, bounds: Rect) {
        let child_bounds = Node::local_bounds_of_nodes(&self.children);
        let sx = if child_bounds.width() == 0.0 { 1.0 } else { bounds.width() / child_bounds.width() };
        let sy = if child_bounds.height() == 0.0 { 1.0 } else { bounds.height() / child_bounds.height() };
        for child in &mut self.children {
            let cur = child.local_bounds();
            child.resize(Rect::from_ltwh(
                (cur.left - child_bounds.left) * sx,
                (cur.top - child_bounds.top) * sy,
                cur.width() * sx,
                cur.height() * sy,
            ));
        }
        self.origin = bounds.top_left();
    }

    /// Deep copy. With `reset_ids`, the copy and all descendants get `NO_ID`.
    pub fn copy_with(&self, id: Option<NodeId>, reset_ids: bool) -> Group {
        Group {
            id: id.unwrap_or(self.id),
            origin: self.origin,
            children: self.children.iter().map(|c| c.copy_with(None, reset_ids)).collect(),
        }
    }
}
