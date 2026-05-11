use gpui::*;

use crate::feature::Feature;

pub struct ShapeCanvasState {
    pub camera_x: Entity<f32>,
    pub camera_y: Entity<f32>,
    pub camera_zoom: Entity<f32>,
}

/// Renders a collection of features as shapes on a canvas.
pub fn shape_canvas(features: Vec<Feature>) -> impl IntoElement {
    canvas(
        move |_bounds: Bounds<Pixels>, _window, _cx| {},
        move |bounds: Bounds<Pixels>, _prepaint, window: &mut Window, _cx: &mut App| {
            draw_grid_lines(bounds, window);

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

fn draw_grid_lines(bounds: Bounds<Pixels>, window: &mut Window) {
    const CELLS_X: i32 = 20i32;
    let cell_width: f32 = f32::from(bounds.size.width / (CELLS_X as f32));
    for i in 1..CELLS_X {
        let x = bounds.origin.x + px((i as f32) * cell_width);
        window.paint_quad(fill(
            Bounds::new(point(x, bounds.origin.y), size(px(1.0), bounds.size.height)),
            rgb(0x444444),
        ));
    }
    let cells_y: i32 = (bounds.size.height / cell_width).as_f32().ceil() as i32;
    for j in 1..cells_y {
        let y = bounds.origin.y + px((j as f32) * cell_width);
        window.paint_quad(fill(
            Bounds::new(point(bounds.origin.y, y), size(bounds.size.width, px(1.0))),
            rgb(0x444444),
        ));
    }
}
