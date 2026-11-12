//! Pluggable text measurement. Logic that needs text extents (label growth, auto-width text)
//! calls [`measure_text`]; the UI installs a real shaper with [`set_text_measurer`]. The default
//! is a deterministic heuristic so tests and headless use agree.

use crate::geom::Size;
use std::cell::RefCell;

pub trait TextMeasurer {
    /// Size of `text` laid out at `font_size`, wrapping at `width` when given.
    fn measure(&self, text: &str, width: Option<f64>, font_size: f64) -> Size;
}

/// 0.55em average glyph advance, 1.25em line height, greedy word wrap.
pub struct HeuristicMeasurer;

impl TextMeasurer for HeuristicMeasurer {
    fn measure(&self, text: &str, width: Option<f64>, font_size: f64) -> Size {
        let advance = font_size * 0.55;
        let line_height = font_size * 1.25;
        let max_chars = width.map(|w| ((w / advance).floor() as usize).max(1));
        let mut lines = 0usize;
        let mut widest = 0usize;
        for raw in text.split('\n') {
            let mut current = 0usize;
            let mut line_count = 1usize;
            for word in raw.split(' ') {
                let len = word.chars().count();
                match max_chars {
                    Some(max) if current > 0 && current + 1 + len > max => {
                        widest = widest.max(current);
                        line_count += 1;
                        current = len;
                    }
                    _ => current += if current == 0 { len } else { len + 1 },
                }
                if let Some(max) = max_chars
                    && current > max
                {
                    // A single word longer than the box breaks across lines.
                    line_count += (current - 1) / max;
                    current = (current - 1) % max + 1;
                    widest = widest.max(max);
                }
            }
            widest = widest.max(current);
            lines += line_count;
        }
        Size::new(widest as f64 * advance, lines as f64 * line_height)
    }
}

thread_local! {
    static MEASURER: RefCell<Box<dyn TextMeasurer>> = RefCell::new(Box::new(HeuristicMeasurer));
}

pub fn set_text_measurer(measurer: Box<dyn TextMeasurer>) {
    MEASURER.with(|m| *m.borrow_mut() = measurer);
}

pub fn measure_text(text: &str, width: Option<f64>, font_size: f64) -> Size {
    MEASURER.with(|m| m.borrow().measure(text, width, font_size))
}
