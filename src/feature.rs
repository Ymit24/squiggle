#[derive(Clone, Copy)]
pub enum Feature {
    Rectangle { x: f32, y: f32, w: f32, h: f32 },
    Circle { x: f32, y: f32, r: f32 },
}
