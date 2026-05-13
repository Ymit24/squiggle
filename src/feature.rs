#[derive(Clone, Copy)]
pub enum Feature {
    Rectangle { x: f32, y: f32, w: f32, h: f32 },
    Circle { x: f32, y: f32, r: f32 },
}

impl Feature {
    pub fn move_to(&mut self, x: f32, y: f32) {
        match self {
            Feature::Rectangle {
                x: self_x,
                y: self_y,
                w: _,
                h: _,
            } => {
                *self_x = x;
                *self_y = y;
            }
            Feature::Circle {
                x: self_x,
                y: self_y,
                r: _,
            } => {
                *self_x = x;
                *self_y = y;
            }
        }
    }
}
