//! Editor commands: the single place keyboard shortcuts, the toolbar and the context menu call.

use crate::state::State;
use rune::Tx;
use squiggle_core::editor::grouping_commands::{
    can_group_selected_nodes, can_ungroup_selected_nodes, group_selected_nodes, ungroup_selected_nodes,
};
use squiggle_core::editor::layer_order_commands::{LayerOrder, can_reorder_selected_nodes, reorder_selected_nodes};
use squiggle_core::editor::selection::selected_siblings;
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::feature_kinds::ImageKind;
use squiggle_core::geom::Point;
use squiggle_core::node::Node;
use squiggle_core::node_layout::center_nodes_at;
use squiggle_core::repositories::clamp_image_world_size;
use squiggle_core::services::clipboard::{
    CLIPBOARD_PREFIX, ClipboardBackend, MAX_PASTED_TEXT_WIDTH, PasteContent, copy_nodes_to_clipboard,
    paste_content_from_text,
};
use squiggle_core::services::duplicate_nodes::{can_duplicate_selected_nodes, duplicate_selected_nodes};
use squiggle_core::tools::create_feature_tool::CreateFeatureTool;
use squiggle_core::tools::create_line_tool::CreateLineTool;
use squiggle_core::tools::create_text_tool::CreateTextTool;
use squiggle_core::tools::select_tool::SelectTool;
use squiggle_core::tools::tool::{Tool, ToolId};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    SetTool(ToolId),
    ToggleToolLock,
    /// Activate the n-th brush while a drawing tool is active and nothing is selected.
    ActivateBrush(usize),
    Reorder(LayerOrder),
    Duplicate,
    Delete,
    ClearSelection,
    SelectAll,
    Copy,
    Cut,
    Paste,
    Undo,
    Redo,
    Group,
    Ungroup,
}

pub fn tool_for(id: ToolId) -> Box<dyn Tool> {
    match id {
        ToolId::Select => Box::new(SelectTool::default()),
        ToolId::Rectangle => Box::new(CreateFeatureTool::rect()),
        ToolId::Circle => Box::new(CreateFeatureTool::circle()),
        ToolId::Line => Box::new(CreateLineTool::new()),
        ToolId::Text => Box::new(CreateTextTool::new()),
    }
}

/// Whether `cmd` currently does anything (menu items grey out when it does not).
pub fn is_enabled(s: &State, cmd: Command) -> bool {
    let (doc, sel) = (&s.ctx.document, &s.ctx.selection);
    match cmd {
        Command::Undo => s.ctx.history.can_undo(),
        Command::Redo => s.ctx.history.can_redo(),
        Command::Duplicate => can_duplicate_selected_nodes(doc, sel),
        Command::Group => can_group_selected_nodes(doc, sel),
        Command::Ungroup => can_ungroup_selected_nodes(doc, sel),
        Command::Reorder(order) => can_reorder_selected_nodes(doc, sel, order),
        Command::Delete | Command::Copy | Command::Cut => sel.is_not_empty(),
        _ => true,
    }
}

struct TxClipboard<'a>(&'a mut Tx);

impl ClipboardBackend for TxClipboard<'_> {
    fn read_text(&mut self) -> Option<String> {
        None
    }

    fn write_text(&mut self, text: &str) -> bool {
        self.0.copy(text);
        true
    }
}

pub fn run(s: &mut State, tx: &mut Tx, cmd: Command) {
    if s.ctx.text_edit.session().is_some() {
        return;
    }
    match cmd {
        Command::SetTool(id) => s.ctx.set_tool(tool_for(id)),
        Command::ToggleToolLock => s.ctx.tool.toggle_lock(),
        Command::ActivateBrush(i) => activate_brush(s, i),
        Command::Reorder(order) => {
            let State { ctx, .. } = s;
            let _ = reorder_selected_nodes(&mut ctx.document, &mut ctx.history, &ctx.selection, order);
        }
        Command::Duplicate => {
            s.ctx.cancel_interaction();
            let State { ctx, .. } = s;
            let _ = duplicate_selected_nodes(&mut ctx.document, &mut ctx.history, &mut ctx.selection);
        }
        Command::Delete => delete_selected(s),
        Command::ClearSelection => s.ctx.selection.clear_selection(),
        Command::SelectAll => {
            let ids: Vec<_> = s.ctx.document.nodes().iter().map(Node::id).collect();
            s.ctx.selection.set_selection(ids);
        }
        Command::Copy => {
            copy_selected(s, tx);
        }
        Command::Cut => {
            if copy_selected(s, tx) {
                delete_selected(s);
            }
        }
        Command::Paste => tx.read_clipboard(|s: &mut State, content, _tx| paste(s, content)),
        Command::Undo => s.ctx.undo(),
        Command::Redo => s.ctx.redo(),
        Command::Group => {
            s.ctx.cancel_interaction();
            let State { ctx, .. } = s;
            let _ = group_selected_nodes(&mut ctx.document, &mut ctx.history, &mut ctx.selection);
        }
        Command::Ungroup => {
            s.ctx.cancel_interaction();
            let State { ctx, .. } = s;
            let _ = ungroup_selected_nodes(&mut ctx.document, &mut ctx.history, &mut ctx.selection);
        }
    }
    s.after_edit(tx);
}

fn activate_brush(s: &mut State, index: usize) {
    let drawing = s.ctx.tool.active().is_some_and(|t| t.create_drawing_kind().is_some());
    let id = s.ctx.document.session.brushes.get(index).map(|b| b.id.clone());
    if let (true, true, Some(id)) = (drawing, s.ctx.selection.is_empty(), id) {
        let State { ctx, .. } = s;
        ctx.brushes.activate(&mut ctx.document.session, &id);
        ctx.refresh_brush_preview();
    }
}

fn delete_selected(s: &mut State) {
    s.ctx.cancel_interaction();
    let State { ctx, .. } = s;
    if let Some((container, ids)) = selected_siblings(&ctx.document, &ctx.selection) {
        let _ = ctx.history.run(&mut ctx.document, "Delete", container, |tx| tx.remove_all(&ids));
    }
    ctx.selection.clear_selection();
}

fn copy_selected(s: &mut State, tx: &mut Tx) -> bool {
    let ids = s.ctx.selection.selected_node_ids();
    let nodes: Vec<Node> = s.ctx.document.nodes().iter().filter(|n| ids.contains(&n.id())).cloned().collect();
    copy_nodes_to_clipboard(&nodes, &s.images, &mut TxClipboard(tx)).unwrap_or(false)
}

fn paste(s: &mut State, content: &rune::ClipboardContent) {
    let Some(center) = s.ctx.world_center_at_viewport_center() else { return };
    let mut nodes = nodes_for_paste(s, content);
    if nodes.is_empty() {
        return;
    }
    center_nodes_at(&mut nodes, center);
    s.ctx.cancel_interaction();
    let State { ctx, .. } = s;
    let mut ids = Vec::new();
    let _ = ctx.history.run(&mut ctx.document, "Paste", None, |tx| {
        for node in nodes {
            ids.push(tx.add(node, None)?);
        }
        Ok(())
    });
    ctx.selection.set_selection(ids);
}

fn nodes_for_paste(s: &State, content: &rune::ClipboardContent) -> Vec<Node> {
    match paste_content_from_text(content.text(), &s.images) {
        PasteContent::Nodes(nodes) => nodes,
        PasteContent::Text(text) => {
            let at = |width| s.ctx.new_text_feature(Point::ZERO, &text, width);
            let pasted = at(None);
            vec![if pasted.width() <= MAX_PASTED_TEXT_WIDTH { pasted } else { at(Some(MAX_PASTED_TEXT_WIDTH)) }.into()]
        }
        PasteContent::Empty if content.text().starts_with(CLIPBOARD_PREFIX.trim_end_matches("3:")) => Vec::new(),
        PasteContent::Empty => image_for_paste(s, content).into_iter().collect(),
    }
}

fn image_for_paste(s: &State, content: &rune::ClipboardContent) -> Option<Node> {
    let imported = s.images.import_png_bytes(content.image()?.png())?;
    let mut feature = Feature::new(
        Point::ZERO,
        clamp_image_world_size(imported.intrinsic_size, 1024.0),
        FeatureKind::Image(ImageKind::new(imported.image_id)),
    );
    s.ctx.apply_active_brush(&mut feature.kind);
    Some(feature.into())
}
