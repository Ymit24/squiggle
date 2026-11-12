//! Click-to-place polyline tool (`create_line_tool.dart` + `create_line_tool/*_state.dart`).
//!
//! The Dart `InteractionState` objects become the [`LineState`] enum; each state lives in its own
//! file and reports the next state as a [`Next`] value instead of calling back into the tool.

mod dragging;
mod idle;
mod pending_pointer;
mod placing;

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::feature::Feature;
use crate::feature_geometry::{local_points_from_world, snap_point_to_45_degree_angle};
use crate::feature_kind::FeatureKind;
use crate::feature_kinds::PolylineKind;
use crate::geom::{Point, Size};
use crate::paint::Painter;
use crate::tools::tool::{EditorCursor, Key, KeyInput, Modifiers, Tool, ToolId};
use placing::Placing;

/// Flutter's `kTouchSlop`, in screen pixels.
pub const TOUCH_SLOP: f64 = 18.0;

enum LineState {
    Idle,
    PendingPointer { start: Point },
    Dragging { start: Point },
    Placing(Placing),
}

/// What a state handler wants to happen to the state machine.
enum Next {
    Stay,
    /// Enter another state (running its `on_enter`).
    To(LineState),
    /// The gesture ended (`finish` already reset the tool).
    Idle,
}

/// Tool-wide helpers shared by the states (the Dart `parent`).
#[derive(Default)]
struct LineCore {
    preview: Option<Feature>,
}

impl LineCore {
    fn constrained_point(&self, origin: Point, point: Point, shift: bool) -> Point {
        if shift { snap_point_to_45_degree_angle(origin, point) } else { point }
    }

    fn finish(&mut self, ctx: &mut EditorContext, points: &[Point]) -> Next {
        if points.len() >= 2 {
            self.commit(ctx, points);
        }
        self.preview = None;
        ctx.reset_to_select_tool();
        Next::Idle
    }

    fn commit(&mut self, ctx: &mut EditorContext, world_points: &[Point]) {
        let mut feature = self.preview.take().unwrap_or_else(|| build_feature(ctx, world_points));
        set_feature_points(&mut feature, world_points);
        let created = ctx.history.run(&mut ctx.document, "Create feature", None, |tx| tx.add(feature, None));
        if let Ok(id) = created {
            ctx.select_created_feature(id);
        }
    }

    fn update_preview(&mut self, ctx: &EditorContext, world_points: &[Point]) {
        let feature = self.preview.get_or_insert_with(|| build_feature(ctx, world_points));
        set_feature_points(feature, world_points);
    }
}

fn set_feature_points(feature: &mut Feature, world_points: &[Point]) {
    let Some(&origin) = world_points.first() else { return };
    feature.set_polyline_geometry(origin, local_points_from_world(world_points, origin));
}

fn build_feature(ctx: &EditorContext, world_points: &[Point]) -> Feature {
    let origin = world_points.first().copied().unwrap_or(Point::ZERO);
    let mut kind = FeatureKind::Polyline(PolylineKind::new(local_points_from_world(world_points, origin)));
    ctx.apply_active_brush(&mut kind);
    Feature::new(origin, Size::ZERO, kind)
}

pub struct CreateLineTool {
    state: LineState,
    core: LineCore,
}

impl Default for CreateLineTool {
    fn default() -> Self {
        CreateLineTool { state: LineState::Idle, core: LineCore::default() }
    }
}

impl CreateLineTool {
    pub fn new() -> Self {
        Self::default()
    }

    fn reset(&mut self) {
        self.state = LineState::Idle;
        self.core.preview = None;
    }

    /// Runs `f` on the current state and applies the transition it asks for.
    fn step<R>(
        &mut self,
        ctx: &mut EditorContext,
        f: impl FnOnce(&mut LineState, &mut LineCore, &mut EditorContext) -> (Next, R),
    ) -> R {
        let mut state = std::mem::replace(&mut self.state, LineState::Idle);
        let (next, result) = f(&mut state, &mut self.core, ctx);
        self.state = match next {
            Next::Stay => state,
            Next::Idle => LineState::Idle,
            Next::To(mut next) => {
                if let LineState::Placing(p) = &mut next {
                    p.on_enter(&mut self.core, ctx);
                }
                next
            }
        };
        result
    }
}

impl Tool for CreateLineTool {
    fn id(&self) -> ToolId {
        ToolId::Line
    }

    fn create_drawing_kind(&self) -> Option<FeatureKind> {
        Some(FeatureKind::Polyline(PolylineKind::new(Vec::new())))
    }

    fn refresh_brush_preview(&mut self, ctx: &mut EditorContext) {
        let Some(feature) = &mut self.core.preview else { return };
        let FeatureKind::Polyline(previous) = &feature.kind else { return };
        let mut fresh = FeatureKind::Polyline(PolylineKind::new(previous.local_points.clone()));
        ctx.apply_active_brush(&mut fresh);
        feature.kind = fresh;
    }

    fn resolve_cursor(&self, _: &EditorContext, _: Point, _: &Camera) -> EditorCursor {
        EditorCursor::Crosshair
    }

    fn paint(&self, _: &EditorContext, _: &Camera, painter: &mut Painter) {
        if let Some(feature) = &self.core.preview {
            feature.paint(painter);
        }
    }

    fn deactivate(&mut self, _: &mut EditorContext) {
        self.reset();
    }

    fn cancel_interaction(&mut self, _: &mut EditorContext) {
        self.reset();
    }

    fn on_pointer_down(&mut self, ctx: &mut EditorContext, world: Point, _: &Camera, _: Modifiers) -> bool {
        self.step(ctx, |s, core, ctx| (s.on_pointer_down(core, ctx, world), true))
    }

    fn on_pointer_move(&mut self, ctx: &mut EditorContext, world: Point, camera: &Camera, mods: Modifiers) -> bool {
        self.step(ctx, |s, core, ctx| (s.on_pointer_move(core, ctx, world, camera, mods), true))
    }

    fn on_pointer_up(&mut self, ctx: &mut EditorContext, world: Point, _: &Camera, mods: Modifiers) -> bool {
        self.step(ctx, |s, core, ctx| (s.on_pointer_up(core, ctx, world, mods), true))
    }

    fn on_pointer_hover(&mut self, ctx: &mut EditorContext, world: Point, _: &Camera, mods: Modifiers) -> bool {
        self.step(ctx, |s, core, ctx| (s.on_pointer_hover(core, ctx, world, mods), true))
    }

    fn on_double_click(&mut self, ctx: &mut EditorContext, _: Point, _: &Camera) -> bool {
        self.step(ctx, |s, core, ctx| (s.on_double_click(core, ctx), true))
    }

    fn on_key(&mut self, ctx: &mut EditorContext, key: KeyInput) -> bool {
        self.step(ctx, |s, core, ctx| s.on_key(core, ctx, key))
    }
}

impl LineState {
    fn on_pointer_down(&mut self, core: &mut LineCore, ctx: &mut EditorContext, world: Point) -> Next {
        match self {
            LineState::Idle => idle::on_pointer_down(world),
            LineState::Placing(p) => p.on_pointer_down(core, ctx, world),
            _ => Next::Stay,
        }
    }

    fn on_pointer_move(
        &mut self,
        core: &mut LineCore,
        ctx: &mut EditorContext,
        world: Point,
        camera: &Camera,
        mods: Modifiers,
    ) -> Next {
        match self {
            LineState::PendingPointer { start } => pending_pointer::on_pointer_move(*start, core, ctx, world, camera, mods),
            LineState::Dragging { start } => {
                dragging::on_pointer_move(*start, core, ctx, world, mods);
                Next::Stay
            }
            LineState::Placing(p) => p.on_pointer_move(core, ctx, world, mods),
            LineState::Idle => Next::Stay,
        }
    }

    fn on_pointer_up(&mut self, core: &mut LineCore, ctx: &mut EditorContext, world: Point, mods: Modifiers) -> Next {
        match self {
            LineState::PendingPointer { start } => pending_pointer::on_pointer_up(*start, world),
            LineState::Dragging { start } => dragging::on_pointer_up(*start, core, ctx, world, mods),
            LineState::Placing(p) => p.on_pointer_up(core, ctx, world, mods),
            LineState::Idle => Next::Stay,
        }
    }

    fn on_pointer_hover(&mut self, core: &mut LineCore, ctx: &mut EditorContext, world: Point, mods: Modifiers) -> Next {
        match self {
            LineState::Placing(p) => p.on_pointer_hover(core, ctx, world, mods),
            _ => Next::Stay,
        }
    }

    fn on_double_click(&mut self, core: &mut LineCore, ctx: &mut EditorContext) -> Next {
        match self {
            LineState::Placing(p) => core.finish(ctx, &p.points),
            _ => Next::Stay,
        }
    }

    /// Enter/Escape finish a placement (or discard a pending press); other states ignore keys.
    fn on_key(&mut self, core: &mut LineCore, ctx: &mut EditorContext, key: KeyInput) -> (Next, bool) {
        if !matches!(key.key, Key::Enter | Key::Escape) {
            return (Next::Stay, false);
        }
        match self {
            LineState::PendingPointer { .. } => (core.finish(ctx, &[]), true),
            LineState::Placing(p) => (core.finish(ctx, &p.points), true),
            _ => (Next::Stay, false),
        }
    }
}

#[cfg(test)]
mod tests;
