//! Paints the visual affordances used by selection tools (`selection_painter.dart`).
//!
//! Output is in world space. Screen-sized values are converted to world units through the camera
//! so handles remain a constant size at every zoom level.

use crate::camera::Camera;
use crate::color::Color;
use crate::editor::context::EditorContext;
use crate::feature_geometry::world_points;
use crate::feature_kind::FeatureKind;
use crate::geom::{Point, Rect};
use crate::paint::{Cap, Painter};
use std::f64::consts::{FRAC_PI_2, TAU};

pub const BASE_COLOR: Color = Color(0xFF17_1717);
pub const ACCENT_COLOR: Color = Color(0xFFA8_B3C2);
pub const SELECTION_FILL_COLOR: Color = Color(0x1AA8_B3C2);

pub const BOX_PADDING: f64 = 8.0;
pub const HANDLE_SIZE: f64 = 12.0;

const CIRCLE_SEGMENTS: usize = 24;
const CORNER_SEGMENTS: usize = 4;
const DASH_LENGTH: f64 = 8.0;
const GAP_LENGTH: f64 = 4.0;
const MARQUEE_STROKE_WIDTH: f64 = 1.5;

/// Selection boxes and any handles associated with the selection.
pub fn paint_selection(ctx: &EditorContext, camera: &Camera, painter: &mut Painter) {
    paint_selected_feature_boxes(ctx, camera, painter);
    paint_selected_polyline_handles(ctx, camera, painter);
}

pub fn paint_selected_feature_boxes(ctx: &EditorContext, camera: &Camera, painter: &mut Painter) {
    let show_resize_handles = ctx.selection.len() == 1;
    for &id in ctx.selection.selected_node_ids() {
        // The inline text editor is the frame while a feature's text is edited.
        if ctx.text_edit.is_editing(id) {
            continue;
        }
        if let Some(node) = ctx.document.node(id) {
            paint_selection_box(painter, camera, node.local_bounds(), show_resize_handles);
        }
    }
}

pub fn paint_selected_polyline_handles(ctx: &EditorContext, camera: &Camera, painter: &mut Painter) {
    let [id] = ctx.selection.selected_node_ids() else { return };
    let Some(feature) = ctx.document.node(*id).and_then(|n| n.as_feature()) else { return };
    let FeatureKind::Polyline(polyline) = &feature.kind else { return };
    for point in world_points(feature.origin, &polyline.local_points) {
        paint_vertex_handle(painter, camera, point);
    }
}

pub fn paint_selection_box(painter: &mut Painter, camera: &Camera, world_bounds: Rect, show_resize_handles: bool) {
    let inflated = world_bounds.inflate(BOX_PADDING);
    let handle_size = camera.screen_length_to_world_length(HANDLE_SIZE);
    let half = handle_size / 2.0;
    let line_width = camera.screen_length_to_world_length(2.0);
    painter.stroke(&rect_points(&inflated), true, line_width, ACCENT_COLOR, Cap::Butt);
    if !show_resize_handles {
        return;
    }
    let centers = [
        inflated.top_left() - Point::new(half, half),
        inflated.top_right() + Point::new(half, -half),
        inflated.bottom_left() + Point::new(-half, half),
        inflated.bottom_right() + Point::new(half, half),
    ];
    for center in centers {
        paint_square_handle(painter, camera, center, handle_size);
    }
}

pub fn paint_vertex_handle(painter: &mut Painter, camera: &Camera, world_point: Point) {
    let radius = camera.screen_length_to_world_length(HANDLE_SIZE / 2.0);
    let outline = circle_points(world_point, radius);
    painter.fill(&outline, BASE_COLOR);
    painter.stroke(&outline, true, camera.screen_length_to_world_length(2.0), ACCENT_COLOR, Cap::Butt);
}

pub fn paint_marquee(painter: &mut Painter, world_bounds: Rect) {
    painter.fill(&rect_points(&world_bounds), SELECTION_FILL_COLOR);
    paint_dashed_rect(painter, world_bounds);
}

/// Accent dashed outline (`utils/painting.dart` `paintDashedRect`).
pub fn paint_dashed_rect(painter: &mut Painter, bounds: Rect) {
    let corners = rect_points(&bounds);
    for i in 0..4 {
        paint_dashed_line(painter, corners[i], corners[(i + 1) % 4]);
    }
}

fn paint_dashed_line(painter: &mut Painter, start: Point, end: Point) {
    let delta = end - start;
    let length = delta.length();
    if length == 0.0 {
        return;
    }
    let direction = delta / length;
    let (mut drawn, mut drawing) = (0.0, true);
    while drawn < length {
        let segment = if drawing { DASH_LENGTH } else { GAP_LENGTH };
        let next = (drawn + segment).min(length);
        if drawing {
            let points = [start + direction * drawn, start + direction * next];
            painter.stroke(&points, false, MARQUEE_STROKE_WIDTH, ACCENT_COLOR, Cap::Butt);
        }
        drawn = next;
        drawing = !drawing;
    }
}

fn paint_square_handle(painter: &mut Painter, camera: &Camera, center: Point, size: f64) {
    let radius = camera.screen_length_to_world_length(2.0);
    let outline = rounded_rect_points(&Rect::from_center(center, size, size), radius);
    painter.fill(&outline, BASE_COLOR);
    painter.stroke(&outline, true, camera.screen_length_to_world_length(2.0), ACCENT_COLOR, Cap::Butt);
}

fn rect_points(rect: &Rect) -> [Point; 4] {
    [rect.top_left(), rect.top_right(), rect.bottom_right(), rect.bottom_left()]
}

fn circle_points(center: Point, radius: f64) -> Vec<Point> {
    (0..CIRCLE_SEGMENTS)
        .map(|i| {
            let angle = TAU * i as f64 / CIRCLE_SEGMENTS as f64;
            center + Point::new(angle.cos(), angle.sin()) * radius
        })
        .collect()
}

/// Rounded rectangle outline, clockwise from the top-left corner's arc.
fn rounded_rect_points(rect: &Rect, radius: f64) -> Vec<Point> {
    let r = radius.min(rect.width() / 2.0).min(rect.height() / 2.0);
    let arcs = [
        (Point::new(rect.left + r, rect.top + r), 2.0),
        (Point::new(rect.right - r, rect.top + r), 3.0),
        (Point::new(rect.right - r, rect.bottom - r), 0.0),
        (Point::new(rect.left + r, rect.bottom - r), 1.0),
    ];
    let mut points = Vec::with_capacity(4 * (CORNER_SEGMENTS + 1));
    for (center, quarter) in arcs {
        for step in 0..=CORNER_SEGMENTS {
            let angle = (quarter + step as f64 / CORNER_SEGMENTS as f64) * FRAC_PI_2;
            points.push(center + Point::new(angle.cos(), angle.sin()) * r);
        }
    }
    points
}
