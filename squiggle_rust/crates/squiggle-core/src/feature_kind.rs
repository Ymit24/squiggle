//! The closed set of feature kinds. Per-kind behaviour lives in `feature_kinds/*`; this enum only
//! dispatches, so the node/document/tool code stays agnostic of kind specifics.

use crate::color::Color;
use crate::feature::Feature;
use crate::feature_kinds::*;
use crate::fill_type::FillType;
use crate::geom::{Point, Rect};
use crate::label_layout::LabelLayout;
use crate::paint::Painter;
use crate::stroke_type::StrokeType;
use serde_json::Value;

#[derive(Clone, Debug, PartialEq)]
pub enum FeatureKind {
    Rectangle(RectangleKind),
    Circle(CircleKind),
    Text(TextKind),
    Polyline(PolylineKind),
    Image(ImageKind),
}

impl Default for FeatureKind {
    fn default() -> Self {
        FeatureKind::Rectangle(RectangleKind::default())
    }
}

macro_rules! dispatch {
    ($self:expr, $k:ident => $body:expr) => {
        match $self {
            FeatureKind::Rectangle($k) => $body,
            FeatureKind::Circle($k) => $body,
            FeatureKind::Text($k) => $body,
            FeatureKind::Polyline($k) => $body,
            FeatureKind::Image($k) => $body,
        }
    };
}

impl FeatureKind {
    /// Persisted `type` tag.
    pub fn type_name(&self) -> &'static str {
        match self {
            FeatureKind::Rectangle(_) => "rectangle",
            FeatureKind::Circle(_) => "circle",
            FeatureKind::Text(_) => "text",
            FeatureKind::Polyline(_) => "polyline",
            FeatureKind::Image(_) => "image",
        }
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        match content.get("type").and_then(Value::as_str) {
            Some("rectangle") => RectangleKind::from_json(content).map(FeatureKind::Rectangle),
            Some("circle") => CircleKind::from_json(content).map(FeatureKind::Circle),
            Some("text") => TextKind::from_json(content).map(FeatureKind::Text),
            Some("polyline") => PolylineKind::from_json(content).map(FeatureKind::Polyline),
            Some("image") => ImageKind::from_json(content).map(FeatureKind::Image),
            other => Err(format!("Unknown feature kind: {other:?}")),
        }
    }

    /// Persisted `content` object (includes the `type` tag).
    pub fn to_json(&self) -> Value {
        dispatch!(self, k => k.to_json())
    }

    pub fn bounds_for(&self, feature: &Feature) -> Rect {
        dispatch!(self, k => k.bounds_for(feature))
    }

    pub fn hit_test(&self, feature: &Feature, world_point: Point) -> bool {
        dispatch!(self, k => k.hit_test(feature, world_point))
    }

    pub fn intersects_rect(&self, feature: &Feature, rect: &Rect) -> bool {
        dispatch!(self, k => k.intersects_rect(feature, rect))
    }

    /// Called by [`Feature::resize`], which swaps a default kind into the feature while this runs.
    pub fn apply_bounds(&mut self, feature: &mut Feature, bounds: Rect) {
        dispatch!(self, k => k.apply_bounds(feature, bounds))
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        dispatch!(self, k => k.paint(feature, painter))
    }
}

macro_rules! impl_from_kind {
    ($($kind:ident => $variant:ident),+) => {
        $(impl From<$kind> for FeatureKind {
            fn from(kind: $kind) -> Self {
                FeatureKind::$variant(kind)
            }
        })+
    };
}
impl_from_kind!(RectangleKind => Rectangle, CircleKind => Circle, TextKind => Text, PolylineKind => Polyline, ImageKind => Image);

/// Style capabilities (`StrokeColorCapable`, `FillColorCapable`, ...): getters return `None` and
/// setters return `false` for kinds without the capability, so callers need not match variants.
impl FeatureKind {
    pub fn stroke_color(&self) -> Option<Color> {
        Some(match self {
            FeatureKind::Rectangle(k) => k.style.stroke_color,
            FeatureKind::Circle(k) => k.style.stroke_color,
            FeatureKind::Text(k) => k.stroke_color,
            FeatureKind::Polyline(k) => k.stroke_color,
            FeatureKind::Image(k) => k.stroke_color,
        })
    }

    pub fn set_stroke_color(&mut self, color: Color) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.stroke_color = color,
            FeatureKind::Circle(k) => k.style.stroke_color = color,
            FeatureKind::Text(k) => k.stroke_color = color,
            FeatureKind::Polyline(k) => k.stroke_color = color,
            FeatureKind::Image(k) => k.stroke_color = color,
        }
        true
    }

    /// Whether the stroke colour is not fully transparent (`hasVisibleStroke`).
    pub fn has_visible_stroke(&self) -> bool {
        self.stroke_color().is_some_and(|c| c.a() > 0)
    }

    pub fn fill_color(&self) -> Option<Color> {
        match self {
            FeatureKind::Rectangle(k) => Some(k.style.fill_color),
            FeatureKind::Circle(k) => Some(k.style.fill_color),
            _ => None,
        }
    }

    pub fn set_fill_color(&mut self, color: Color) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.fill_color = color,
            FeatureKind::Circle(k) => k.style.fill_color = color,
            _ => return false,
        }
        true
    }

    /// Whether the fill colour is not fully transparent (`hasVisibleFill`).
    pub fn has_visible_fill(&self) -> bool {
        self.fill_color().is_some_and(|c| c.a() > 0)
    }

    pub fn fill_type(&self) -> Option<FillType> {
        match self {
            FeatureKind::Rectangle(k) => Some(k.style.fill_type),
            FeatureKind::Circle(k) => Some(k.style.fill_type),
            _ => None,
        }
    }

    pub fn set_fill_type(&mut self, fill_type: FillType) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.fill_type = fill_type,
            FeatureKind::Circle(k) => k.style.fill_type = fill_type,
            _ => return false,
        }
        true
    }

    pub fn stroke_width(&self) -> Option<f64> {
        match self {
            FeatureKind::Rectangle(k) => Some(k.style.stroke_width),
            FeatureKind::Circle(k) => Some(k.style.stroke_width),
            FeatureKind::Polyline(k) => Some(k.stroke_width),
            FeatureKind::Image(k) => Some(k.stroke_width),
            FeatureKind::Text(_) => None,
        }
    }

    pub fn set_stroke_width(&mut self, width: f64) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.stroke_width = width,
            FeatureKind::Circle(k) => k.style.stroke_width = width,
            FeatureKind::Polyline(k) => k.stroke_width = width,
            FeatureKind::Image(k) => k.stroke_width = width,
            FeatureKind::Text(_) => return false,
        }
        true
    }

    pub fn stroke_type(&self) -> Option<StrokeType> {
        match self {
            FeatureKind::Rectangle(k) => Some(k.style.stroke_type),
            FeatureKind::Circle(k) => Some(k.style.stroke_type),
            FeatureKind::Polyline(k) => Some(k.stroke_type),
            _ => None,
        }
    }

    pub fn set_stroke_type(&mut self, stroke_type: StrokeType) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.stroke_type = stroke_type,
            FeatureKind::Circle(k) => k.style.stroke_type = stroke_type,
            FeatureKind::Polyline(k) => k.stroke_type = stroke_type,
            _ => return false,
        }
        true
    }

    /// The label (the contents, for text) of kinds that can carry one.
    pub fn label(&self) -> Option<&str> {
        match self {
            FeatureKind::Rectangle(k) => Some(&k.style.label),
            FeatureKind::Circle(k) => Some(&k.style.label),
            FeatureKind::Text(k) => Some(&k.label),
            _ => None,
        }
    }

    /// Where and how the label is typeset in `feature`, for label-capable kinds.
    pub fn label_layout(&self, feature: &Feature) -> Option<LabelLayout> {
        match self {
            FeatureKind::Rectangle(k) => Some(k.label_layout(feature)),
            FeatureKind::Circle(k) => Some(k.label_layout(feature)),
            FeatureKind::Text(k) => Some(k.label_layout(feature)),
            _ => None,
        }
    }

    /// Sets the label and grows/refits `feature` to match. `feature` must be the feature that
    /// owns this kind, with the kind swapped out (see [`Feature::set_label`]).
    pub fn set_label(&mut self, feature: &mut Feature, value: &str) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.set_label(feature, value),
            FeatureKind::Circle(k) => k.set_label(feature, value),
            FeatureKind::Text(k) => k.set_label(feature, value),
            _ => return false,
        }
        true
    }
}

impl Feature {
    /// Runs `f` with this feature's kind temporarily taken out (a default kind stands in), so
    /// kind logic that also mutates the feature can borrow both. Kind logic must therefore read
    /// geometry from the feature's `origin`/`size`, never from `feature.kind`.
    pub fn with_kind_taken<R>(&mut self, f: impl FnOnce(&mut FeatureKind, &mut Feature) -> R) -> R {
        let mut kind = std::mem::take(&mut self.kind);
        let result = f(&mut kind, self);
        self.kind = kind;
        result
    }

    /// Sets the label; rectangles and circles grow taller to fit it, text refits its box.
    /// Returns false for kinds without a label.
    pub fn set_label(&mut self, value: &str) -> bool {
        self.with_kind_taken(|kind, feature| kind.set_label(feature, value))
    }

    /// Where and how this feature's label is typeset, if its kind has one.
    pub fn label_layout(&self) -> Option<LabelLayout> {
        self.kind.label_layout(self)
    }

    /// Text features: drops a fixed width so the box hugs its contents again.
    pub fn make_text_auto_width(&mut self) {
        self.with_kind_taken(|kind, feature| {
            if let FeatureKind::Text(text) = kind {
                text.make_auto_width(feature);
            }
        });
    }

    /// Polylines: replaces origin and local points and re-derives the size.
    pub fn set_polyline_geometry(&mut self, origin: Point, local_points: Vec<Point>) {
        self.with_kind_taken(|kind, feature| {
            if let FeatureKind::Polyline(line) = kind {
                line.set_geometry(feature, origin, local_points);
            }
        });
    }

    /// Polylines: moves point `index` to a world position (the first point is the origin).
    pub fn set_polyline_point(&mut self, index: usize, world_position: Point) {
        self.with_kind_taken(|kind, feature| {
            if let FeatureKind::Polyline(line) = kind {
                line.set_point(feature, index, world_position);
            }
        });
    }
}
