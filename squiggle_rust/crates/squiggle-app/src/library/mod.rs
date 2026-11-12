//! Document library page (`lib/document_library`). `view` is shown when `Page::Library` is
//! active; [`open_library`] switches to it from the editor.
//!
//! Left out of the port: hover/focus animations, the preview loading shimmer (previews load
//! synchronously and are cached by document id and modification time), image nodes in previews,
//! and local-time-zone dates (labels use UTC).

mod actions;
mod card;
mod header;
mod layout;
mod preview;
mod sort;
mod time;
mod dialogs;

#[allow(unused_imports)]
pub use actions::{
    close_overlay, create_and_open, delete_document, open_delete_dialog, open_document, open_library, open_new_dialog,
    open_rename_dialog, rename_document,
};
pub use sort::DocumentSortMode;

use crate::menu::{MenuItem, Placement, menu_layer};
use crate::state::State;
use crate::theme;
use preview::Preview;
use rune::{Chord, Cx, El, ScrollSpec, col, row};
use squiggle_core::repositories::{DocumentInfo, DocumentLibraryRepository};
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::time::SystemTime;

/// What is floating over the library page.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum Overlay {
    #[default]
    None,
    Sort,
    /// The "…" button's menu under a card.
    CardMenu(String),
    /// Right-click menu at a window point.
    Context { id: String, x: f32, y: f32 },
    NewDialog,
    RenameDialog(String),
    DeleteDialog(String),
}

pub struct LibraryUi {
    pub search: rune::TextEdit,
    pub sort: DocumentSortMode,
    pub overlay: Overlay,
    /// The new/rename dialog's name field.
    pub name: rune::TextEdit,
    /// Window size in points, from the page's layout.
    pub window: (f32, f32),
    /// Card under the pointer.
    pub hovered: Option<String>,
    /// Clock override for tests.
    pub now: Option<SystemTime>,
    previews: RefCell<HashMap<String, (SystemTime, Rc<Preview>)>>,
}

impl Default for LibraryUi {
    fn default() -> Self {
        LibraryUi {
            search: rune::TextEdit::new(""),
            sort: DocumentSortMode::default(),
            overlay: Overlay::None,
            name: rune::TextEdit::new(""),
            window: (1100.0, 760.0),
            hovered: None,
            now: None,
            previews: RefCell::default(),
        }
    }
}

impl LibraryUi {
    fn now(&self) -> SystemTime {
        self.now.unwrap_or_else(SystemTime::now)
    }

    /// The (cached) preview of `info`, re-read when the document was saved since.
    fn preview(&self, library: &DocumentLibraryRepository, info: &DocumentInfo) -> Rc<Preview> {
        let mut cache = self.previews.borrow_mut();
        if let Some((at, p)) = cache.get(&info.id).filter(|(at, _)| *at == info.updated_at) {
            let _ = at;
            return p.clone();
        }
        let p = Rc::new(Preview::load(library.storage(), &info.id));
        cache.insert(info.id.clone(), (info.updated_at, p.clone()));
        p
    }

    fn forget_preview(&self, id: &str) {
        self.previews.borrow_mut().remove(id);
    }
}

/// Window-level key handler (install via `AppSpec::on_key`): Cmd/Ctrl+N creates a canvas and
/// Cmd/Ctrl+/ focuses the search field. Only acts on the library page with no overlay open.
pub fn on_key(s: &mut State, ev: &rune::KeyEvent, _tx: &mut rune::Tx) -> bool {
    if s.page != crate::state::Page::Library {
        return false;
    }
    let chord = |spec: &str| Chord::parse(spec).is_ok_and(|c| c.matches(ev));
    if s.library_ui.overlay != Overlay::None {
        return false;
    }
    if chord("mod+n") {
        actions::create_and_open(s, None);
    } else if chord("mod+/") {
        s.library_ui.search.focused = true;
    } else {
        return false;
    }
    true
}

fn card_grid(s: &State, docs: &[DocumentInfo], searching: bool) -> El {
    let ui = &s.library_ui;
    let columns = layout::column_count(layout::grid_width(ui.window.0));
    let size = layout::card_size(layout::grid_width(ui.window.0), columns);
    let current = s.library.current_document().map(|d| d.id.as_str());
    let can_delete = s.library.documents().len() > 1;
    let now = ui.now();

    let mut cells: Vec<El> = Vec::new();
    if !searching {
        cells.push(card::new_document_card(size));
    }
    for info in docs {
        let menu_open = matches!(&ui.overlay, Overlay::CardMenu(id) | Overlay::Context { id, .. } if *id == info.id);
        cells.push(card::document_card(card::CardProps {
            info: info.clone(),
            is_current: current == Some(info.id.as_str()),
            can_delete,
            size,
            preview: ui.preview(&s.library, info),
            now,
            elevated: menu_open || ui.hovered.as_deref() == Some(info.id.as_str()),
        }));
    }
    let mut grid = col().key("library-grid").gap(layout::GRID_GAP);
    let mut cells = cells.into_iter().peekable();
    while cells.peek().is_some() {
        let line = cells.by_ref().take(columns).fold(row().gap(layout::GRID_GAP), |r, c| r.child(c));
        grid = grid.child(line);
    }
    grid
}

fn body(s: &State, docs: &[DocumentInfo]) -> El {
    let ui = &s.library_ui;
    let searching = !ui.search.text.trim().is_empty();
    let content = if docs.is_empty() { card::empty_results(searching) } else { card_grid(s, docs, searching) };
    let inner = col().w_full().max_w(layout::MAX_WIDTH).px(layout::horizontal_padding(ui.window.0)).pt(8.0).pb(if docs.is_empty() { 64.0 } else { 56.0 }).child(content);
    col()
        .key("library-scroll")
        .w_full()
        .grow(1.0)
        .min_h(0.0)
        .items_center()
        .scroll(ScrollSpec { stick_bottom: false })
        .child(inner)
}

/// The document actions shared by the card's "…" button and its context menu.
fn card_menu_items(id: &str, can_delete: bool) -> Vec<MenuItem<State>> {
    let rename_id = id.to_owned();
    let mut items = vec![MenuItem::new("menu-rename", "Rename", move |s: &mut State| actions::open_rename_dialog(s, &rename_id))];
    if can_delete {
        let delete_id = id.to_owned();
        items.push(MenuItem::new("menu-delete", "Delete", move |s: &mut State| actions::open_delete_dialog(s, &delete_id)).danger(true));
    }
    items
}

fn overlays(s: &State) -> Vec<El> {
    let ui = &s.library_ui;
    let can_delete = s.library.documents().len() > 1;
    match &ui.overlay {
        Overlay::None => vec![],
        Overlay::Sort => vec![header::sort_menu(ui.sort)],
        Overlay::CardMenu(id) => {
            let placement = Placement::Below { anchor: card::menu_button_key(id) };
            vec![menu_layer("card-menu", card_menu_items(id, can_delete), placement, actions::close_overlay)]
        }
        Overlay::Context { id, x, y } => {
            let placement = Placement::At { x: *x, y: *y, window: ui.window };
            vec![menu_layer("context-menu", card_menu_items(id, can_delete), placement, actions::close_overlay)]
        }
        Overlay::NewDialog => dialogs::name_dialog("New canvas", "Create", ui),
        Overlay::RenameDialog(_) => dialogs::name_dialog("Rename canvas", "Save", ui),
        Overlay::DeleteDialog(id) => {
            let name = s.library.documents().iter().find(|d| d.id == *id).map(|d| d.name.as_str()).unwrap_or_default();
            dialogs::delete_dialog(name)
        }
    }
}

pub fn view(s: &State, _cx: &mut Cx<State>) -> El {
    let ui = &s.library_ui;
    let docs = sort::filter_and_sort(s.library.documents(), &ui.search.text, ui.sort);
    let mut root = col()
        .key("library")
        .w_full()
        .h_full()
        .fill(theme::mantle())
        .on_layout(|s: &mut State, r: [f32; 4]| {
            if s.library_ui.window != (r[2], r[3]) {
                s.library_ui.window = (r[2], r[3]);
            }
        })
        .child(header::view(ui))
        .child(body(s, &docs));
    for layer in overlays(s) {
        root = root.child(layer);
    }
    root
}

#[cfg(test)]
mod tests;
