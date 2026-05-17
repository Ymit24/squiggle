use gpui::*;

#[derive(Clone, Debug, Copy)]
pub struct Camera {
    location: Point<Pixels>,
    zoom: f32,
    viewport_origin: Point<Pixels>,
}

impl Default for Camera {
    fn default() -> Self {
        Self {
            location: Point::default(),
            zoom: 1.0,
            viewport_origin: Point::default(),
        }
    }
}

impl Camera {
    pub fn new(location: Point<Pixels>, zoom: f32) -> Self {
        Self {
            location,
            zoom,
            viewport_origin: Point::default(),
        }
    }

    pub fn set_viewport_origin(&mut self, origin: Point<Pixels>) {
        self.viewport_origin = origin;
    }

    pub fn world_to_screen(&self, location: Point<Pixels>) -> Point<Pixels> {
        self.viewport_origin + (location - self.location) / self.zoom
    }

    pub fn world_size_to_screen_size(&self, size: Size<Pixels>) -> Size<Pixels> {
        size / self.zoom
    }

    pub fn world_length_to_screen_length(&self, size: Pixels) -> Pixels {
        size / self.zoom
    }

    pub fn screen_length_to_world_length(&self, size: Pixels) -> Pixels {
        size * self.zoom
    }

    pub fn screen_to_world(&self, point: Point<Pixels>) -> Point<Pixels> {
        (point - self.viewport_origin) * self.zoom + self.location
    }

    pub fn location(&self) -> Point<Pixels> {
        self.location
    }

    pub fn zoom(&self) -> f32 {
        self.zoom
    }

    pub fn pan_by_screen_delta(&mut self, delta: Point<Pixels>) {
        self.location -= delta * self.zoom;
    }

    pub fn zoom_toward(&mut self, anchor: Point<Pixels>, factor: f32) {
        let anchor = anchor - self.viewport_origin;
        let prev_zoom = self.zoom;
        self.zoom *= factor;
        self.zoom = self.zoom.clamp(0.05, 10.);
        self.location += anchor * (prev_zoom - self.zoom);
    }

    pub fn world_to_screen_bounds(&self, world_bounds: Bounds<Pixels>) -> Bounds<Pixels> {
        Bounds::new(
            self.world_to_screen(world_bounds.origin),
            self.world_size_to_screen_size(world_bounds.size),
        )
    }
}
