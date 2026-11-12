//! Minimal 2D geometry modelled on `dart:ui` (`Offset`, `Size`, `Rect`) so ported logic reads the same.

use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub const ZERO: Point = Point { x: 0.0, y: 0.0 };

    pub const fn new(x: f64, y: f64) -> Self {
        Point { x, y }
    }

    pub fn distance(self, other: Point) -> f64 {
        (self - other).length()
    }

    pub fn length(self) -> f64 {
        self.x.hypot(self.y)
    }
}

impl Add for Point {
    type Output = Point;
    fn add(self, o: Point) -> Point {
        Point::new(self.x + o.x, self.y + o.y)
    }
}

impl Sub for Point {
    type Output = Point;
    fn sub(self, o: Point) -> Point {
        Point::new(self.x - o.x, self.y - o.y)
    }
}

impl Mul<f64> for Point {
    type Output = Point;
    fn mul(self, k: f64) -> Point {
        Point::new(self.x * k, self.y * k)
    }
}

impl Div<f64> for Point {
    type Output = Point;
    fn div(self, k: f64) -> Point {
        Point::new(self.x / k, self.y / k)
    }
}

impl Neg for Point {
    type Output = Point;
    fn neg(self) -> Point {
        Point::new(-self.x, -self.y)
    }
}

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct Size {
    pub width: f64,
    pub height: f64,
}

impl Size {
    pub const ZERO: Size = Size { width: 0.0, height: 0.0 };

    pub const fn new(width: f64, height: f64) -> Self {
        Size { width, height }
    }

    pub fn is_empty(self) -> bool {
        self.width <= 0.0 || self.height <= 0.0
    }
}

impl Mul<f64> for Size {
    type Output = Size;
    fn mul(self, k: f64) -> Size {
        Size::new(self.width * k, self.height * k)
    }
}

impl Div<f64> for Size {
    type Output = Size;
    fn div(self, k: f64) -> Size {
        Size::new(self.width / k, self.height / k)
    }
}

/// Axis-aligned rectangle with `left <= right` and `top <= bottom` expected (not enforced).
#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct Rect {
    pub left: f64,
    pub top: f64,
    pub right: f64,
    pub bottom: f64,
}

impl Rect {
    pub const ZERO: Rect = Rect { left: 0.0, top: 0.0, right: 0.0, bottom: 0.0 };

    pub const fn from_ltrb(left: f64, top: f64, right: f64, bottom: f64) -> Self {
        Rect { left, top, right, bottom }
    }

    pub fn from_ltwh(left: f64, top: f64, width: f64, height: f64) -> Self {
        Rect::from_ltrb(left, top, left + width, top + height)
    }

    pub fn from_origin_size(origin: Point, size: Size) -> Self {
        Rect::from_ltwh(origin.x, origin.y, size.width, size.height)
    }

    pub fn from_center(center: Point, width: f64, height: f64) -> Self {
        Rect::from_ltwh(center.x - width / 2.0, center.y - height / 2.0, width, height)
    }

    /// Rectangle spanning two arbitrary corners, normalised.
    pub fn from_points(a: Point, b: Point) -> Self {
        Rect::from_ltrb(a.x.min(b.x), a.y.min(b.y), a.x.max(b.x), a.y.max(b.y))
    }

    pub fn width(&self) -> f64 {
        self.right - self.left
    }

    pub fn height(&self) -> f64 {
        self.bottom - self.top
    }

    pub fn size(&self) -> Size {
        Size::new(self.width(), self.height())
    }

    pub fn top_left(&self) -> Point {
        Point::new(self.left, self.top)
    }

    pub fn top_right(&self) -> Point {
        Point::new(self.right, self.top)
    }

    pub fn bottom_left(&self) -> Point {
        Point::new(self.left, self.bottom)
    }

    pub fn bottom_right(&self) -> Point {
        Point::new(self.right, self.bottom)
    }

    pub fn center(&self) -> Point {
        Point::new((self.left + self.right) / 2.0, (self.top + self.bottom) / 2.0)
    }

    pub fn is_empty(&self) -> bool {
        self.left >= self.right || self.top >= self.bottom
    }

    pub fn shift(&self, offset: Point) -> Rect {
        Rect::from_ltrb(
            self.left + offset.x,
            self.top + offset.y,
            self.right + offset.x,
            self.bottom + offset.y,
        )
    }

    pub fn inflate(&self, delta: f64) -> Rect {
        Rect::from_ltrb(self.left - delta, self.top - delta, self.right + delta, self.bottom + delta)
    }

    pub fn deflate(&self, delta: f64) -> Rect {
        self.inflate(-delta)
    }

    /// Like Flutter's `Rect.contains`: left/top inclusive, right/bottom exclusive.
    pub fn contains(&self, p: Point) -> bool {
        p.x >= self.left && p.x < self.right && p.y >= self.top && p.y < self.bottom
    }

    /// Like Flutter's `Rect.overlaps`: touching edges do not overlap.
    pub fn overlaps(&self, other: &Rect) -> bool {
        !(self.right <= other.left
            || other.right <= self.left
            || self.bottom <= other.top
            || other.bottom <= self.top)
    }

    pub fn expand_to_include(&self, other: &Rect) -> Rect {
        Rect::from_ltrb(
            self.left.min(other.left),
            self.top.min(other.top),
            self.right.max(other.right),
            self.bottom.max(other.bottom),
        )
    }

    pub fn intersect(&self, other: &Rect) -> Rect {
        Rect::from_ltrb(
            self.left.max(other.left),
            self.top.max(other.top),
            self.right.min(other.right),
            self.bottom.min(other.bottom),
        )
    }

    /// Union of rects; `Rect::ZERO` when empty.
    pub fn union_all<'a>(rects: impl IntoIterator<Item = &'a Rect>) -> Rect {
        let mut iter = rects.into_iter();
        match iter.next() {
            None => Rect::ZERO,
            Some(first) => iter.fold(*first, |acc, r| acc.expand_to_include(r)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn contains_is_half_open() {
        let r = Rect::from_ltwh(0.0, 0.0, 10.0, 10.0);
        assert!(r.contains(Point::new(0.0, 0.0)));
        assert!(!r.contains(Point::new(10.0, 5.0)));
    }

    #[test]
    fn touching_rects_do_not_overlap() {
        let a = Rect::from_ltwh(0.0, 0.0, 10.0, 10.0);
        assert!(!a.overlaps(&Rect::from_ltwh(10.0, 0.0, 5.0, 5.0)));
        assert!(a.overlaps(&Rect::from_ltwh(9.0, 0.0, 5.0, 5.0)));
    }
}
