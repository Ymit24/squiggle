use crate::feature::Feature;

pub struct Document {
    pub features: Vec<Feature>,
    undo_stack: Vec<Command>,
    redo_stack: Vec<Command>,
}

impl Default for Document {
    fn default() -> Self {
        Self {
            features: Vec::new(),
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
        }
    }
}

#[derive(Clone)]
pub enum Command {
    AddFeature(Feature),
    RemoveFeature(usize),
    MoveFeature(usize, f32, f32),
}

impl Document {
    pub fn new(features: Vec<Feature>) -> Self {
        Self {
            features,
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
        }
    }

    pub fn execute_command(&mut self, command: Command) {
        self.undo_stack.push(command.clone());
        self.redo_stack.clear();
        match command {
            Command::AddFeature(feature) => self.features.push(feature),
            Command::RemoveFeature(index) => {
                self.features.remove(index);
            }
            Command::MoveFeature(index, x, y) => {
                self.features[index].move_to(x, y);
            }
        };
    }
}
