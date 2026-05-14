use gpui::*;

use crate::feature::{Feature, FeatureId, NO_ID};

pub struct Document {
    pub features: Vec<Feature>,
    next_id: FeatureId,
    undo_stack: Vec<Command>,
    redo_stack: Vec<Command>,
}

impl Default for Document {
    fn default() -> Self {
        Self {
            features: Vec::new(),
            next_id: 1,
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
        }
    }
}

#[derive(Clone)]
pub enum Command {
    AddFeature(Feature),
    RemoveFeature(FeatureId),
    MoveFeature(FeatureId, Point<Pixels>),
}

impl Document {
    pub fn new(features: Vec<Feature>) -> Self {
        let mut doc = Self::default();
        for feature in features {
            doc.execute_command(Command::AddFeature(feature));
        }
        doc
    }

    pub fn generate_id(&mut self) -> FeatureId {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    pub fn feature_by_id(&self, id: FeatureId) -> Option<&Feature> {
        self.features.iter().find(|f| f.id == id)
    }

    pub fn feature_by_id_mut(&mut self, id: FeatureId) -> Option<&mut Feature> {
        self.features.iter_mut().find(|f| f.id == id)
    }

    pub fn feature_index_by_id(&self, id: FeatureId) -> Option<usize> {
        self.features.iter().position(|f| f.id == id)
    }

    pub fn execute_command(&mut self, command: Command) {
        self.undo_stack.push(command.clone());
        self.redo_stack.clear();
        match command {
            Command::AddFeature(mut feature) => {
                if feature.id == NO_ID {
                    feature.id = self.generate_id();
                }
                self.features.push(feature);
            }
            Command::RemoveFeature(id) => {
                if let Some(index) = self.feature_index_by_id(id) {
                    self.features.remove(index);
                }
            }
            Command::MoveFeature(id, origin) => {
                if let Some(feature) = self.feature_by_id_mut(id) {
                    feature.move_to(origin);
                }
            }
        };
    }
}
