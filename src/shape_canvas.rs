use gpui::*;

use crate::{camera::Camera, feature::{Feature, FeatureKind}};

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
                        let zoom = state.camera.zoom();
                        let visible_world = Bounds::new(
                            state.camera.location(),
                            size(bounds.size.width * zoom, bounds.size.height * zoom),
                        );

                        window.paint_layer(bounds, |window| {
                            for feature in &features {
                                let world_bounds = feature.bounds();
                                if !world_bounds.intersect(&visible_world).is_empty() {
                                    match feature.kind {
                                        FeatureKind::Rectangle { .. } => {
                                            window.paint_quad(fill(
                                                state.camera.world_to_screen_bounds(
                                                    bounds.origin,
                                                    world_bounds,
                                                ),
                                                rgb(0xcba6f7),
                                            ));
                                        }
                                        FeatureKind::Circle { radius } => {
                                            window.paint_quad(
                                                fill(
                                                    state.camera.world_to_screen_bounds(
                                                        bounds.origin,
                                                        world_bounds,
                                                    ),
                                                    rgb(0xf38ba8),
                                                )
                                                .corner_radii(
                                                    state.camera.world_length_to_screen_length(radius),
                                                ),
                                            );
                                        }
                                    }
                                }
                            }
                        });
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
    const BASE_CELL_SIZE: Pixels = px(128.);
    let camera = &state.camera;
    let cell_screen = camera.world_length_to_screen_length(BASE_CELL_SIZE);
    let cam = camera.location();

    let first_grid = point(
        px((cam.x.as_f32() / BASE_CELL_SIZE.as_f32()).floor() * BASE_CELL_SIZE.as_f32()),
        px((cam.y.as_f32() / BASE_CELL_SIZE.as_f32()).floor() * BASE_CELL_SIZE.as_f32()),
    );
    let grid_origin = bounds.origin + camera.world_to_screen(first_grid);
    let grid_x = grid_origin.x;
    let grid_y = grid_origin.y;

    let cell_count_x = (bounds.size.width.as_f32() / cell_screen.as_f32()).ceil() as i32 + 2;
    let cell_count_y = (bounds.size.height.as_f32() / cell_screen.as_f32()).ceil() as i32 + 2;

    for i in 0..cell_count_x {
        window.paint_quad(fill(
            Bounds::new(
                point(grid_x + cell_screen * i as f32, bounds.origin.y),
                size(px(1.0), bounds.size.height),
            ),
            rgb(0x45475a),
        ));
    }
    for j in 0..cell_count_y {
        window.paint_quad(fill(
            Bounds::new(
                point(bounds.origin.x, grid_y + cell_screen * j as f32),
                size(bounds.size.width, px(1.0)),
            ),
            rgb(0x45475a),
        ));
    }
}
