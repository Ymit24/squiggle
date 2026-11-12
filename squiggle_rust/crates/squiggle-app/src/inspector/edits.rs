//! Selection edits as single undoable history entries (the `history.run('Inspector Update', ..)`
//! calls of the Dart inspector).

use squiggle_core::editor::context::EditorContext;
use squiggle_core::feature::Feature;
use squiggle_core::ids::{Container, NodeId};

/// Selected nodes grouped by container, in selection order.
fn ids_by_container(ctx: &EditorContext, only_features: bool) -> Vec<(Container, Vec<NodeId>)> {
    let mut groups: Vec<(Container, Vec<NodeId>)> = Vec::new();
    for &id in ctx.selection.selected_node_ids() {
        let Some(node) = ctx.document.node(id) else { continue };
        if only_features && node.as_feature().is_none() {
            continue;
        }
        let Some(container) = ctx.document.parent_of(id) else { continue };
        match groups.iter_mut().find(|(c, _)| *c == container) {
            Some((_, ids)) => ids.push(id),
            None => groups.push((container, vec![id])),
        }
    }
    groups
}

/// Runs `edit` on every selected feature inside one history entry labelled `label`. Features in
/// different containers cannot share an entry, so each container gets its own.
pub fn edit_selected_features(ctx: &mut EditorContext, label: &str, edit: impl Fn(&mut Feature)) {
    for (container, ids) in ids_by_container(ctx, true) {
        let result = ctx.history.run(&mut ctx.document, label, container, |tx| {
            tx.watch(&ids)?;
            for &id in &ids {
                if let Some(feature) = tx.doc_mut().feature_mut(id) {
                    edit(feature);
                }
            }
            Ok(())
        });
        // A transaction already in progress (mid-gesture) simply refuses the edit.
        drop(result);
    }
}
