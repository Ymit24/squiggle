//! Inline text editing state: the active session, its draft text, and the commit command.
//!
//! Kind-specific parts (reading/writing a label, computing the label layout) belong to the feature
//! kinds, which are ported separately; they are passed in by the caller.

use super::history::{History, HistoryError};
use super::selection::Selection;
use crate::document::Document;
use crate::feature::Feature;
use crate::geom::Rect;
use crate::ids::NodeId;

/// What is being typed into.
#[derive(Clone, Debug, PartialEq)]
pub enum TextEditKind {
    /// Text being typed into a feature that is not in the document yet. `draft` is styled and
    /// placed once when the edit starts; committing sets its label and inserts it.
    Create { draft: Feature },
    /// Editing the label of a document feature.
    Edit { feature_id: NodeId },
}

#[derive(Clone, Debug, PartialEq)]
pub struct TextEditSession {
    pub kind: TextEditKind,
    pub initial_contents: String,
    /// Where the edited text is typeset, in document (root) world coordinates.
    // TODO(integrate): becomes `LabelLayout` once the kinds area provides it.
    pub layout: Rect,
}

impl TextEditSession {
    /// `layout` must already be shifted into root coordinates (`label_layout.shifted(global_origin)`).
    pub fn edit(feature_id: NodeId, initial_contents: impl Into<String>, layout: Rect) -> Self {
        TextEditSession { kind: TextEditKind::Edit { feature_id }, initial_contents: initial_contents.into(), layout }
    }

    pub fn create(draft: Feature, layout: Rect) -> Self {
        TextEditSession { kind: TextEditKind::Create { draft }, initial_contents: String::new(), layout }
    }

    pub fn feature_id(&self) -> Option<NodeId> {
        match self.kind {
            TextEditKind::Edit { feature_id } => Some(feature_id),
            TextEditKind::Create { .. } => None,
        }
    }
}

/// State of the active text edit session, if any.
#[derive(Clone, Debug, Default)]
pub struct TextEditModel {
    session: Option<TextEditSession>,
    /// Feature whose label is hidden on the canvas because the inline editor draws it instead.
    label_hidden: Option<NodeId>,
    /// What the text field currently contains; kept here so anything that ends the edit can
    /// commit it.
    pub draft: String,
}

impl TextEditModel {
    pub fn new() -> Self {
        TextEditModel::default()
    }

    pub fn session(&self) -> Option<&TextEditSession> {
        self.session.as_ref()
    }

    /// Whether the text of node `id` is being edited right now.
    pub fn is_editing(&self, id: NodeId) -> bool {
        self.session.as_ref().and_then(TextEditSession::feature_id) == Some(id)
    }

    pub fn begin(&mut self, doc: &mut Document, session: TextEditSession) {
        self.show_hidden_label(doc);
        self.draft = session.initial_contents.clone();
        if let Some(id) = session.feature_id()
            && let Some(feature) = doc.feature_mut(id)
        {
            feature.hide_label = true;
            self.label_hidden = Some(id);
        }
        self.session = Some(session);
    }

    pub fn end(&mut self, doc: &mut Document) {
        if self.session.take().is_some() {
            self.show_hidden_label(doc);
        }
    }

    fn show_hidden_label(&mut self, doc: &mut Document) {
        if let Some(id) = self.label_hidden.take()
            && let Some(feature) = doc.feature_mut(id)
        {
            feature.hide_label = false;
        }
    }
}

/// Applies `contents` (default: the field's current draft) as one undoable step and closes the
/// text edit. Does nothing when no edit is open, which happens when several commit triggers fire
/// for the same click. Returns the id of a newly created feature.
///
/// `set_label` writes the label on the feature's kind (and resizes content-sized kinds); it should
/// do nothing for kinds without labels. Set `select_created` to false when the commit comes from
/// a click that picks the selection itself.
pub fn commit_text_edit(
    doc: &mut Document,
    history: &mut History,
    selection: &mut Selection,
    text_edit: &mut TextEditModel,
    contents: Option<&str>,
    select_created: bool,
    set_label: impl FnOnce(&mut Feature, &str),
) -> Result<Option<NodeId>, HistoryError> {
    let Some(session) = text_edit.session().cloned() else { return Ok(None) };
    let text = contents.map_or_else(|| text_edit.draft.clone(), str::to_owned);
    let mut created = None;

    match session.kind {
        TextEditKind::Edit { feature_id } => {
            // Close the session first so the inline-editor flag is not part of the snapshot.
            text_edit.end(doc);
            let container = doc.parent_of(feature_id).flatten();
            history.run(doc, "Edit text", container, |tx| {
                tx.update(feature_id, |node| {
                    if let Some(feature) = node.as_feature_mut() {
                        set_label(feature, &text);
                    }
                })
            })?;
        }
        TextEditKind::Create { mut draft } => {
            if !text.is_empty() {
                set_label(&mut draft, &text);
                let id = history.run(doc, "Create text", None, |tx| tx.add(draft, None))?;
                if select_created {
                    selection.set_selection([id]);
                }
                created = Some(id);
            }
        }
    }
    text_edit.end(doc);
    Ok(created)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::test_util::rect_at;
    use crate::feature_kind::FeatureKind;
    use crate::geom::{Point, Size};

    /// Stands in for a label-capable kind: stores the text in the (stub) kind's raw JSON.
    fn set_label(feature: &mut Feature, text: &str) {
        if let FeatureKind::Rectangle(k) = &mut feature.kind {
            k.raw["label"] = text.into();
        }
    }

    fn label(doc: &Document, id: NodeId) -> Option<String> {
        match &doc.feature(id)?.kind {
            FeatureKind::Rectangle(k) => k.raw.get("label").and_then(|v| v.as_str()).map(str::to_owned),
            _ => None,
        }
    }

    struct Fixture {
        doc: Document,
        history: History,
        selection: Selection,
        edit: TextEditModel,
        id: NodeId,
    }

    fn fixture() -> Fixture {
        let mut doc = Document::default();
        let id = doc.insert(None, rect_at(0.0, 0.0), None).unwrap();
        Fixture { doc, history: History::new(), selection: Selection::new(), edit: TextEditModel::new(), id }
    }

    fn commit(f: &mut Fixture, contents: Option<&str>, select: bool) -> Option<NodeId> {
        commit_text_edit(&mut f.doc, &mut f.history, &mut f.selection, &mut f.edit, contents, select, set_label)
            .unwrap()
    }

    #[test]
    fn edit_updates_label_as_one_undoable_command() {
        let mut f = fixture();
        f.edit.begin(&mut f.doc, TextEditSession::edit(f.id, "initial", Rect::ZERO));
        assert!(f.edit.is_editing(f.id));
        assert!(f.doc.feature(f.id).unwrap().hide_label);

        commit(&mut f, Some("updated text"), true);

        assert!(f.edit.session().is_none());
        assert!(!f.doc.feature(f.id).unwrap().hide_label);
        assert_eq!(label(&f.doc, f.id).as_deref(), Some("updated text"));
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(label(&f.doc, f.id), None);
        assert!(!f.doc.feature(f.id).unwrap().hide_label);
        f.history.redo(&mut f.doc).unwrap();
        assert_eq!(label(&f.doc, f.id).as_deref(), Some("updated text"));
    }

    #[test]
    fn edit_uses_draft_when_contents_omitted() {
        let mut f = fixture();
        f.edit.begin(&mut f.doc, TextEditSession::edit(f.id, "", Rect::ZERO));
        f.edit.draft = "from draft".into();
        commit(&mut f, None, true);
        assert_eq!(label(&f.doc, f.id).as_deref(), Some("from draft"));
    }

    #[test]
    fn unchanged_edit_adds_no_history_entry() {
        let mut f = fixture();
        f.edit.begin(&mut f.doc, TextEditSession::edit(f.id, "", Rect::ZERO));
        commit_text_edit(&mut f.doc, &mut f.history, &mut f.selection, &mut f.edit, Some("x"), true, |_, _| {}).unwrap();
        assert!(!f.history.can_undo());
        assert!(f.edit.session().is_none());
    }

    #[test]
    fn create_inserts_draft_and_selects_it() {
        let mut f = fixture();
        let draft = Feature::new(Point::new(5.0, 6.0), Size::new(10.0, 10.0), FeatureKind::default());
        f.edit.begin(&mut f.doc, TextEditSession::create(draft, Rect::ZERO));
        let id = commit(&mut f, Some("new text"), true).unwrap();
        assert_eq!(f.doc.nodes().len(), 2);
        assert_eq!(label(&f.doc, id).as_deref(), Some("new text"));
        assert_eq!(f.selection.selected_node_ids(), &[id]);
        f.history.undo(&mut f.doc).unwrap();
        assert_eq!(f.doc.nodes().len(), 1);
    }

    #[test]
    fn create_without_select_leaves_selection_alone() {
        let mut f = fixture();
        f.selection.set_selection([f.id]);
        let draft = Feature::new(Point::ZERO, Size::new(10.0, 10.0), FeatureKind::default());
        f.edit.begin(&mut f.doc, TextEditSession::create(draft, Rect::ZERO));
        commit(&mut f, Some("t"), false).unwrap();
        assert_eq!(f.selection.selected_node_ids(), &[f.id]);
    }

    #[test]
    fn empty_create_does_nothing_but_close() {
        let mut f = fixture();
        let draft = Feature::new(Point::ZERO, Size::new(10.0, 10.0), FeatureKind::default());
        f.edit.begin(&mut f.doc, TextEditSession::create(draft, Rect::ZERO));
        assert_eq!(commit(&mut f, Some(""), true), None);
        assert_eq!(f.doc.nodes().len(), 1);
        assert!(!f.history.can_undo());
        assert!(f.edit.session().is_none());
    }

    #[test]
    fn commit_without_session_is_a_no_op() {
        let mut f = fixture();
        assert_eq!(commit(&mut f, Some("x"), true), None);
        assert!(!f.history.can_undo());
    }

    #[test]
    fn beginning_a_new_session_unhides_the_previous_label() {
        let mut f = fixture();
        let other = f.doc.insert(None, rect_at(50.0, 0.0), None).unwrap();
        f.edit.begin(&mut f.doc, TextEditSession::edit(f.id, "", Rect::ZERO));
        f.edit.begin(&mut f.doc, TextEditSession::edit(other, "", Rect::ZERO));
        assert!(!f.doc.feature(f.id).unwrap().hide_label);
        assert!(f.doc.feature(other).unwrap().hide_label);
        f.edit.end(&mut f.doc);
        assert!(!f.doc.feature(other).unwrap().hide_label);
    }
}
