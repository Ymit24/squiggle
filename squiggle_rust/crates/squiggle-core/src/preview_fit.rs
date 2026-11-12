//! Fits a document's content into a small preview (port of the `_DocumentPreviewPainter` maths
//! in `document_preview.dart`). Pure geometry; the app turns the camera into a render.

use crate::camera::Camera;
use crate::geom::{Point, Rect, Size};

const MIN_VIEWPORT: Size = Size { width: 560.0, height: 420.0 };
const MAX_SCALE: f64 = 1.25;
const MIN_SCALE: f64 = 0.06;
const MIN_CONTENT_EXTENT: f64 = 64.0;

/// Content bounds grown to at least 64 square and padded by 18% (at least 64) on every side.
pub fn padded_content_bounds(bounds: Rect) -> Rect {
    let w = bounds.width().max(MIN_CONTENT_EXTENT);
    let h = bounds.height().max(MIN_CONTENT_EXTENT);
    let pad = MIN_CONTENT_EXTENT.max(w.max(h) * 0.18);
    Rect::from_center(bounds.center(), w, h).inflate(pad)
}

/// World-to-preview scale; content smaller than a 560x420 viewport is not blown up past it.
pub fn fit_scale(content: Rect, size: Size) -> f64 {
    let w = content.width().max(MIN_VIEWPORT.width);
    let h = content.height().max(MIN_VIEWPORT.height);
    (size.width / w).min(size.height / h).clamp(MIN_SCALE, MAX_SCALE)
}

/// Screen offset (preview pixels) that centres `content` at `scale`.
pub fn fit_offset(content: Rect, size: Size, scale: f64) -> Point {
    Point::new(
        (size.width - content.width() * scale) / 2.0 - content.left * scale,
        (size.height - content.height() * scale) / 2.0 - content.top * scale,
    )
}

/// The camera that draws the document's `content_bounds` centred in a `size` preview:
/// `screen = world * scale + offset`, expressed as the editor's `Camera`.
pub fn preview_camera(content_bounds: Rect, size: Size) -> Camera {
    let content = padded_content_bounds(content_bounds);
    let scale = fit_scale(content, size);
    let offset = fit_offset(content, size, scale);
    Camera::new(Point::new(-offset.x / scale, -offset.y / scale), 1.0 / scale)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn close(a: f64, b: f64) -> bool {
        (a - b).abs() < 1e-9
    }

    #[test]
    fn tiny_content_is_grown_and_padded() {
        let padded = padded_content_bounds(Rect::from_ltwh(10.0, 10.0, 4.0, 4.0));
        assert!(close(padded.width(), 64.0 + 128.0) && close(padded.height(), 192.0));
        assert!(close(padded.center().x, 12.0) && close(padded.center().y, 12.0));
    }

    #[test]
    fn large_content_pads_by_eighteen_percent() {
        let padded = padded_content_bounds(Rect::from_ltwh(0.0, 0.0, 1000.0, 500.0));
        assert!(close(padded.width(), 1000.0 + 2.0 * 180.0));
        assert!(close(padded.height(), 500.0 + 2.0 * 180.0));
    }

    #[test]
    fn scale_is_clamped() {
        let huge = Rect::from_ltwh(0.0, 0.0, 1.0e6, 1.0e6);
        assert!(close(fit_scale(huge, Size::new(200.0, 150.0)), MIN_SCALE));
        let small = Rect::from_ltwh(0.0, 0.0, 10.0, 10.0);
        assert!(close(fit_scale(small, Size::new(5000.0, 5000.0)), MAX_SCALE));
    }

    #[test]
    fn small_content_is_scaled_against_the_minimum_viewport() {
        let content = Rect::from_ltwh(0.0, 0.0, 100.0, 100.0);
        assert!(close(fit_scale(content, Size::new(280.0, 210.0)), 0.5));
    }

    #[test]
    fn camera_centres_the_content() {
        let bounds = Rect::from_ltwh(300.0, -200.0, 800.0, 300.0);
        let size = Size::new(280.0, 190.0);
        let camera = preview_camera(bounds, size);
        let centre = camera.world_to_screen(bounds.center());
        assert!(close(centre.x, size.width / 2.0) && close(centre.y, size.height / 2.0));
        let on_screen = camera.world_to_screen_bounds(padded_content_bounds(bounds));
        assert!(on_screen.left >= -1e-6 && on_screen.right <= size.width + 1e-6);
        assert!(on_screen.top >= -1e-6 && on_screen.bottom <= size.height + 1e-6);
    }

    #[test]
    fn camera_zoom_is_the_inverse_of_the_fit_scale() {
        let bounds = Rect::from_ltwh(0.0, 0.0, 2000.0, 1000.0);
        let size = Size::new(300.0, 200.0);
        let scale = fit_scale(padded_content_bounds(bounds), size);
        assert!(close(preview_camera(bounds, size).zoom, 1.0 / scale));
    }
}
