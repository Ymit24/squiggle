//! A square, selectable swatch (port of `style_color_swatch.dart`). Every selector builds on it.

use super::metrics::{SWATCH, SWATCH_BORDER, SWATCH_RADIUS};
use crate::state::State;
use crate::theme;
use rune::{Color, El, LineCap, Shape, canvas, el, row};

/// Interior size of a swatch, inside its border.
pub const INNER: f32 = SWATCH - 2.0 * SWATCH_BORDER;

pub struct Swatch {
    key: String,
    fill: Option<Color>,
    active: bool,
    enabled: bool,
    help: Option<String>,
    overlay: Option<El>,
}

impl Swatch {
    /// A swatch without a fill is the "none" swatch: the surface colour with a diagonal strike.
    pub fn new(key: impl Into<String>) -> Self {
        Swatch { key: key.into(), fill: None, active: false, enabled: true, help: None, overlay: None }
    }

    pub fn fill(mut self, color: Color) -> Self {
        self.fill = Some(color);
        self
    }

    pub fn active(mut self, active: bool) -> Self {
        self.active = active;
        self
    }

    pub fn enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }

    pub fn help(mut self, help: &str) -> Self {
        self.help = Some(help.to_owned());
        self
    }

    pub fn overlay(mut self, overlay: El) -> Self {
        self.overlay = Some(overlay);
        self
    }

    pub fn build(self, on_press: impl Fn(&mut State) + 'static) -> El {
        let border = if self.active { theme::text() } else { theme::surface1() };
        let overlay = match (self.overlay, self.fill) {
            (Some(overlay), _) => Some(overlay),
            (None, None) => Some(strike(icon_color(self.active))),
            (None, Some(_)) => None,
        };
        let mut swatch = row()
            .key(self.key)
            .size(SWATCH, SWATCH)
            .radius(SWATCH_RADIUS)
            .fill(self.fill.unwrap_or_else(theme::surface0))
            .border(SWATCH_BORDER, border)
            .items_center()
            .justify_center()
            .opacity(if self.enabled { 1.0 } else { 0.35 })
            .focus_selected(self.active);
        if let Some(help) = self.help {
            swatch = swatch.help(help);
        }
        if let Some(overlay) = overlay {
            swatch = swatch.child(overlay);
        }
        if self.enabled { swatch.hover(Color::WHITE.alpha(0.08)).motion(rune::tok::motion::SNAPPY).on_press(on_press) } else { swatch }
    }
}

fn strike(color: Color) -> El {
    let far = INNER - 3.0;
    canvas(Shape::new().view_box(INNER, INNER).line([3.0, 3.0], [far, far], 2.0, LineCap::Butt, color)).size(INNER, INNER)
}

/// Colour of an icon on a swatch: bright when active, muted otherwise.
pub fn icon_color(active: bool) -> Color {
    if active { theme::text() } else { theme::subtext() }
}

/// An overlay box filling the swatch interior, centring `content`.
pub fn centered(content: El) -> El {
    el().size(INNER, INNER).items_center().justify_center().child(content)
}
