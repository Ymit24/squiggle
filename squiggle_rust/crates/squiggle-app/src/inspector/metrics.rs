//! Inspector sizes (port of `inspector/widgets/metrics.dart`).

pub use crate::kit::metrics::{PANEL_PADDING, PANEL_SECTION_SPACING, SWATCH, SWATCH_GAP, SWATCH_RADIUS};

pub const SWATCH_BORDER: f32 = 2.0;
pub const BRUSH_ENTRY_HEIGHT: f32 = 56.0;
pub const BRUSH_PREVIEW_HEIGHT: f32 = 24.0;
pub const BRUSH_PREVIEW_GAP: f32 = 3.0;
pub const BRUSH_ENTRY_VERTICAL_PADDING: f32 = 5.0;
/// Inner width of the panel, which brush entries and previews fill.
pub const PANEL_INNER_WIDTH: f32 = crate::kit::metrics::MENU_WIDTH - 2.0 * PANEL_PADDING;
/// Width brush entries lay their preview out in.
pub const BRUSH_PREVIEW_WIDTH: f32 = PANEL_INNER_WIDTH - 2.0 * crate::kit::metrics::MENU_PADDING;
