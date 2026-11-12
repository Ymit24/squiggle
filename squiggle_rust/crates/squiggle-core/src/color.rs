//! ARGB colour matching `dart:ui` `Color` (0xAARRGGBB), the format documents persist.

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct Color(pub u32);

impl Color {
    pub const TRANSPARENT: Color = Color(0x0000_0000);
    pub const BLACK: Color = Color(0xFF00_0000);
    pub const WHITE: Color = Color(0xFFFF_FFFF);

    pub const fn from_argb(a: u8, r: u8, g: u8, b: u8) -> Self {
        Color(((a as u32) << 24) | ((r as u32) << 16) | ((g as u32) << 8) | b as u32)
    }

    pub const fn a(self) -> u8 {
        (self.0 >> 24) as u8
    }

    pub const fn r(self) -> u8 {
        (self.0 >> 16) as u8
    }

    pub const fn g(self) -> u8 {
        (self.0 >> 8) as u8
    }

    pub const fn b(self) -> u8 {
        self.0 as u8
    }

    /// Alpha in `0.0..=1.0`.
    pub fn opacity(self) -> f64 {
        self.a() as f64 / 255.0
    }

    pub fn with_opacity(self, opacity: f64) -> Color {
        let a = (opacity.clamp(0.0, 1.0) * 255.0).round() as u8;
        Color::from_argb(a, self.r(), self.g(), self.b())
    }

    pub fn with_alpha(self, a: u8) -> Color {
        Color::from_argb(a, self.r(), self.g(), self.b())
    }

    /// RGBA floats in `0.0..=1.0`, the form most renderers want.
    pub fn to_rgba_f32(self) -> [f32; 4] {
        [
            self.r() as f32 / 255.0,
            self.g() as f32 / 255.0,
            self.b() as f32 / 255.0,
            self.a() as f32 / 255.0,
        ]
    }
}
