use gpui::{rgb, Hsla};

// Catppuccin Mocha

/// Base (#1e1e2e) — app background, FPS overlay background.
pub fn base() -> Hsla {
    rgb(0x1e1e2e).into()
}

/// Mantle (#181825) — toolbar background.
pub fn mantle() -> Hsla {
    rgb(0x181825).into()
}

/// Surface0 (#313244) — toolbar button hover.
pub fn surface0() -> Hsla {
    rgb(0x313244).into()
}

/// Surface1 (#45475a) — borders, active states, grid lines.
pub fn surface1() -> Hsla {
    rgb(0x45475a).into()
}

/// Overlay0 (#6c7086) — secondary/muted text.
pub fn overlay0() -> Hsla {
    rgb(0x6c7086).into()
}

/// Subtext0 (#a6adc8) — inactive toolbar icons.
pub fn subtext0() -> Hsla {
    rgb(0xa6adc8).into()
}

/// Text (#cdd6f4) — active toolbar icons.
pub fn text() -> Hsla {
    rgb(0xcdd6f4).into()
}

/// Green (#a6e3a1) — FPS smooth indicator.
pub fn green() -> Hsla {
    rgb(0xa6e3a1).into()
}

/// Yellow (#f9e2af) — FPS OK indicator.
pub fn yellow() -> Hsla {
    rgb(0xf9e2af).into()
}

/// Red (#f38ba8) — FPS slow indicator, circle features.
pub fn red() -> Hsla {
    rgb(0xf38ba8).into()
}

/// Mauve (#cba6f7) — rectangle features.
pub fn mauve() -> Hsla {
    rgb(0xcba6f7).into()
}

/// Blue (#89b4fa) — toolbar accent; selection strokes on dark canvas.
pub fn accent() -> Hsla {
    Hsla {
        h: 0.603,
        s: 0.72,
        l: 0.74,
        a: 1.,
    }
}
