//! Polyline kind (`feature_kind_polyline.dart`): an open stroke through local points, with
//! optional arrow heads.

use crate::color::Color;
use crate::document_colors::DEFAULT_FEATURE_STROKE_COLOR;
use crate::feature::Feature;
use crate::feature_geometry::{
    POLYLINE_HIT_SLOP, distance_to_segment, envelope_of_points, local_points_from_world, segment_intersects_rect,
    world_points,
};
use crate::geom::{Point, Rect};
use crate::inspector::{FieldControl, FieldValue, InspectorField};
use crate::line_end_cap::LineEndCap;
use crate::paint::{Cap, Painter};
use crate::painting::{Contour, paint_stroke};
use crate::stroke_type::StrokeType;
use crate::stroke_width::DEFAULT_STROKE_WIDTH;
use crate::style_values::{decode_style_color, decode_style_enum_or, decode_style_number, num};
use serde_json::{Value, json};

/// Segments used per rounded corner of an arrow head.
const ARROW_CURVE_STEPS: usize = 6;

#[derive(Clone, Debug, PartialEq)]
pub struct PolylineKind {
    /// Points relative to the feature origin; the first is normally zero.
    pub local_points: Vec<Point>,
    pub stroke_color: Color,
    pub stroke_width: f64,
    pub stroke_type: StrokeType,
    pub start_end_cap: LineEndCap,
    pub end_end_cap: LineEndCap,
}

impl Default for PolylineKind {
    fn default() -> Self {
        PolylineKind::new(Vec::new())
    }
}

impl PolylineKind {
    pub fn new(local_points: Vec<Point>) -> Self {
        PolylineKind {
            local_points,
            stroke_color: DEFAULT_FEATURE_STROKE_COLOR,
            stroke_width: DEFAULT_STROKE_WIDTH,
            stroke_type: StrokeType::Solid,
            start_end_cap: LineEndCap::Rounded,
            end_end_cap: LineEndCap::Rounded,
        }
    }

    pub fn has_visible_stroke(&self) -> bool {
        self.stroke_color.a() > 0
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        let points = content
            .get("localPoints")
            .and_then(Value::as_array)
            .ok_or("polyline.localPoints")?
            .iter()
            .map(point_from_json)
            .collect::<Result<Vec<_>, _>>()?;
        let get = |key: &str| content.get(key);
        Ok(PolylineKind {
            local_points: points,
            stroke_color: decode_style_color(get("strokeColor"))?,
            stroke_width: decode_style_number(get("strokeWidth"))?,
            stroke_type: decode_style_enum_or(get("strokeType"), StrokeType::Solid),
            start_end_cap: decode_style_enum_or(get("startEndCap"), LineEndCap::Rounded),
            end_end_cap: decode_style_enum_or(get("endEndCap"), LineEndCap::Rounded),
        })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "type": "polyline",
            "localPoints": self.local_points.iter().map(|p| json!({ "x": num(p.x), "y": num(p.y) })).collect::<Vec<_>>(),
            "strokeColor": self.stroke_color.0,
            "strokeWidth": num(self.stroke_width),
            "strokeType": self.stroke_type.name(),
            "startEndCap": self.start_end_cap.name(),
            "endEndCap": self.end_end_cap.name(),
        })
    }

    fn hit_radius(&self) -> f64 {
        self.stroke_width / 2.0
    }

    fn selection_tolerance(&self) -> f64 {
        self.hit_radius() + POLYLINE_HIT_SLOP
    }

    fn has_arrow(&self) -> bool {
        self.start_end_cap == LineEndCap::Arrow || self.end_end_cap == LineEndCap::Arrow
    }

    fn arrow_half_width(&self) -> f64 {
        (self.stroke_width * 1.5).max(5.0)
    }

    fn bounds_padding(&self) -> f64 {
        if !self.has_arrow() {
            return self.hit_radius();
        }
        self.hit_radius().max(self.arrow_half_width() + self.hit_radius() / 2.0)
    }

    fn arrow_length(&self) -> f64 {
        (self.stroke_width * 3.0).max(12.0)
    }

    /// Replaces the geometry: `origin` and the local points, then re-derives the feature size.
    /// `feature.kind` must not be this kind (see [`Feature::set_polyline_geometry`]).
    pub fn set_geometry(&mut self, feature: &mut Feature, origin: Point, local_points: Vec<Point>) {
        feature.origin = origin;
        self.local_points = local_points;
        feature.size = self.bounds_for(feature).size();
    }

    /// Moves point `index` to `world_position`; the first point becomes the new origin.
    /// Out-of-range indices are ignored.
    pub fn set_point(&mut self, feature: &mut Feature, index: usize, world_position: Point) {
        let mut points = world_points(feature.origin, &self.local_points);
        if index >= points.len() {
            return;
        }
        points[index] = world_position;
        let origin = points[0];
        self.set_geometry(feature, origin, local_points_from_world(&points, origin));
    }

    pub fn bounds_for(&self, feature: &Feature) -> Rect {
        if self.local_points.is_empty() {
            return Rect::from_origin_size(feature.origin, feature.size);
        }
        envelope_of_points(&world_points(feature.origin, &self.local_points), self.bounds_padding())
    }

    pub fn hit_test(&self, feature: &Feature, world_point: Point) -> bool {
        if self.local_points.len() < 2 {
            return false;
        }
        let threshold = self.selection_tolerance();
        let points = world_points(feature.origin, &self.local_points);
        if points.windows(2).any(|s| distance_to_segment(world_point, s[0], s[1]) <= threshold) {
            return true;
        }
        self.arrow_polygons(&points).iter().any(|poly| polygon_contains(poly, world_point))
    }

    pub fn intersects_rect(&self, feature: &Feature, rect: &Rect) -> bool {
        if self.local_points.len() < 2 {
            return false;
        }
        let padded = rect.inflate(self.selection_tolerance());
        let points = world_points(feature.origin, &self.local_points);
        points.windows(2).any(|s| segment_intersects_rect(s[0], s[1], &padded))
    }

    /// Scales the centreline proportionally into the new bounds.
    pub fn apply_bounds(&mut self, feature: &mut Feature, bounds: Rect) {
        let padding = self.bounds_padding();
        let old = self.bounds_for(feature).deflate(padding);
        let new = bounds.deflate(padding);
        let ratio = |value: f64, start: f64, extent: f64| if extent == 0.0 { 0.0 } else { (value - start) / extent };
        let scaled: Vec<Point> = self
            .local_points
            .iter()
            .map(|local| {
                let world = feature.origin + *local;
                let nx = ratio(world.x, old.left, old.width());
                let ny = ratio(world.y, old.top, old.height());
                Point::new(new.left + nx * new.width(), new.top + ny * new.height()) - bounds.top_left()
            })
            .collect();
        feature.set_bounds(bounds);
        self.local_points = scaled;
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        if self.local_points.len() < 2 || !self.has_visible_stroke() {
            return;
        }
        let points = world_points(feature.origin, &self.local_points);
        let line = [Contour::open(self.shortened_for_arrows(&points))];
        paint_stroke(painter, &line, self.stroke_width, self.stroke_color, Cap::Round, self.stroke_type);
        for arrow in self.arrow_polygons(&points) {
            painter.fill(&arrow, self.stroke_color);
        }
    }

    pub fn fields(&self) -> Vec<InspectorField> {
        let end_cap = |key, label, is_start, value| {
            InspectorField::new(key, label, FieldControl::EndCap { is_start }, FieldValue::EndCap(value))
        };
        vec![
            InspectorField::new("strokeColor", "Stroke Color", FieldControl::Color, FieldValue::Color(self.stroke_color)),
            InspectorField::new(
                "strokeType",
                "Stroke Type",
                FieldControl::StrokeType,
                FieldValue::StrokeType(self.stroke_type),
            ),
            InspectorField::new(
                "strokeWidth",
                "Stroke Width",
                FieldControl::StrokeWidth,
                FieldValue::Number(self.stroke_width),
            ),
            end_cap("startEndCap", "Start End Cap", true, self.start_end_cap),
            end_cap("endEndCap", "End End Cap", false, self.end_end_cap),
        ]
    }

    pub fn set_field(&mut self, key: &str, value: &FieldValue) -> bool {
        match (key, *value) {
            ("strokeColor", FieldValue::Color(v)) => self.stroke_color = v,
            ("strokeType", FieldValue::StrokeType(v)) => self.stroke_type = v,
            ("strokeWidth", FieldValue::Number(v)) => self.stroke_width = v,
            ("startEndCap", FieldValue::EndCap(v)) => self.start_end_cap = v,
            ("endEndCap", FieldValue::EndCap(v)) => self.end_end_cap = v,
            _ => return false,
        }
        true
    }

    /// The centreline with arrow ends pulled back so the line does not poke through the head.
    fn shortened_for_arrows(&self, world: &[Point]) -> Vec<Point> {
        let mut points = world.to_vec();
        if self.start_end_cap == LineEndCap::Arrow
            && let Some(dir) = endpoint_direction(&points, true)
        {
            points[0] = points[0] - dir * self.arrow_length();
        }
        if self.end_end_cap == LineEndCap::Arrow
            && let Some(dir) = endpoint_direction(&points, false)
        {
            let last = points.len() - 1;
            points[last] = points[last] - dir * self.arrow_length();
        }
        points
    }

    fn arrow_polygons(&self, points: &[Point]) -> Vec<Vec<Point>> {
        let mut arrows = Vec::new();
        if self.start_end_cap == LineEndCap::Arrow
            && let Some(dir) = endpoint_direction(points, true)
        {
            arrows.push(self.arrow_polygon(points[0], dir));
        }
        if self.end_end_cap == LineEndCap::Arrow
            && let Some(dir) = endpoint_direction(points, false)
        {
            arrows.push(self.arrow_polygon(points[points.len() - 1], dir));
        }
        arrows
    }

    /// Arrow head with rounded corners, flattened to a polygon.
    fn arrow_polygon(&self, tip: Point, direction: Point) -> Vec<Point> {
        let half_width = self.arrow_half_width();
        let base = tip - direction * self.arrow_length();
        let normal = Point::new(-direction.y, direction.x) * half_width;
        let (upper, lower) = (base + normal, base - normal);
        let radius = 4.0_f64.min(self.stroke_width / 2.0);
        let mut poly = vec![tip];
        poly.push(point_toward(tip, upper, radius));
        poly.push(point_toward(upper, tip, radius));
        quad_to(&mut poly, upper, point_toward(upper, lower, radius));
        poly.push(point_toward(lower, upper, radius));
        quad_to(&mut poly, lower, point_toward(lower, tip, radius));
        quad_to(&mut poly, tip, tip);
        poly
    }
}

fn point_from_json(value: &Value) -> Result<Point, String> {
    let coord = |k: &str| value.get(k).and_then(Value::as_f64).ok_or_else(|| format!("polyline point.{k}"));
    Ok(Point::new(coord("x")?, coord("y")?))
}

/// Unit vector pointing out of the line at one end, skipping coincident points.
fn endpoint_direction(points: &[Point], from_start: bool) -> Option<Point> {
    let tip = if from_start { *points.first()? } else { *points.last()? };
    let others: Vec<Point> = if from_start { points.iter().skip(1).copied().collect() } else { points.iter().rev().skip(1).copied().collect() };
    others.into_iter().find_map(|p| {
        let delta = tip - p;
        (delta.length() > 0.0).then(|| delta / delta.length())
    })
}

fn point_toward(from: Point, to: Point, distance: f64) -> Point {
    let delta = to - from;
    let len = delta.length();
    if len == 0.0 { from } else { from + delta / len * distance.min(len) }
}

/// Appends a flattened quadratic curve from the polygon's last point via `control` to `end`.
fn quad_to(poly: &mut Vec<Point>, control: Point, end: Point) {
    let Some(start) = poly.last().copied() else { return };
    for i in 1..=ARROW_CURVE_STEPS {
        let t = i as f64 / ARROW_CURVE_STEPS as f64;
        let u = 1.0 - t;
        poly.push(start * (u * u) + control * (2.0 * u * t) + end * (t * t));
    }
}

/// Non-zero winding point-in-polygon test (the polygon is implicitly closed).
fn polygon_contains(poly: &[Point], p: Point) -> bool {
    let mut winding = 0;
    for i in 0..poly.len() {
        let (a, b) = (poly[i], poly[(i + 1) % poly.len()]);
        let cross = (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
        if a.y <= p.y && b.y > p.y && cross > 0.0 {
            winding += 1;
        } else if a.y > p.y && b.y <= p.y && cross < 0.0 {
            winding -= 1;
        }
    }
    winding != 0
}

#[cfg(test)]
mod tests;
