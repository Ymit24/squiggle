use gpui::*;

use crate::{
    app::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature::FeatureKind,
    feature_id::FeatureId,
};

pub struct ShapeCanvas {
    camera: Camera,
    selected_feature_move_offset: Point<Pixels>,
    did_drag: bool,
    did_select: bool,
    active_selection_box: Option<Bounds<Pixels>>,

    document: Entity<Document>,
    selection_state: Entity<SelectionState>,
}

impl ShapeCanvas {
    pub fn new(document: Entity<Document>, selection_state: Entity<SelectionState>) -> Self {
        Self {
            camera: Camera::default(),
            selected_feature_move_offset: Point::new(px(0.), px(0.)),
            did_drag: false,
            did_select: false,
            active_selection_box: Some(Bounds::centered_at(
                point(px(50.), px(50.)),
                size(px(100.), px(100.)),
            )),
            document,
            selection_state,
        }
    }
}

impl ShapeCanvas {
    fn on_scroll_wheel(
        &mut self,
        event: &ScrollWheelEvent,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let delta = event.delta.pixel_delta(px(1.));

        self.camera.pan_by_screen_delta(delta);
        cx.notify();
    }

    fn on_pinch(&mut self, event: &PinchEvent, cx: &mut Context<Self>) {
        let delta = event.delta;
        self.camera
            .zoom_toward(event.position, 1. - 0.6 * (delta / 0.4));
        cx.notify();
    }

    fn on_mouse_move(
        &mut self,
        event: &MouseMoveEvent,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let selected_features = self.selection_state.read(cx).selected_features.clone();
        let document = self.document.read(cx);

        let camera = self.camera.clone();

        if !event.dragging() || selected_features.is_empty() {
            return;
        }

        self.did_drag = true;

        let chase_feature = document
            .feature_by_id(selected_features.last().unwrap().clone())
            .unwrap();

        let last_mouse_pos = self.selected_feature_move_offset.clone();

        let selected_features: Vec<(FeatureId, Point<Pixels>)> = selected_features
            .iter()
            .map(|id| {
                let feature = document.feature_by_id(id.clone()).unwrap().clone();
                (feature.id, feature.origin - chase_feature.origin)
            })
            .collect();

        self.document.update(cx, |document, _cx| {
            for (id, offset) in selected_features.into_iter() {
                document.execute_command(Command::MoveFeature(
                    id,
                    (camera.screen_to_world(event.position) - last_mouse_pos) + offset,
                ));
            }
        });
    }

    fn on_mouse_down(
        &mut self,
        event: &MouseDownEvent,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let doc = self.document.read(cx);
        let mouse_world = self.camera.screen_to_world(event.position);

        let selection_state = self.selection_state.read(cx).selected_features.clone();

        let selected_feature = doc
            .features
            .iter()
            .find(|feature| feature.bounds().contains(&mouse_world));

        if let Some(feature) = selected_feature {
            if !event.modifiers.shift {
                self.selected_feature_move_offset = point(px(0.), px(0.));
            }
            self.selected_feature_move_offset =
                self.camera.screen_to_world(event.position) - feature.origin;

            let id = feature.id.clone();
            if !selection_state.contains(&id) {
                self.did_select = true;
            }
            self.selection_state.update(cx, move |state, _| {
                if !event.modifiers.shift {
                    if !selection_state.contains(&id) {
                        state.selected_features.clear();
                    }
                }
                state.selected_features.push(id);
            });
        } else {
            if !event.modifiers.shift {
                self.selected_feature_move_offset = point(px(0.), px(0.));
                self.selection_state.update(cx, |state, _| {
                    state.selected_features.clear();
                });
            }
        }
    }

    fn on_mouse_up(&mut self, event: &MouseUpEvent, _window: &mut Window, cx: &mut Context<Self>) {
        let doc = self.document.read(cx);
        let mouse_world = self.camera.screen_to_world(event.position);

        let hovered_feature = doc
            .features
            .iter()
            .find(|feature| feature.bounds().contains(&mouse_world))
            .map(Clone::clone);

        if let Some(hovered_feature) = hovered_feature {
            if self.did_drag {
                self.did_drag = false;
                self.did_select = false;
                return;
            }

            if event.modifiers.shift {
                println!("Did select: {:?}", self.did_select);
                if !self.did_select {
                    self.selection_state.update(cx, |state, _| {
                        state
                            .selected_features
                            .retain(|id| id != &hovered_feature.id);
                    });
                } else {
                    self.did_select = false;
                }
            } else {
                self.selection_state.update(cx, |state, _| {
                    state.selected_features.clear();
                    state.selected_features.push(hovered_feature.id);
                });
            }
        }
    }

    fn paint_canvas(
        &mut self,
        bounds: Bounds<Pixels>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        self.camera.set_viewport_origin(bounds.origin);
        let features = &self.document.read(cx).features;
        let selected_ids = &self.selection_state.read(cx).selected_features;
        draw_grid_lines(&self.camera, bounds, window);
        let zoom = self.camera.zoom();
        let visible_world = Bounds::new(
            self.camera.location(),
            size(bounds.size.width * zoom, bounds.size.height * zoom),
        );

        window.paint_layer(bounds, |window| {
            for feature in features {
                let world_bounds = feature.bounds();
                if !world_bounds.intersect(&visible_world).is_empty() {
                    let screen_bounds = self.camera.world_to_screen_bounds(world_bounds);
                    match feature.kind {
                        FeatureKind::Rectangle { .. } => {
                            window.paint_quad(fill(screen_bounds, rgb(0xcba6f7)));
                        }
                        FeatureKind::Circle { radius } => {
                            window.paint_quad(
                                fill(screen_bounds, rgb(0xf38ba8)).corner_radii(
                                    self.camera.world_length_to_screen_length(radius),
                                ),
                            );
                        }
                    }
                }
            }

            const SELECTION_PADDING: Pixels = px(8.);
            for feature in features {
                if selected_ids.contains(&feature.id) {
                    let world_bounds = feature.bounds();
                    if !world_bounds.intersect(&visible_world).is_empty() {
                        let screen_bounds = self.camera.world_to_screen_bounds(world_bounds);
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
                            outline(padded_bounds, rgb(0xffffff), BorderStyle::Dashed)
                                .border_widths(px(4.)),
                        );
                    }
                }
            }

            if let Some(active_selection_box) = &self.active_selection_box {
                let screen_bounds = self.camera.world_to_screen_bounds(*active_selection_box);
                window.paint_quad(
                    outline(screen_bounds, rgb(0xffffff), BorderStyle::Dashed)
                        .border_widths(px(4.)),
                );
            }
        });
    }
}

impl Render for ShapeCanvas {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let this = cx.entity();

        div()
            .child(
                canvas(
                    move |_, _, _| {},
                    move |bounds: Bounds<Pixels>, _prepaint, window: &mut Window, cx: &mut App| {
                        this.update(cx, |this, cx| {
                            this.paint_canvas(bounds, window, cx);
                        });
                    },
                )
                .size_full(),
            )
            .size_full()
            .on_scroll_wheel(cx.listener(|this, event, window, cx| {
                this.on_scroll_wheel(event, window, cx);
            }))
            .on_pinch(cx.listener(|this, event, _, cx| {
                this.on_pinch(event, cx);
            }))
            .on_mouse_move(cx.listener(|this, event, window, cx| {
                this.on_mouse_move(event, window, cx);
            }))
            .on_mouse_up(
                MouseButton::Left,
                cx.listener(|this, event, window, cx| {
                    this.on_mouse_up(event, window, cx);
                }),
            )
            .on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, event, window, cx| {
                    this.on_mouse_down(event, window, cx);
                }),
            )
    }
}

fn draw_grid_lines(camera: &Camera, bounds: Bounds<Pixels>, window: &mut Window) {
    const BASE_CELL_SIZE: Pixels = px(128.);
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
