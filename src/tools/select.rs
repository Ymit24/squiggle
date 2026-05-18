use gpui::{BorderStyle, Bounds, Pixels, Point, Size, Window, outline, point, px, rgb};

use crate::{
    app::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature_id::FeatureId,
};

pub struct SelectTool {
    selected_feature_move_offset: Point<Pixels>,
    did_drag: bool,
    did_select: bool,

    selection_box: Option<(Point<Pixels>, Point<Pixels>)>,
}

impl SelectTool {
    pub fn new() -> Self {
        Self {
            selected_feature_move_offset: Point::new(px(0.), px(0.)),
            did_drag: false,
            did_select: false,
            selection_box: None,
        }
    }

    pub fn on_mouse_down(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        let selected_feature = document
            .features
            .iter()
            .find(|feature| feature.bounds().contains(&mouse_world));

        if let Some(feature) = selected_feature {
            if !shift {
                self.selected_feature_move_offset = point(px(0.), px(0.));
            }
            self.selected_feature_move_offset = mouse_world - feature.origin;

            let id = feature.id.clone();
            if !selection_state.selected_features.contains(&id) {
                self.did_select = true;
            }

            if !shift {
                if !selection_state.selected_features.contains(&id) {
                    selection_state.selected_features.clear();
                }
            }
            selection_state.selected_features.push(id);
        } else {
            if !shift {
                self.selected_feature_move_offset = point(px(0.), px(0.));

                selection_state.selected_features.clear();
            }
        }
    }

    pub fn on_mouse_move(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        is_dragging: bool,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        if !is_dragging {
            return;
        }

        if self.handle_selection_box_drag(document, mouse_world, selection_state, shift) {
            return;
        }

        self.handle_drag_features(document, mouse_world, selection_state);
    }

    pub fn on_mouse_up(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        if self.selection_box.is_some() {
            self.selection_box = None;
        }

        let hovered_feature = document
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

            if shift {
                if !self.did_select {
                    selection_state
                        .selected_features
                        .retain(|id| id != &hovered_feature.id);
                } else {
                    self.did_select = false;
                }
            } else {
                selection_state.selected_features.clear();
                selection_state.selected_features.push(hovered_feature.id);
            }
        } else {
            self.did_drag = false;
        }
    }

    fn handle_selection_box_drag(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) -> bool {
        let has_hovered_feature = document
            .features
            .iter()
            .any(|feature| feature.bounds().contains(&mouse_world));

        let is_starting_selecting_box = !self.did_drag && !has_hovered_feature;
        let is_continueing_selection_box = self.did_drag && self.selection_box.is_some();
        let is_drawing_selecion_box = is_starting_selecting_box || is_continueing_selection_box;
        if !is_drawing_selecion_box {
            return false;
        }

        self.did_drag = true;

        if let Some((point1, _)) = self.selection_box {
            let point2 = mouse_world;

            self.selection_box = Some((point1, point2));

            let selection_bounds = self.selection_box_bounds().unwrap();

            let selectable_features: Vec<FeatureId> = document
                .features
                .iter()
                .filter(|feature| feature.bounds().intersects(&selection_bounds))
                .map(|feature| feature.id.clone())
                .collect();

            if shift {
                for feature in &selectable_features {
                    if !selection_state.selected_features.contains(feature) {
                        selection_state.selected_features.push(feature.clone());
                    }
                }
            } else {
                selection_state.selected_features = selectable_features;
            }
        } else {
            self.selection_box = Some((mouse_world, mouse_world));
        }

        true
    }

    fn handle_drag_features(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
    ) {
        let selected_features = selection_state.selected_features.clone();
        if selected_features.is_empty() {
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

        for (id, offset) in selected_features.into_iter() {
            document.execute_command(Command::MoveFeature(
                id,
                (mouse_world - last_mouse_pos) + offset,
            ));
        }
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        if let Some(bounds) = self.selection_box_bounds() {
            let screen_bounds = camera.world_to_screen_bounds(bounds);
            window.paint_quad(
                outline(screen_bounds, rgb(0xffffff), BorderStyle::Dashed).border_widths(px(4.)),
            );
        }
    }

    fn selection_box_bounds(&self) -> Option<Bounds<Pixels>> {
        self.selection_box.map(|(point1, point2)| {
            let min_point = point1.min(&point2);
            let max_point = point1.max(&point2);
            Bounds::new(min_point, Size::from(max_point - min_point))
        })
    }
}
