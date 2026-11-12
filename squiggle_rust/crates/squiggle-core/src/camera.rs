use crate::geom::{Point, Rect, Size};

/// 2D camera mapping world coordinates to canvas-local screen space (pixels from the canvas top-left).
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Camera {
    pub location: Point,
    pub zoom: f64,
}

impl Default for Camera {
    fn default() -> Self {
        Camera { location: Point::ZERO, zoom: 1.0 }
    }
}

impl Camera {
    pub const MIN_ZOOM: f64 = 0.05;
    pub const MAX_ZOOM: f64 = 10.0;

    pub fn new(location: Point, zoom: f64) -> Self {
        Camera { location, zoom }
    }

    pub fn world_to_screen(&self, world: Point) -> Point {
        (world - self.location) / self.zoom
    }

    pub fn world_size_to_screen_size(&self, size: Size) -> Size {
        size / self.zoom
    }

    pub fn world_length_to_screen_length(&self, length: f64) -> f64 {
        length / self.zoom
    }

    pub fn screen_length_to_world_length(&self, length: f64) -> f64 {
        length * self.zoom
    }

    pub fn screen_to_world(&self, screen: Point) -> Point {
        screen * self.zoom + self.location
    }

    pub fn pan_by_screen_delta(&mut self, delta: Point) {
        self.location = self.location - delta * self.zoom;
    }

    pub fn zoom_toward(&mut self, anchor: Point, factor: f64) {
        let prev = self.zoom;
        self.zoom = (self.zoom * factor).clamp(Self::MIN_ZOOM, Self::MAX_ZOOM);
        self.location = self.location + anchor * (prev - self.zoom);
    }

    pub fn world_to_screen_bounds(&self, world: Rect) -> Rect {
        Rect::from_origin_size(
            self.world_to_screen(world.top_left()),
            self.world_size_to_screen_size(world.size()),
        )
    }

    pub fn screen_to_world_bounds(&self, screen: Rect) -> Rect {
        Rect::from_origin_size(self.screen_to_world(screen.top_left()), screen.size() * self.zoom)
    }

    /// World-space rectangle visible in a viewport of `viewport` screen pixels.
    pub fn visible_world_rect(&self, viewport: Size) -> Rect {
        Rect::from_origin_size(self.location, viewport * self.zoom)
    }
}
