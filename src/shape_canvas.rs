use gpui::*;

use crate::{app::SelectionState, camera::Camera, document::Document, tool_store::ToolStore};

pub struct ShapeCanvas {
    camera: Camera,
    tool_store: Entity<ToolStore>,
    document: Entity<Document>,
    selection_state: Entity<SelectionState>,
}

impl ShapeCanvas {
    pub fn new(
        document: Entity<Document>,
        selection_state: Entity<SelectionState>,
        tool_store: Entity<ToolStore>,
    ) -> Self {
        Self {
            camera: Camera::default(),
            tool_store,
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
        let is_dragging = event.dragging();
        if !is_dragging {
            return;
        }

        let mouse_world = self.camera.screen_to_world(event.position);

        self.document.update(cx, |document, cx| {
            self.selection_state.update(cx, |selection_state, cx| {
                self.tool_store.update(cx, |tool_store, _| {
                    tool_store.tool.on_mouse_move(
                        document,
                        mouse_world,
                        is_dragging,
                        selection_state,
                        event.modifiers.shift,
                    );
                });
            });
        });
    }

    fn on_mouse_down(
        &mut self,
        event: &MouseDownEvent,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let mouse_world = self.camera.screen_to_world(event.position);

        self.selection_state.update(cx, |selection_state, cx| {
            self.tool_store.update(cx, |tool_store, cx| {
                let document = self.document.read(cx);
                tool_store.tool.on_mouse_down(
                    document,
                    mouse_world,
                    selection_state,
                    event.modifiers.shift,
                );
            });
        });
    }

    fn on_mouse_up(
        &mut self,
        event: &MouseUpEvent,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let mouse_world = self.camera.screen_to_world(event.position);

        self.document.update(cx, |document, cx| {
            self.selection_state.update(cx, |selection_state, cx| {
                self.tool_store.update(cx, |tool_store, _| {
                    tool_store.tool.on_mouse_up(
                        document,
                        mouse_world,
                        selection_state,
                        event.modifiers.shift,
                    );
                });
            });
        });
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
                    feature.render(screen_bounds, window);
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
            self.tool_store.read(cx).tool.render(window, &self.camera);
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
