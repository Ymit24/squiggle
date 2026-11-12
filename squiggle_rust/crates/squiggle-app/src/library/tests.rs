//! Headless widget tests for the library page (ports of `library_menu_test`, `menu_layout_test`
//! and `squiggle_shortcut_hint_test` plus page flows).

use super::*;
use crate::state::Page;
use rune::{Env, Key, KeyEvent, Mods, Runtime};
use squiggle_core::feature_kinds::rectangle::RectangleKind;
use squiggle_core::geom::{Point, Size};
use squiggle_core::{Feature, FeatureKind, Node};

fn temp_dir(name: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!("squiggle_library_{name}_{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    dir
}

fn app_with(name: &str, docs: &[&str]) -> Runtime<State> {
    let mut state = State::new(temp_dir(name));
    for d in docs {
        state.library.create_document(Some(d), &mut state.ctx);
    }
    open_library(&mut state);
    let mut rt = Runtime::new(state, view, (1100.0, 760.0), Env::new(true, 1.0));
    rt.on_key = Some(on_key);
    rt.frame(0.0);
    rt.frame(0.0);
    rt
}

fn app(name: &str) -> Runtime<State> {
    app_with(name, &["Alpha", "Beta"])
}

fn settle(rt: &mut Runtime<State>) {
    for _ in 0..600 {
        if !rt.frame(1.0 / 60.0) && !rt.has_pending_input() {
            return;
        }
    }
    panic!("never settled");
}

fn click(rt: &mut Runtime<State>, key: &str) {
    settle(rt);
    let (x, y) = rt.find(key).unwrap_or_else(|| panic!("no element {key}"));
    rt.pointer_move(x, y);
    rt.pointer_down(x, y);
    rt.pointer_up(x, y);
    settle(rt);
}

fn has(rt: &Runtime<State>, key: &str) -> bool {
    rt.find(key).is_some()
}

fn id_of(rt: &Runtime<State>, name: &str) -> String {
    rt.state.library.documents().iter().find(|d| d.name == name).unwrap().id.clone()
}

fn press(rt: &mut Runtime<State>, key: Key, mods: Mods) {
    rt.key(KeyEvent { key, mods });
    settle(rt);
}

fn texts(rt: &Runtime<State>) -> Vec<String> {
    rt.elements().into_iter().filter_map(|e| e.text).collect()
}

fn card_count(rt: &Runtime<State>) -> usize {
    rt.state
        .library
        .documents()
        .iter()
        .filter(|d| has(rt, &card::card_key(&d.id)))
        .count()
}

#[test]
fn open_library_shows_the_page_with_every_document_and_a_new_card() {
    let rt = app("list");
    assert_eq!(rt.state.page, Page::Library);
    assert!(has(&rt, "new-card"));
    assert_eq!(card_count(&rt), 3);
    let shown = texts(&rt);
    assert!(shown.iter().any(|t| t == "Alpha") && shown.iter().any(|t| t == "Beta"), "{shown:?}");
    assert!(shown.iter().any(|t| t == "Edited just now"));
    assert!(shown.iter().any(|t| t == "Current"));
}

#[test]
fn clicking_a_card_opens_that_document_in_the_editor() {
    let mut rt = app("open");
    let alpha = id_of(&rt, "Alpha");
    click(&mut rt, &card::card_key(&alpha));
    assert_eq!(rt.state.page, Page::Editor);
    assert_eq!(rt.state.library.current_document().unwrap().id, alpha);
    assert_eq!(rt.state.ctx.document.name, "Alpha");
}

#[test]
fn new_card_creates_and_opens_an_untitled_document() {
    let mut rt = app("new");
    click(&mut rt, "new-card");
    assert_eq!(rt.state.page, Page::Editor);
    assert_eq!(rt.state.library.documents().len(), 4);
    assert!(rt.state.library.current_document().unwrap().name.starts_with("Untitled"));
}

#[test]
fn header_button_asks_for_a_name_first() {
    let mut rt = app("named");
    click(&mut rt, "library-new");
    assert!(has(&rt, "name-dialog"));
    assert_eq!(rt.state.library_ui.name.text, "Untitled");
    rt.update(|s, _| s.library_ui.name.replace_text("Sketchbook"));
    settle(&mut rt);
    click(&mut rt, "dialog-confirm");
    assert_eq!(rt.state.page, Page::Editor);
    assert_eq!(rt.state.library.current_document().unwrap().name, "Sketchbook");
}

#[test]
fn name_dialog_confirm_is_disabled_for_blank_names() {
    let mut rt = app("blank");
    click(&mut rt, "library-new");
    rt.update(|s, _| s.library_ui.name.replace_text("   "));
    settle(&mut rt);
    click(&mut rt, "dialog-confirm");
    assert_eq!(rt.state.page, Page::Library);
    assert!(has(&rt, "name-dialog"));
    click(&mut rt, "dialog-cancel");
    assert!(!has(&rt, "name-dialog"));
    assert_eq!(rt.state.library.documents().len(), 3);
}

#[test]
fn search_filters_cards_and_reports_empty_results() {
    let mut rt = app("search");
    rt.update(|s, _| s.library_ui.search.replace_text("alp"));
    settle(&mut rt);
    assert_eq!(card_count(&rt), 1);
    assert!(!has(&rt, "new-card"), "the new-document card hides while searching");
    rt.update(|s, _| s.library_ui.search.replace_text("zzz"));
    settle(&mut rt);
    assert!(has(&rt, "empty-results"));
    assert!(texts(&rt).iter().any(|t| t == "No canvases found"));
    click(&mut rt, "empty-clear");
    assert!(rt.state.library_ui.search.text.is_empty());
    assert_eq!(card_count(&rt), 3);
}

#[test]
fn sort_menu_changes_the_sort_and_closes() {
    let mut rt = app("sort");
    click(&mut rt, header::SORT_KEY);
    assert!(has(&rt, "sort-menu"));
    click(&mut rt, "sort-oldest");
    assert_eq!(rt.state.library_ui.sort, DocumentSortMode::Oldest);
    assert!(!has(&rt, "sort-menu"));
    assert!(texts(&rt).iter().any(|t| t == "Oldest"));
    assert!(!texts(&rt).iter().any(|t| t == "Oldest first"));
}

#[test]
fn sort_menu_supports_keyboard_selection() {
    let mut rt = app("sort_keys");
    click(&mut rt, header::SORT_KEY);
    let (x, y) = rt.find("sort-recent").unwrap();
    rt.pointer_move(x, y);
    settle(&mut rt);
    press(&mut rt, Key::Down, Mods::default());
    press(&mut rt, Key::Enter, Mods::default());
    assert_eq!(rt.state.library_ui.sort, DocumentSortMode::Oldest);
    assert!(!has(&rt, "sort-menu"));
}

#[test]
fn escape_and_outside_press_dismiss_menus() {
    let mut rt = app("dismiss");
    click(&mut rt, header::SORT_KEY);
    press(&mut rt, Key::Escape, Mods::default());
    assert_eq!(rt.state.library_ui.overlay, Overlay::None);
    click(&mut rt, header::SORT_KEY);
    assert!(has(&rt, "sort-menu"));
    rt.pointer_move(5.0, 700.0);
    rt.pointer_down(5.0, 700.0);
    rt.pointer_up(5.0, 700.0);
    settle(&mut rt);
    assert_eq!(rt.state.library_ui.overlay, Overlay::None);
    assert_eq!(rt.state.page, Page::Library, "the outside press did not open a card");
}

#[test]
fn card_menu_actions_dismiss_before_opening_the_rename_dialog() {
    let mut rt = app("rename");
    let alpha = id_of(&rt, "Alpha");
    let card = card::card_key(&alpha);
    let (x, y) = rt.find(&card).unwrap();
    rt.pointer_move(x, y);
    settle(&mut rt);
    click(&mut rt, &card::menu_button_key(&alpha));
    assert!(has(&rt, "card-menu"));
    click(&mut rt, "menu-rename");
    assert!(!has(&rt, "card-menu"));
    assert!(has(&rt, "name-dialog"));
    assert_eq!(rt.state.library_ui.name.text, "Alpha");
    rt.update(|s, _| s.library_ui.name.replace_text("Gamma"));
    settle(&mut rt);
    click(&mut rt, "dialog-confirm");
    assert!(!has(&rt, "name-dialog"));
    assert!(rt.state.library.documents().iter().any(|d| d.name == "Gamma"));
    assert!(!rt.state.library.documents().iter().any(|d| d.name == "Alpha"));
}

#[test]
fn context_menu_deletes_after_confirmation() {
    let mut rt = app("delete");
    let alpha = id_of(&rt, "Alpha");
    let (x, y) = rt.find(&card::card_key(&alpha)).unwrap();
    rt.secondary_down(x, y);
    rt.secondary_up(x, y);
    settle(&mut rt);
    assert!(has(&rt, "context-menu"));
    click(&mut rt, "menu-delete");
    assert!(has(&rt, "delete-dialog"));
    assert!(texts(&rt).iter().any(|t| t.contains("\"Alpha\" will be permanently deleted")));
    click(&mut rt, "dialog-confirm");
    assert_eq!(rt.state.library.documents().len(), 2);
    assert!(!has(&rt, "delete-dialog"));
}

#[test]
fn cancelling_the_delete_dialog_keeps_the_document() {
    let mut rt = app("delete_cancel");
    let alpha = id_of(&rt, "Alpha");
    rt.update(|s, _| open_delete_dialog(s, &alpha));
    settle(&mut rt);
    click(&mut rt, "dialog-cancel");
    assert_eq!(rt.state.library.documents().len(), 3);
}

#[test]
fn the_last_document_cannot_be_deleted_from_the_menu() {
    let mut rt = app_with("last", &[]);
    assert_eq!(rt.state.library.documents().len(), 1);
    let only = rt.state.library.documents()[0].id.clone();
    let (x, y) = rt.find(&card::card_key(&only)).unwrap();
    rt.secondary_down(x, y);
    rt.secondary_up(x, y);
    settle(&mut rt);
    assert!(has(&rt, "menu-rename") && !has(&rt, "menu-delete"));
}

#[test]
fn context_menu_stays_inside_the_window() {
    let mut rt = app("ctx_clamp");
    let alpha = id_of(&rt, "Alpha");
    rt.update(|s, _| s.library_ui.overlay = Overlay::Context { id: alpha, x: 1095.0, y: 755.0 });
    settle(&mut rt);
    let panel = rt.elements().into_iter().find(|e| e.key.as_deref() == Some("context-menu")).unwrap().rect;
    assert!(panel[0] + panel[2] <= 1100.0 && panel[1] + panel[3] <= 760.0, "{panel:?}");
}

#[test]
fn keyboard_shortcut_creates_a_document_and_slash_focuses_search() {
    let mut rt = app("keys");
    let mods = Mods { cmd: true, ctrl: true, ..Mods::default() };
    press(&mut rt, Key::Text("/".into()), mods);
    assert!(rt.state.library_ui.search.focused);
    press(&mut rt, Key::Text("n".into()), mods);
    assert_eq!(rt.state.page, Page::Editor);
    assert_eq!(rt.state.library.documents().len(), 4);
}

#[test]
fn open_library_saves_the_open_document_and_previews_its_content() {
    let mut state = State::new(temp_dir("preview"));
    let rect = Feature::new(Point::new(0.0, 0.0), Size::new(200.0, 100.0), FeatureKind::Rectangle(RectangleKind::default()));
    state.ctx.document.insert(None, Node::Feature(rect), None).unwrap();
    state.page = Page::Editor;
    open_library(&mut state);
    assert_eq!(state.page, Page::Library);
    let id = state.library.current_document().unwrap().id.clone();
    let loaded = state.library.storage().load_document(&id).unwrap();
    assert_eq!(loaded.document.nodes().len(), 1, "the edit was saved");
    let mut rt = Runtime::new(state, view, (1100.0, 760.0), Env::new(true, 1.0));
    settle(&mut rt);
    assert!(has(&rt, &format!("card-preview-{id}-art")), "a drawing canvas is present");
}

#[test]
fn empty_documents_show_the_placeholder_glyph_instead_of_a_drawing() {
    let rt = app("empty_preview");
    let id = rt.state.library.documents()[0].id.clone();
    assert!(!has(&rt, &format!("card-preview-{id}-art")));
}

#[test]
fn compact_windows_use_icon_only_header_buttons() {
    let mut state = State::new(temp_dir("compact"));
    open_library(&mut state);
    let mut rt = Runtime::new(state, view, (600.0, 700.0), Env::new(true, 1.0));
    settle(&mut rt);
    let new_button = rt.elements().into_iter().find(|e| e.key.as_deref() == Some("library-new")).unwrap();
    assert_eq!(new_button.rect[2], 38.0);
}

#[test]
fn returning_from_the_editor_resets_search_and_lists_everything() {
    let mut rt = app("roundtrip");
    let beta = id_of(&rt, "Beta");
    click(&mut rt, &card::card_key(&beta));
    rt.update(|s, _| open_library(s));
    settle(&mut rt);
    assert_eq!(rt.state.library_ui.search.text, "");
    assert_eq!(card_count(&rt), 3);
}
