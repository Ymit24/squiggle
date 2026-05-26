use gpui::{Bounds, Pixels, Point, Size};

use crate::{document::Document, editor::SelectionState, feature_id::FeatureId};

#[derive(Clone)]
pub(super) struct SelectionFSMState {
    pub(super) selection_box: (Point<Pixels>, Point<Pixels>),
}

impl SelectionFSMState {
    pub(super) fn on_mouse_move(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) -> bool {
        let point1 = self.selection_box.0;
        let point2 = mouse_world;

        self.selection_box = (point1, point2);

        let selection_bounds = selection_box_bounds(self.selection_box);

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

        true
    }
}

pub(super) fn selection_box_bounds(
    selection_box: (Point<Pixels>, Point<Pixels>),
) -> Bounds<Pixels> {
    let (point1, point2) = selection_box;
    let min_point = point1.min(&point2);
    let max_point = point1.max(&point2);
    Bounds::new(min_point, Size::from(max_point - min_point))
}
