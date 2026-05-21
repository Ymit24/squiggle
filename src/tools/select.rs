use gpui::{BorderStyle, Bounds, Corners, Pixels, Point, Size, Window, point, px, quad};

use crate::{
    colors,
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
        document: &mut Document,
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

    pub fn deactivate(&mut self, selection_state: &mut SelectionState) {
        selection_state.selected_features.clear();
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        if let Some(bounds) = self.selection_box_bounds() {
            let screen_bounds = camera.world_to_screen_bounds(bounds);
            window.paint_quad(quad(
                screen_bounds,
                Corners::all(px(0.)),
                colors::accent().alpha(0.06),
                px(1.5),
                colors::accent(),
                BorderStyle::Dashed,
            ));
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::app::SelectionState;
    use crate::document::Document;
    use crate::feature::Feature;
    use gpui::px;

    fn make_rect(x: f32, y: f32, w: f32, h: f32) -> Feature {
        Feature::new_rectangle(px(x), px(y), px(w), px(h))
    }

    fn doc_with_features(features: Vec<Feature>) -> Document {
        Document::new(features)
    }

    fn point_px(x: f32, y: f32) -> Point<Pixels> {
        point(px(x), px(y))
    }

    #[test]
    fn test_on_mouse_down_clicks_feature_without_shift_clears_and_selects() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();
        let mouse_world = point_px(50., 50.);

        tool.on_mouse_down(&doc, mouse_world, &mut selection_state, false);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert_eq!(selection_state.selected_features[0], doc.features[0].id);
    }

    #[test]
    fn test_on_mouse_down_clicks_feature_with_shift_adds_to_selection() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![
            make_rect(0., 0., 100., 100.),
            make_rect(200., 0., 100., 100.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        let mouse_world = point_px(250., 50.);

        tool.on_mouse_down(&doc, mouse_world, &mut selection_state, true);

        assert_eq!(selection_state.selected_features.len(), 2);
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[0].id)
        );
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[1].id)
        );
    }

    #[test]
    fn test_on_mouse_down_clicks_empty_without_shift_clears_selection() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        let mouse_world = point_px(200., 200.);

        tool.on_mouse_down(&doc, mouse_world, &mut selection_state, false);

        assert!(selection_state.selected_features.is_empty());
    }

    #[test]
    fn test_on_mouse_down_clicks_empty_with_shift_preserves_selection() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();
        let feature_id = doc.features[0].id;
        selection_state.selected_features.push(feature_id);
        let mouse_world = point_px(200., 200.);

        tool.on_mouse_down(&doc, mouse_world, &mut selection_state, true);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert!(selection_state.selected_features.contains(&feature_id));
    }

    #[test]
    fn test_on_mouse_move_non_dragging_does_nothing() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();

        tool.on_mouse_move(
            &mut doc,
            point_px(50., 50.),
            false,
            &mut selection_state,
            false,
        );

        assert!(selection_state.selected_features.is_empty());
        assert!(!tool.did_drag);
    }

    #[test]
    fn test_selection_box_bounds_returns_none_when_no_selection_box() {
        let tool = SelectTool::new();
        assert!(tool.selection_box_bounds().is_none());
    }

    #[test]
    fn test_selection_box_bounds_returns_correct_bounds() {
        let mut tool = SelectTool::new();
        tool.selection_box = Some((point_px(10., 10.), point_px(110., 60.)));

        let bounds = tool.selection_box_bounds().unwrap();

        assert_eq!(bounds.origin, point_px(10., 10.));
        assert_eq!(bounds.size.width, px(100.));
        assert_eq!(bounds.size.height, px(50.));
    }

    #[test]
    fn test_selection_box_bounds_handles_reverse_points() {
        let mut tool = SelectTool::new();
        tool.selection_box = Some((point_px(110., 60.), point_px(10., 10.)));

        let bounds = tool.selection_box_bounds().unwrap();

        assert_eq!(bounds.origin, point_px(10., 10.));
        assert_eq!(bounds.size.width, px(100.));
        assert_eq!(bounds.size.height, px(50.));
    }

    #[test]
    fn test_handle_selection_box_drag_starting_box_on_empty_space() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        let mouse_world = point_px(200., 200.);

        let result = tool.handle_selection_box_drag(&doc, mouse_world, &mut selection_state, false);

        assert!(result);
        assert!(tool.did_drag);
        assert!(tool.selection_box.is_some());
        assert!(selection_state.selected_features.is_empty());
    }

    #[test]
    fn test_handle_selection_box_drag_expands_box_and_selects() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        tool.selection_box = Some((point_px(0., 0.), point_px(0., 0.)));

        let result =
            tool.handle_selection_box_drag(&doc, point_px(150., 25.), &mut selection_state, false);

        assert!(result);
        assert!(tool.did_drag);
        assert!(tool.selection_box.is_some());
        assert_eq!(selection_state.selected_features.len(), 2);
    }

    #[test]
    fn test_handle_selection_box_drag_with_shift_adds_to_selection() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        tool.selection_box = Some((point_px(0., 0.), point_px(0., 0.)));

        tool.handle_selection_box_drag(&doc, point_px(150., 25.), &mut selection_state, true);

        assert_eq!(selection_state.selected_features.len(), 2);
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[0].id)
        );
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[1].id)
        );
    }

    #[test]
    fn test_on_mouse_up_after_drag_clears_flags() {
        let mut tool = SelectTool::new();
        tool.did_drag = true;
        tool.did_select = true;
        let mut doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();

        tool.on_mouse_up(&mut doc, point_px(50., 50.), &mut selection_state, false);

        assert!(!tool.did_drag);
        assert!(!tool.did_select);
    }

    #[test]
    fn test_on_mouse_up_clicks_feature_without_shift_selects_only_that_feature() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);

        tool.on_mouse_up(&mut doc, point_px(25., 25.), &mut selection_state, false);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[0].id)
        );
        assert!(
            !selection_state
                .selected_features
                .contains(&doc.features[1].id)
        );
    }

    #[test]
    fn test_on_mouse_up_clicks_feature_with_shift_removes_from_selection() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        selection_state.selected_features.push(doc.features[1].id);

        tool.on_mouse_up(&mut doc, point_px(25., 25.), &mut selection_state, true);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[1].id)
        );
        assert!(
            !selection_state
                .selected_features
                .contains(&doc.features[0].id)
        );
    }

    #[test]
    fn test_on_mouse_up_clicks_empty_preserves_selection() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![make_rect(0., 0., 50., 50.)]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);

        tool.on_mouse_up(&mut doc, point_px(200., 200.), &mut selection_state, false);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert!(!tool.did_drag);
    }

    #[test]
    fn test_on_mouse_up_after_selection_box_clears_box() {
        let mut tool = SelectTool::new();
        tool.selection_box = Some((point_px(0., 0.), point_px(100., 100.)));
        let mut doc = doc_with_features(vec![make_rect(0., 0., 50., 50.)]);
        let mut selection_state = SelectionState::new();

        tool.on_mouse_up(&mut doc, point_px(25., 25.), &mut selection_state, false);

        assert!(tool.selection_box.is_none());
    }

    #[test]
    fn test_handle_drag_features_moves_single_feature() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![make_rect(0., 0., 50., 50.)]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        tool.selected_feature_move_offset = point_px(10., 10.);

        tool.handle_drag_features(&mut doc, point_px(60., 60.), &mut selection_state);

        assert!(tool.did_drag);
        assert_eq!(doc.features[0].origin.x, px(50.));
        assert_eq!(doc.features[0].origin.y, px(50.));
    }

    #[test]
    fn test_handle_drag_features_does_nothing_when_no_selection() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![make_rect(0., 0., 50., 50.)]);
        let mut selection_state = SelectionState::new();

        tool.handle_drag_features(&mut doc, point_px(100., 100.), &mut selection_state);

        assert!(!tool.did_drag);
    }

    #[test]
    fn test_new_creates_tool_with_default_values() {
        let tool = SelectTool::new();

        assert_eq!(tool.selected_feature_move_offset, point_px(0., 0.));
        assert!(!tool.did_drag);
        assert!(!tool.did_select);
        assert!(tool.selection_box.is_none());
    }

    #[test]
    fn test_handle_drag_features_moves_multiple_features() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![
            make_rect(100., 100., 50., 50.),
            make_rect(0., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        selection_state.selected_features.push(doc.features[1].id);
        tool.selected_feature_move_offset = point_px(0., 0.);

        tool.handle_drag_features(&mut doc, point_px(10., 10.), &mut selection_state);

        assert!(tool.did_drag);
        assert_eq!(doc.features[1].origin.x, px(10.));
        assert_eq!(doc.features[1].origin.y, px(10.));
        assert_eq!(doc.features[0].origin.x, px(110.));
        assert_eq!(doc.features[0].origin.y, px(110.));
    }

    #[test]
    fn test_on_mouse_up_shift_with_did_select_preserves_feature() {
        let mut tool = SelectTool::new();
        let mut doc = doc_with_features(vec![
            make_rect(0., 0., 50., 50.),
            make_rect(100., 0., 50., 50.),
        ]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);
        tool.did_select = true;

        tool.on_mouse_up(&mut doc, point_px(25., 25.), &mut selection_state, true);

        assert_eq!(selection_state.selected_features.len(), 1);
        assert!(
            selection_state
                .selected_features
                .contains(&doc.features[0].id)
        );
        assert!(!tool.did_select);
    }

    #[test]
    fn test_deactivate_clears_selection() {
        let mut tool = SelectTool::new();
        let doc = doc_with_features(vec![make_rect(0., 0., 100., 100.)]);
        let mut selection_state = SelectionState::new();
        selection_state.selected_features.push(doc.features[0].id);

        tool.deactivate(&mut selection_state);

        assert!(selection_state.selected_features.is_empty());
    }
}
