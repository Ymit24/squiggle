//! Align / distribute / center operations over sibling nodes (one shared coordinate space).

use crate::geom::{Point, Rect};
use crate::node::Node;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NodeAlignment {
    Left,
    CenterHorizontal,
    Right,
    Top,
    CenterVertical,
    Bottom,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NodeDistribution {
    Horizontal,
    Vertical,
}

fn translate(node: &mut Node, delta: Point) {
    node.set_origin(node.origin() + delta);
}

/// Aligns `nodes` within their selection bounds.
pub fn align_nodes(nodes: &mut [Node], alignment: NodeAlignment) {
    if nodes.len() < 2 {
        return;
    }
    let union = Node::local_bounds_of_nodes(nodes);
    for node in nodes {
        let b = node.local_bounds();
        let delta = match alignment {
            NodeAlignment::Left => Point::new(union.left - b.left, 0.0),
            NodeAlignment::Right => Point::new(union.right - b.right, 0.0),
            NodeAlignment::Top => Point::new(0.0, union.top - b.top),
            NodeAlignment::Bottom => Point::new(0.0, union.bottom - b.bottom),
            NodeAlignment::CenterHorizontal => Point::new(union.center().x - b.center().x, 0.0),
            NodeAlignment::CenterVertical => Point::new(0.0, union.center().y - b.center().y),
        };
        translate(node, delta);
    }
}

/// Evenly distributes `nodes` between the extremes.
pub fn distribute_nodes(nodes: &mut [Node], distribution: NodeDistribution) {
    if nodes.len() < 3 {
        return;
    }
    let horizontal = distribution == NodeDistribution::Horizontal;
    let mut entries: Vec<(usize, Rect)> = nodes.iter().enumerate().map(|(i, n)| (i, n.local_bounds())).collect();
    let lead = |r: &Rect| if horizontal { r.left } else { r.top };
    let extent = |r: &Rect| if horizontal { r.width() } else { r.height() };
    entries.sort_by(|a, b| lead(&a.1).total_cmp(&lead(&b.1)));

    let first = entries[0].1;
    let last = entries[entries.len() - 1].1;
    let total: f64 = entries.iter().map(|(_, r)| extent(r)).sum();
    let span = if horizontal { last.right - first.left } else { last.bottom - first.top };
    let gap = (span - total) / (entries.len() - 1) as f64;

    let mut current = lead(&first);
    for (index, bounds) in entries {
        let shift = current - lead(&bounds);
        translate(&mut nodes[index], if horizontal { Point::new(shift, 0.0) } else { Point::new(0.0, shift) });
        current += extent(&bounds) + gap;
    }
}

/// Moves the combined bounds to `target_center`, preserving relative positions. Nodes must share
/// a parent coordinate space; their ids are unchanged.
pub fn center_nodes_at(nodes: &mut [Node], target_center: Point) {
    if nodes.is_empty() {
        return;
    }
    let delta = target_center - Node::local_bounds_of_nodes(nodes).center();
    for node in nodes {
        translate(node, delta);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::document::Document;
    use crate::editor::test_util::rect_at;
    use crate::feature::Feature;
    use crate::feature_kind::FeatureKind;
    use crate::geom::Size;
    use crate::group::Group;
    use crate::ids::NodeId;

    fn rects(origins: &[(f64, f64)]) -> Vec<Node> {
        let doc = Document::from_nodes(origins.iter().map(|&(x, y)| rect_at(x, y)));
        doc.nodes().to_vec()
    }

    fn origins(nodes: &[Node]) -> Vec<Point> {
        nodes.iter().map(Node::origin).collect()
    }

    #[test]
    fn centering_preserves_group_contents_relative_positions_and_ids() {
        let mut child = Feature::new(Point::new(5.0, 10.0), Size::new(20.0, 30.0), FeatureKind::default());
        child.id = NodeId(2);
        let mut group = Group::new(Point::new(100.0, 200.0), vec![child.clone().into()]);
        group.id = NodeId(1);
        let mut sibling = Feature::new(Point::new(200.0, 300.0), Size::new(40.0, 50.0), FeatureKind::default());
        sibling.id = NodeId(3);
        let relative = sibling.origin - group.origin;
        let mut nodes: Vec<Node> = vec![group.into(), sibling.into()];

        center_nodes_at(&mut nodes, Point::new(500.0, 400.0));

        assert_eq!(Node::local_bounds_of_nodes(&nodes).center(), Point::new(500.0, 400.0));
        assert_eq!(nodes[1].origin() - nodes[0].origin(), relative);
        let g = nodes[0].as_group().unwrap();
        assert_eq!(g.children, vec![Node::from(child)]);
        assert_eq!((nodes[0].id(), nodes[1].id()), (NodeId(1), NodeId(3)));
    }

    #[test]
    fn align_does_nothing_for_fewer_than_two() {
        let mut nodes = rects(&[(0.0, 0.0)]);
        align_nodes(&mut nodes, NodeAlignment::Left);
        assert_eq!(nodes[0].origin(), Point::ZERO);
    }

    #[test]
    fn aligns_left_edges() {
        let mut nodes = rects(&[(0.0, 0.0), (30.0, 5.0), (10.0, 20.0)]);
        align_nodes(&mut nodes, NodeAlignment::Left);
        assert_eq!(origins(&nodes), vec![Point::new(0.0, 0.0), Point::new(0.0, 5.0), Point::new(0.0, 20.0)]);
    }

    #[test]
    fn aligns_centers_horizontally() {
        let mut nodes = rects(&[(0.0, 0.0), (40.0, 0.0)]);
        align_nodes(&mut nodes, NodeAlignment::CenterHorizontal);
        assert_eq!(origins(&nodes), vec![Point::new(20.0, 0.0), Point::new(20.0, 0.0)]);
    }

    #[test]
    fn distribute_does_nothing_for_fewer_than_three() {
        let mut nodes = rects(&[(0.0, 0.0), (20.0, 0.0)]);
        distribute_nodes(&mut nodes, NodeDistribution::Horizontal);
        assert_eq!(origins(&nodes), vec![Point::ZERO, Point::new(20.0, 0.0)]);
    }

    #[test]
    fn distributes_horizontally_with_equal_spacing() {
        let mut nodes = rects(&[(0.0, 0.0), (30.0, 0.0), (100.0, 0.0)]);
        distribute_nodes(&mut nodes, NodeDistribution::Horizontal);
        assert_eq!(origins(&nodes), vec![Point::new(0.0, 0.0), Point::new(50.0, 0.0), Point::new(100.0, 0.0)]);
    }

    #[test]
    fn distributes_vertically_with_equal_spacing() {
        let mut nodes = rects(&[(0.0, 0.0), (0.0, 30.0), (0.0, 100.0)]);
        distribute_nodes(&mut nodes, NodeDistribution::Vertical);
        assert_eq!(origins(&nodes), vec![Point::new(0.0, 0.0), Point::new(0.0, 50.0), Point::new(0.0, 100.0)]);
    }
}
