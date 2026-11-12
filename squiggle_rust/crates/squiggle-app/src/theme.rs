//! Palette (port of `squiggle_colors.dart`) and conversions from core types to Rune's.

use rune::Color;
use rune::color::srgb_decode;
use squiggle_core::Color as CoreColor;
use squiggle_core::document_colors::squiggle_colors as c;

/// Core colours are 8-bit sRGB ARGB; Rune colours are linear with straight alpha.
pub fn rune_color(color: CoreColor) -> Color {
    let ch = |v: u8| srgb_decode(v as f32 / 255.0);
    Color { r: ch(color.r()), g: ch(color.g()), b: ch(color.b()), a: color.a() as f32 / 255.0 }
}

pub fn base() -> Color {
    rune_color(c::BASE)
}
pub fn mantle() -> Color {
    rune_color(c::MANTLE)
}
pub fn surface0() -> Color {
    rune_color(c::SURFACE0)
}
pub fn surface1() -> Color {
    rune_color(c::SURFACE1)
}
pub fn subtext() -> Color {
    rune_color(c::SUBTEXT0)
}
pub fn text() -> Color {
    rune_color(c::TEXT)
}
pub fn accent() -> Color {
    rune_color(c::ACCENT)
}
pub fn danger() -> Color {
    rune_color(c::DANGER)
}
