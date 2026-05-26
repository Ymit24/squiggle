use gpui::{Pixels, Point};

use crate::{
    document::{Command, Document},
    editor::SelectionState,
    feature_id::FeatureId,
};

#[derive(Clone)]
pub(super) struct MovingFSMState {
    pub(super) selected_feature_move_offset: Point<Pixels>,
    pub(super) is_first_time_select: bool,
    pub(super) did_move: bool,
}

impl MovingFSMState {
    pub(super) fn on_mouse_move(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
    ) {
        let selected_features = selection_state.selected_features.clone();
        if selected_features.is_empty() {
            return;
        }

        self.did_move = true;

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
}
