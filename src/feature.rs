#[derive(Clone, Copy)]
pub struct Feature {
    pub x: f32,
    pub y: f32,
    pub kind: FeatureKind,
}

#[derive(Clone, Copy)]
pub enum FeatureKind {
    Rectangle { w: f32, h: f32 },
    Circle { r: f32 },
}

impl Feature {
    pub fn new_rectangle(x: f32, y: f32, w: f32, h: f32) -> Self {
        Self {
            x,
            y,
            kind: FeatureKind::Rectangle { w, h },
        }
    }

    pub fn new_circle(x: f32, y: f32, r: f32) -> Self {
        Self {
            x,
            y,
            kind: FeatureKind::Circle { r },
        }
    }

    pub fn move_to(&mut self, x: f32, y: f32) {
        self.x = x;
        self.y = y;
    }
}
