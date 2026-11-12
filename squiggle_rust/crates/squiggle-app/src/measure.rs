//! Text measurement backed by Rune's shaper, so layout in the core matches what is drawn.

use rune::tok::TextStyle;
use squiggle_core::geom::Size;
use squiggle_core::text_measure::{TextMeasurer, set_text_measurer};

pub struct RuneMeasurer;

impl TextMeasurer for RuneMeasurer {
    fn measure(&self, text: &str, width: Option<f64>, font_size: f64) -> Size {
        let style = TextStyle::new(font_size as f32, 400.0);
        let (w, h) = rune::text::measure(text, &[], style, width.map(|w| w as f32));
        Size::new(w as f64, h as f64)
    }
}

/// Installs the Rune measurer for the current thread (call from each thread that uses the core).
pub fn install() {
    set_text_measurer(Box::new(RuneMeasurer));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wrapping_makes_text_taller_and_narrower() {
        let m = RuneMeasurer;
        let one_line = m.measure("hello world again", None, 24.0);
        let wrapped = m.measure("hello world again", Some(100.0), 24.0);
        assert!(wrapped.height > one_line.height);
        assert!(wrapped.width <= 100.0);
    }
}
