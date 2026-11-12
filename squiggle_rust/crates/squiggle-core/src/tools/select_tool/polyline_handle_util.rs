//! Polyline vertex handle hit testing (`polyline_handle_util.dart`).

use super::SELECTION_HANDLE_HIT_SIZE;
use super::polyline_handle::PolylineHandle;
use crate::camera::Camera;
use crate::feature_kind::FeatureKind;
use crate::geom::{Point, Rect};
use crate::node::Node;

pub fn hit_test(node: &Node, world_point: Point, camera: &Camera) -> Option<PolylineHandle> {
    let feature = node.as_feature()?;
    let FeatureKind::Polyline(polyline) = &feature.kind else { return None };
    let screen_point = camera.world_to_screen(world_point);
    polyline.local_points.iter().enumerate().find_map(|(point_index, local)| {
        let center = camera.world_to_screen(feature.origin + *local);
        let geometry = Rect::from_center(center, SELECTION_HANDLE_HIT_SIZE, SELECTION_HANDLE_HIT_SIZE);
        geometry.contains(screen_point).then_some(PolylineHandle { feature: feature.id, point_index, geometry })
    })
}
