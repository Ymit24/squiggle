//! How the select tool lets a node be resized (`resize_policy.dart`).

use crate::feature_kind::FeatureKind;
use crate::node::Node;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ResizePolicy {
    /// Whether the top and bottom handles are offered.
    pub vertical_sides: bool,
    /// Whether corner drags keep the aspect ratio without Shift.
    pub lock_corner_aspect: bool,
}

impl ResizePolicy {
    pub const FREE: ResizePolicy = ResizePolicy { vertical_sides: true, lock_corner_aspect: false };

    /// Text height follows its contents: sides only change the wrap width and corners scale it
    /// uniformly.
    pub const TEXT: ResizePolicy = ResizePolicy { vertical_sides: false, lock_corner_aspect: true };

    /// Groups holding text scale it uniformly from corners too. A free corner would flip that text
    /// between scaling and reflowing whenever the drag crossed the starting height.
    pub const CONTAINS_TEXT: ResizePolicy = ResizePolicy { vertical_sides: true, lock_corner_aspect: true };

    pub fn of(node: &Node) -> ResizePolicy {
        match node {
            Node::Feature(f) if matches!(f.kind, FeatureKind::Text(_)) => Self::TEXT,
            Node::Group(g) if g.children.iter().any(|c| Self::of(c).lock_corner_aspect) => Self::CONTAINS_TEXT,
            _ => Self::FREE,
        }
    }
}
