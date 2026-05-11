use gpui::*;

use crate::feature::Feature;

#[derive(Clone)]
pub struct ShapeCanvasState {
    pub camera_x: f32,
    pub camera_y: f32,
    pub camera_zoom: f32,
}

#[derive(IntoElement)]
pub struct ShapeCanvas {
    state: Entity<ShapeCanvasState>,
    features: Vec<Feature>,
}

impl ShapeCanvas {
    pub fn new(state: Entity<ShapeCanvasState>, features: Vec<Feature>) -> Self {
        Self { state, features }
    }
}

impl RenderOnce for ShapeCanvas {
    fn render(self, _window: &mut Window, _cx: &mut App) -> impl IntoElement {
        let features = self.features;
        canvas(
            move |_bounds: Bounds<Pixels>, _window, _cx| {},
            move |bounds: Bounds<Pixels>, _prepaint, window: &mut Window, cx: &mut App| {
                let state = self.state.read(cx);
                draw_grid_lines(state, bounds, window);
                for feature in &features {
                    match feature {
                        Feature::Rectangle { x, y, w, h } => {
                            window.paint_quad(fill(
                                Bounds::new(
                                    point(bounds.origin.x + px(*x), bounds.origin.y + px(*y)),
                                    size(px(*w), px(*h)),
                                ),
                                rgb(0xcba6f7),
                            ));
                        }
                        Feature::Circle { x, y, r } => {
                            let diameter = px(*r * 2.0);
                            window.paint_quad(
                                fill(
                                    Bounds::new(
                                        point(bounds.origin.x + px(*x), bounds.origin.y + px(*y)),
                                        size(diameter, diameter),
                                    ),
                                    rgb(0xf38ba8),
                                )
                                .corner_radii(px(*r)),
                            );
                        }
                    }
                }
            },
        )
        .size_full()
    }
}

fn draw_grid_lines(state: &ShapeCanvasState, bounds: Bounds<Pixels>, window: &mut Window) {
    const CELLS_X: i32 = 20i32;
    let cell_width: f32 = f32::from(bounds.size.width / (CELLS_X as f32));
    let camera_position = point(px(state.camera_x), px(state.camera_y));
    for i in 1..CELLS_X {
        let x = bounds.origin.x + px((i as f32) * cell_width);
        window.paint_quad(fill(
            Bounds::new(
                camera_position + point(x, bounds.origin.y),
                size(px(1.0), bounds.size.height),
            ),
            rgb(0x444444),
        ));
    }
    let cells_y: i32 = (bounds.size.height / cell_width).as_f32().ceil() as i32;
    for j in 1..cells_y {
        let y = bounds.origin.y + px((j as f32) * cell_width);
        window.paint_quad(fill(
            Bounds::new(
                camera_position + point(bounds.origin.y, y),
                size(bounds.size.width, px(1.0)),
            ),
            rgb(0x444444),
        ));
    }
}
