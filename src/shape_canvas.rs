use gpui::*;

use crate::{camera::Camera, feature::Feature};

#[derive(Clone)]
pub struct ShapeCanvasState {
    pub camera: Camera,

    last_mouse_pos: Option<Point<Pixels>>,
}

impl ShapeCanvasState {
    pub fn new() -> Self {
        Self {
            camera: Camera::default(),
            last_mouse_pos: None,
        }
    }
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
    fn render(self, _window: &mut Window, _: &mut App) -> impl IntoElement {
        let features = self.features;
        let state = self.state.clone();
        let state_for_wheel = self.state.clone();
        let state_for_pinch = self.state.clone();
        div()
            .child(
                canvas(
                    move |_bounds: Bounds<Pixels>, _window, _cx| {},
                    move |bounds: Bounds<Pixels>, _prepaint, window: &mut Window, cx: &mut App| {
                        let state = state.read(cx);
                        draw_grid_lines(state, bounds, window);
                        for feature in &features {
                            match feature {
                                Feature::Rectangle { x, y, w, h } => {
                                    let world_bounds =
                                        Bounds::new(point(px(*x), px(*y)), size(px(*w), px(*h)));
                                    window.paint_quad(fill(
                                        state
                                            .camera
                                            .world_to_screen_bounds(bounds.origin, world_bounds),
                                        rgb(0xcba6f7),
                                    ));
                                }
                                Feature::Circle { x, y, r } => {
                                    let world_bounds = Bounds::new(
                                        point(px(*x), px(*y)),
                                        size(px(*r * 2.0), px(*r * 2.0)),
                                    );
                                    window.paint_quad(
                                        fill(
                                            state.camera.world_to_screen_bounds(
                                                bounds.origin,
                                                world_bounds,
                                            ),
                                            rgb(0xf38ba8),
                                        )
                                        .corner_radii(
                                            state.camera.world_length_to_screen_length(*r),
                                        ),
                                    );
                                }
                            }
                        }
                    },
                )
                .size_full(),
            )
            .size_full()
            .on_scroll_wheel(move |event, _, cx| {
                let delta = event.delta.pixel_delta(px(1.));

                state_for_wheel.update(cx, |state, _| {
                    state.camera.pan_by_screen_delta(delta);
                });
                cx.notify(state_for_wheel.entity_id());
            })
            .on_pinch(move |event, _, cx| {
                let delta = event.delta;

                state_for_pinch.update(cx, |state, _| {
                    state
                        .camera
                        .zoom_toward(event.position, 1. - 0.6 * (delta / 0.4));
                });
                cx.notify(state_for_pinch.entity_id());
            })
            .on_mouse_move(move |event, _window, cx| {
                if !event.dragging() {
                    self.state.update(cx, |state, _| {
                        state.last_mouse_pos = None;
                    });
                    return;
                }
                self.state.update(cx, |state, _| {
                    let delta = if let Some(last) = state.last_mouse_pos {
                        event.position - last
                    } else {
                        point(px(0.), px(0.))
                    };
                    state.last_mouse_pos = Some(event.position);

                    state.camera.pan_by_screen_delta(delta);
                });
                cx.notify(self.state.entity_id());
            })
    }
}

fn draw_grid_lines(state: &ShapeCanvasState, bounds: Bounds<Pixels>, window: &mut Window) {
    const BASE_CELL_SIZE: f32 = 128.;
    let virtual_width = state
        .camera
        .screen_length_to_world_length(bounds.size.width);

    let cell_width = BASE_CELL_SIZE / state.camera.zoom();
    let cell_count_x: i32 = (virtual_width.as_f32() / cell_width).ceil() as i32;
    let camera_position = state.camera.location();

    for i in 0..cell_count_x + 1 {
        let x = px((i as f32) * BASE_CELL_SIZE);
        window.paint_quad(fill(
            Bounds::new(
                bounds.origin
                    + (point(
                        (x - (camera_position.x % px(BASE_CELL_SIZE))) / state.camera.zoom(),
                        px(0.),
                    )),
                size(px(1.0), bounds.size.height),
            ),
            rgb(0x45475a),
        ));
    }
    let cells_y: i32 = (bounds.size.height / cell_width).as_f32().ceil() as i32;
    for j in 0..cells_y + 1 {
        let y = px((j as f32) * BASE_CELL_SIZE);
        window.paint_quad(fill(
            Bounds::new(
                bounds.origin
                    + (point(
                        px(0.),
                        (y - (camera_position.y % px(BASE_CELL_SIZE))) / state.camera.zoom(),
                    )),
                size(bounds.size.width, px(1.0)),
            ),
            rgb(0x45475a),
        ));
    }
}
