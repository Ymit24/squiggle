//! Pointer simulation through `ToolModel`/`EditorContext` for tool tests.

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::editor::tool_model::ToolModel;
use crate::feature::Feature;
use crate::geom::Point;
use crate::tools::tool::{Key, KeyInput, Modifiers};
use crate::{Document, Node};
use serde_json::Value;

pub const NONE: Modifiers = Modifiers { shift: false, alt: false, command: false };
pub const SHIFT: Modifiers = Modifiers { shift: true, alt: false, command: false };
pub const ALT: Modifiers = Modifiers { shift: false, alt: true, command: false };
pub const SHIFT_ALT: Modifiers = Modifiers { shift: true, alt: true, command: false };

pub fn pt(x: f64, y: f64) -> Point {
    Point::new(x, y)
}

pub struct Sim {
    pub ctx: EditorContext,
    pub camera: Camera,
}

impl Sim {
    pub fn new() -> Self {
        Sim { ctx: EditorContext::new(Document::default()), camera: Camera::default() }
    }

    pub fn down(&mut self, p: Point) {
        self.down_with(p, NONE);
    }
    pub fn down_with(&mut self, p: Point, m: Modifiers) {
        ToolModel::on_pointer_down(&mut self.ctx, p, &self.camera, m);
    }
    pub fn mv(&mut self, p: Point) {
        self.mv_with(p, NONE);
    }
    pub fn mv_with(&mut self, p: Point, m: Modifiers) {
        ToolModel::on_pointer_move(&mut self.ctx, p, &self.camera, m);
    }
    pub fn up(&mut self, p: Point) {
        self.up_with(p, NONE);
    }
    pub fn up_with(&mut self, p: Point, m: Modifiers) {
        ToolModel::on_pointer_up(&mut self.ctx, p, &self.camera, m);
    }
    pub fn hover(&mut self, p: Point) {
        ToolModel::on_pointer_hover(&mut self.ctx, p, &self.camera, NONE);
    }
    pub fn key(&mut self, key: Key) -> bool {
        ToolModel::on_key(&mut self.ctx, KeyInput { key, mods: NONE })
    }

    pub fn features(&self) -> Vec<&Feature> {
        self.ctx.document.nodes().iter().filter_map(Node::as_feature).collect()
    }

    pub fn set_brush(&mut self, key: &str, value: Value) {
        self.ctx.brushes.set_field(&mut self.ctx.document.session, key, value);
        self.ctx.refresh_brush_preview();
    }

    pub fn clear_brush(&mut self, key: &str) {
        self.ctx.brushes.clear_field(&mut self.ctx.document.session, key);
        self.ctx.refresh_brush_preview();
    }

    pub fn activate_brush(&mut self, id: &str) {
        self.ctx.brushes.activate(&mut self.ctx.document.session, id);
        self.ctx.refresh_brush_preview();
    }

    pub fn active_brush_id(&self) -> String {
        self.ctx.document.session.active_brush().id.clone()
    }

    /// Creates a brush copying the active one, then makes `restore` active again; returns the id.
    pub fn create_brush(&mut self, name: &str) -> String {
        let brush = self.ctx.brushes.create(&mut self.ctx.document.session, name).unwrap();
        brush.id
    }

    pub fn content(feature: &Feature) -> Value {
        feature.kind.to_json()
    }
}
