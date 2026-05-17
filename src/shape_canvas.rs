use gpui::*;

use crate::{
    app::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature::FeatureKind,
};

#[derive(Clone)]
pub struct ShapeCanvasState {
    pub camera: Camera,

    selected_feature_move_offset: Vec<Point<Pixels>>,
    expected_drag: bool,
}

impl ShapeCanvasState {
    pub fn new() -> Self {
        Self {
            camera: Camera::default(),
            selected_feature_move_offset: Vec::new(),
        }
    }
}

#[derive(IntoElement)]
pub struct ShapeCanvas {
    state: Entity<ShapeCanvasState>,
    document: Entity<Document>,
    selection_state: Entity<SelectionState>,
}

impl ShapeCanvas {
    pub fn new(
        state: Entity<ShapeCanvasState>,
        document: Entity<Document>,
        selection_state: Entity<SelectionState>,
    ) -> Self {
        Self {
            state,
            document,
            selection_state,
        }
    }
}

impl RenderOnce for ShapeCanvas {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let document_for_render = self.document.clone();
        let document_for_hit_test = self.document.clone();
        let document_for_drag = self.document.clone();

        let state = self.state.clone();
        let state_for_wheel = self.state.clone();
        let state_for_pinch = self.state.clone();
        let state_for_hit_test = self.state.clone();
        let state_for_drag = self.state.clone();

        let selection_state_for_hit_test = self.selection_state.clone();
        let selection_state_for_paint = self.selection_state.clone();
        let selection_state_for_drag = self.selection_state.clone();

        div()
            .child(
                canvas(
                    move |_bounds: Bounds<Pixels>, _window, _cx| {},
                    move |bounds: Bounds<Pixels>, _prepaint, window: &mut Window, cx: &mut App| {
                        state.update(cx, |state, _| {
                            state.camera.set_viewport_origin(bounds.origin);
                        });
                        let state = state.read(cx);
                        let features = &document_for_render.read(cx).features;
                        let selected_ids = &selection_state_for_paint.read(cx).selected_features;
                        draw_grid_lines(state, bounds, window);
                        let zoom = state.camera.zoom();
                        let visible_world = Bounds::new(
                            state.camera.location(),
                            size(bounds.size.width * zoom, bounds.size.height * zoom),
                        );

                        window.paint_layer(bounds, |window| {
                            // First pass: draw all features normally.
                            for feature in features {
                                let world_bounds = feature.bounds();
                                if !world_bounds.intersect(&visible_world).is_empty() {
                                    let screen_bounds =
                                        state.camera.world_to_screen_bounds(world_bounds);
                                    match feature.kind {
                                        FeatureKind::Rectangle { .. } => {
                                            window.paint_quad(fill(screen_bounds, rgb(0xcba6f7)));
                                        }
                                        FeatureKind::Circle { radius } => {
                                            window.paint_quad(
                                                fill(screen_bounds, rgb(0xf38ba8)).corner_radii(
                                                    state
                                                        .camera
                                                        .world_length_to_screen_length(radius),
                                                ),
                                            );
                                        }
                                    }
                                }
                            }

                            // Second pass: draw selection outlines on top.
                            const SELECTION_PADDING: Pixels = px(8.);
                            for feature in features {
                                if selected_ids.contains(&feature.id) {
                                    let world_bounds = feature.bounds();
                                    if !world_bounds.intersect(&visible_world).is_empty() {
                                        let screen_bounds =
                                            state.camera.world_to_screen_bounds(world_bounds);
                                        let padded_bounds = Bounds::new(
                                            point(
                                                screen_bounds.origin.x - SELECTION_PADDING,
                                                screen_bounds.origin.y - SELECTION_PADDING,
                                            ),
                                            size(
                                                screen_bounds.size.width + SELECTION_PADDING * 2.,
                                                screen_bounds.size.height + SELECTION_PADDING * 2.,
                                            ),
                                        );
                                        window.paint_quad(
                                            outline(
                                                padded_bounds,
                                                rgb(0xffffff),
                                                BorderStyle::Dashed,
                                            )
                                            .border_widths(px(4.)),
                                        );
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
                let selected_features = selection_state_for_drag.read(cx).selected_features.clone();
                let state = state_for_drag.read(cx);
                let camera = state.camera.clone();

                if !event.dragging() || selected_features.is_empty() {
                    return;
                }

                let last_mouse_pos = state.selected_feature_move_offset.clone();

                document_for_drag.update(cx, |document, _cx| {
                    for (feature_id, offset) in selected_features.iter().zip(last_mouse_pos) {
                        document.execute_command(Command::MoveFeature(
                            feature_id.clone(),
                            camera.screen_to_world(event.position) - offset,
                        ));
                    }
                });
            })
            // .on_mouse_move(move |event, _window, cx| {
            //     if !event.dragging() {
            //         self.state.update(cx, |state, _| {
            //             state.last_mouse_pos = None;
            //         });
            //         return;
            //     }
            //     self.state.update(cx, |state, _| {
            //         let delta = if let Some(last) = state.last_mouse_pos {
            //             event.position - last
            //         } else {
            //             point(px(0.), px(0.))
            //         };
            //         state.last_mouse_pos = Some(event.position);
            //         state.camera.pan_by_screen_delta(delta);
            //     });
            //     cx.notify(self.state.entity_id());
            // })
            .on_mouse_up(MouseButton::Left, move |event, _window, cx| {})
            .on_mouse_down(MouseButton::Left, move |event, _window, cx| {
                let document = document_for_hit_test.read(cx);
                let state = state_for_hit_test.read(cx).clone();
                let mouse_world = state.camera.screen_to_world(event.position);

                let selected_feature = document
                    .features
                    .iter()
                    .find(|feature| feature.bounds().contains(&mouse_world));

                let selected_feature_id = selected_feature.map(|f| f.id);

                let selected_feature = selected_feature.map(|x| x.clone());

                if let Some(feature) = selected_feature {
                    self.state.update(cx, move |state, _cx| {
                        if !event.modifiers.shift {
                            state.selected_feature_move_offset.clear();
                        }
                        state
                            .selected_feature_move_offset
                            .push(state.camera.screen_to_world(event.position) - feature.origin);
                    });
                } else {
                    self.state.update(cx, move |state, _cx| {
                        state.selected_feature_move_offset.clear();
                    });
                    selection_state_for_hit_test.update(cx, |state, _| {
                        state.selected_features.clear();
                    });
                }

                selection_state_for_hit_test.update(cx, |state, _| {
                    if selected_feature_id.is_none() {
                        state.selected_features.clear();
                    }

                    if let Some(id) = selected_feature_id {
                        state.selected_features.push(id);
                    }
                });
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
    let grid_origin = camera.world_to_screen(first_grid);
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
