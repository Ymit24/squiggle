use gpui::*;

pub type FeatureId = u64;

pub const NO_ID: FeatureId = 0;

#[derive(Clone, Copy)]
pub struct Feature {
    pub id: FeatureId,
    pub origin: Point<Pixels>,
    pub kind: FeatureKind,
}

#[derive(Clone, Copy)]
pub enum FeatureKind {
    Rectangle { size: Size<Pixels> },
    Circle { radius: Pixels },
}

impl Feature {
    pub fn new_rectangle(x: Pixels, y: Pixels, w: Pixels, h: Pixels) -> Self {
        Self {
            id: NO_ID,
            origin: point(x, y),
            kind: FeatureKind::Rectangle { size: size(w, h) },
        }
    }

    pub fn new_circle(x: Pixels, y: Pixels, r: Pixels) -> Self {
        Self {
            id: NO_ID,
            origin: point(x, y),
            kind: FeatureKind::Circle { radius: r },
        }
    }

    pub fn width(&self) -> Pixels {
        match self.kind {
            FeatureKind::Rectangle { size } => size.width,
            FeatureKind::Circle { radius } => radius * 2.0,
        }
    }

    pub fn height(&self) -> Pixels {
        match self.kind {
            FeatureKind::Rectangle { size } => size.height,
            FeatureKind::Circle { radius } => radius * 2.0,
        }
    }

    pub fn size(&self) -> Size<Pixels> {
        size(self.width(), self.height())
    }

    pub fn bounds(&self) -> Bounds<Pixels> {
        Bounds::new(self.origin, self.size())
    }

    pub fn center(&self) -> Point<Pixels> {
        let s = self.size() / 2.0;
        self.origin + point(s.width, s.height)
    }

    pub fn move_to(&mut self, origin: Point<Pixels>) {
        self.origin = origin;
    }
}
