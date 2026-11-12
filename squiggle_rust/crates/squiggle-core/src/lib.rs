//! Squiggle core: document model, editing logic and tools, independent of any UI toolkit.

pub mod camera;
pub mod color;
pub mod document;
pub mod feature;
pub mod feature_kind;
pub mod feature_kinds;
pub mod geom;
pub mod group;
pub mod ids;
pub mod node;
pub mod paint;
pub mod session;
pub mod text_measure;

pub use camera::Camera;
pub use color::Color;
pub use document::Document;
pub use feature::Feature;
pub use feature_kind::FeatureKind;
pub use geom::{Point, Rect, Size};
pub use group::Group;
pub use ids::{Container, NO_ID, NodeId};
pub use node::Node;

// --- kinds & painting modules ---
pub mod brush_apply;
pub mod document_colors;
pub mod feature_geometry;
pub mod fill_type;
pub mod font_size_preset;
pub mod inspector;
pub mod label_layout;
pub mod line_end_cap;
pub mod painting;
pub mod stroke_type;
pub mod stroke_width;
pub mod style_values;
pub mod text_alignment;
pub mod text_feature_placement;
pub mod text_sizing;

// --- history & commands modules ---
pub mod editor;
pub mod node_layout;

// --- persistence modules ---
pub mod repositories;
pub mod services;

// --- tools modules ---
