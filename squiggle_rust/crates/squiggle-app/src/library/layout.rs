//! Library layout rules (`library_layout.dart` plus the grid maths in `document_library_page.dart`).

pub const COMPACT_BREAKPOINT: f32 = 760.0;
pub const MAX_WIDTH: f32 = 1160.0;
pub const HEADER_CONTROL_HEIGHT: f32 = 38.0;
pub const GRID_GAP: f32 = 18.0;
/// Height of the name/time footer under a card's preview (11 top + 13 bottom padding + text).
pub const CARD_FOOTER_HEIGHT: f32 = 62.0;
/// Padding around the preview inside a card (left/top/right 10).
pub const PREVIEW_INSET: f32 = 10.0;

pub fn is_compact(window_width: f32) -> bool {
    window_width < COMPACT_BREAKPOINT
}

pub fn horizontal_padding(window_width: f32) -> f32 {
    if is_compact(window_width) { 16.0 } else { 40.0 }
}

/// Width available to the card grid.
pub fn grid_width(window_width: f32) -> f32 {
    window_width.clamp(0.0, MAX_WIDTH) - 2.0 * horizontal_padding(window_width)
}

pub fn column_count(grid_width: f32) -> usize {
    if grid_width >= 1020.0 {
        3
    } else if grid_width >= 680.0 {
        2
    } else {
        1
    }
}

/// `(width, height)` of one grid cell; Flutter's `childAspectRatio` is 1.6 for one column, else 0.94.
pub fn card_size(grid_width: f32, columns: usize) -> (f32, f32) {
    let cols = columns.max(1) as f32;
    let width = ((grid_width - GRID_GAP * (cols - 1.0)) / cols).max(0.0);
    let aspect = if columns == 1 { 1.6 } else { 0.94 };
    (width, width / aspect)
}

/// Size of the preview area inside a card of `card`.
pub fn preview_size(card: (f32, f32)) -> (f32, f32) {
    ((card.0 - 2.0 * PREVIEW_INSET).max(0.0), (card.1 - PREVIEW_INSET - CARD_FOOTER_HEIGHT).max(0.0))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compact_below_the_breakpoint() {
        assert!(is_compact(759.0) && !is_compact(760.0));
        assert_eq!(horizontal_padding(500.0), 16.0);
        assert_eq!(horizontal_padding(1100.0), 40.0);
    }

    #[test]
    fn grid_is_capped_at_the_max_width() {
        assert_eq!(grid_width(2000.0), MAX_WIDTH - 80.0);
        assert_eq!(grid_width(1100.0), 1020.0);
    }

    #[test]
    fn columns_follow_the_grid_width() {
        assert_eq!(column_count(1020.0), 3);
        assert_eq!(column_count(1019.0), 2);
        assert_eq!(column_count(680.0), 2);
        assert_eq!(column_count(679.0), 1);
    }

    #[test]
    fn cards_fill_the_row_with_the_flutter_aspect_ratios() {
        let (w, h) = card_size(1020.0, 3);
        assert!((3.0 * w + 2.0 * GRID_GAP - 1020.0).abs() < 1e-3);
        assert!((w / h - 0.94).abs() < 1e-4);
        let (w1, h1) = card_size(400.0, 1);
        assert_eq!(w1, 400.0);
        assert!((w1 / h1 - 1.6).abs() < 1e-4);
    }

    #[test]
    fn preview_leaves_room_for_the_footer() {
        let (w, h) = preview_size((300.0, 320.0));
        assert_eq!((w, h), (280.0, 320.0 - PREVIEW_INSET - CARD_FOOTER_HEIGHT));
    }
}
