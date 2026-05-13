use gpui::*;

use crate::feature::Feature;

#[derive(Clone)]
pub struct ShapeCanvasState {
    pub camera_x: f32,
    pub camera_y: f32,
    pub camera_zoom: f32,

    last_mouse_pos: Option<Point<Pixels>>,
}

impl ShapeCanvasState {
    pub fn new() -> Self {
        Self {
            camera_x: 0.,
            camera_y: 0.,
            camera_zoom: 1.,
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
                                    window.paint_quad(fill(
                                        Bounds::new(
                                            point(
                                                bounds.origin.x
                                                    + (px(*x - state.camera_x) / state.camera_zoom),
                                                bounds.origin.y
                                                    + (px(*y - state.camera_y) / state.camera_zoom),
                                            ),
                                            size(
                                                px(*w / state.camera_zoom),
                                                px(*h / state.camera_zoom),
                                            ),
                                        ),
                                        rgb(0xcba6f7),
                                    ));
                                }
                                Feature::Circle { x, y, r } => {
                                    let diameter = px(*r * 2.0);
                                    window.paint_quad(
                                        fill(
                                            Bounds::new(
                                                point(
                                                    bounds.origin.x
                                                        + px((*x - state.camera_x)
                                                            / state.camera_zoom),
                                                    bounds.origin.y
                                                        + px((*y - state.camera_y)
                                                            / state.camera_zoom),
                                                ),
                                                size(diameter, diameter) / state.camera_zoom,
                                            ),
                                            rgb(0xf38ba8),
                                        )
                                        .corner_radii(px(*r / state.camera_zoom)),
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
                    // let camera_zoom_prev = state.camera_zoom;

                    state.camera_x -= delta.x.as_f32() * state.camera_zoom;
                    state.camera_y -= delta.y.as_f32() * state.camera_zoom;

                    // state.camera_zoom += delta.y.as_f32() / 40.;
                    // state.camera_zoom = state.camera_zoom.clamp(1., 10.);

                    // let dcx = event.position.x * (camera_zoom_prev - state.camera_zoom);
                    // let dcy = event.position.y * (camera_zoom_prev - state.camera_zoom);

                    // state.camera_x += dcx.as_f32();
                    // state.camera_y += dcy.as_f32();
                });
                cx.notify(state_for_wheel.entity_id());
            })
            .on_pinch(move |event, _, cx| {
                let delta = event.delta;

                state_for_pinch.update(cx, |state, _| {
                    let camera_zoom_prev = state.camera_zoom;

                    state.camera_zoom *= 1. - 0.6 * (delta / 0.4);
                    state.camera_zoom = state.camera_zoom.clamp(0.05, 10.);

                    let dcx = event.position.x * (camera_zoom_prev - state.camera_zoom);
                    let dcy = event.position.y * (camera_zoom_prev - state.camera_zoom);

                    state.camera_x += dcx.as_f32();
                    state.camera_y += dcy.as_f32();
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

                    state.camera_x -= delta.x.as_f32() * state.camera_zoom;
                    state.camera_y -= delta.y.as_f32() * state.camera_zoom;
                });
                cx.notify(self.state.entity_id());
            })
    }
}

fn draw_grid_lines(state: &ShapeCanvasState, bounds: Bounds<Pixels>, window: &mut Window) {
    const BASE_CELL_SIZE: f32 = 128.;
    let virtual_width = bounds.size.width * state.camera_zoom;

    let cell_width = BASE_CELL_SIZE / state.camera_zoom;
    let cell_count_x: i32 = (virtual_width.as_f32() / cell_width).ceil() as i32;
    let camera_position = point(px(state.camera_x), px(state.camera_y));

    for i in 0..cell_count_x + 1 {
        let x = px((i as f32) * BASE_CELL_SIZE);
        window.paint_quad(fill(
            Bounds::new(
                bounds.origin
                    + (point(
                        (x - (camera_position.x % px(BASE_CELL_SIZE))) / state.camera_zoom,
                        px(0.),
                    )),
                size(px(1.0), bounds.size.height),
            ),
            rgb(0x444444),
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
                        (y - (camera_position.y % px(BASE_CELL_SIZE))) / state.camera_zoom,
                    )),
                size(bounds.size.width, px(1.0)),
            ),
            rgb(0x444444),
        ));
    }
}
