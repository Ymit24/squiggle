//! Library header: brand, search field, sort button and the "New canvas" button
//! (`library_header.dart`, `library_top_bar.dart`, `library_search_field.dart`,
//! `library_sort_button.dart`).

use super::sort::DocumentSortMode;
use super::{LibraryUi, Overlay, actions, layout};
use crate::kit::{ButtonVariant, StyledButton};
use crate::menu::{MenuItem, Placement, format_shortcut, is_mac_style, menu_layer};
use crate::state::State;
use crate::text_field::TextField;
use crate::theme;
use rune::tok::TextStyle;
use rune::{El, LineCap, Shape, canvas, col, el, row, text};

pub const SORT_KEY: &str = "library-sort";
pub const SEARCH_KEY: &str = "library-search";

fn brand_mark() -> El {
    let squiggle: Vec<[f32; 2]> = (0..=24)
        .map(|i| {
            let t = i as f32 / 24.0;
            [2.0 + 15.0 * t, 9.5 + 4.0 * (t * std::f32::consts::TAU * 1.5).sin()]
        })
        .collect();
    let shape = Shape::new().stroke_with(squiggle, false, 2.0, LineCap::Round, theme::text());
    el().size(36.0, 36.0).radius(10.0).fill(theme::surface0()).border(1.0, theme::surface1()).center().child(canvas(shape).size(19.0, 19.0))
}

fn brand() -> El {
    row()
        .items_center()
        .gap(12.0)
        .child(brand_mark())
        .child(
            col()
                .child(text("Squiggle").font(TextStyle::new(14.5, 700.0)).color(theme::text()))
                .child(text("Canvas library").font(TextStyle::new(11.0, 500.0)).color(theme::subtext())),
        )
}

fn search_icon() -> El {
    let c = theme::subtext();
    let ring: Vec<[f32; 2]> = (0..16)
        .map(|i| {
            let a = i as f32 / 16.0 * std::f32::consts::TAU;
            [7.0 + 4.5 * a.cos(), 7.0 + 4.5 * a.sin()]
        })
        .collect();
    let shape = Shape::new().stroke_with(ring, true, 1.5, LineCap::Round, c).line([10.5, 10.5], [14.5, 14.5], 1.5, LineCap::Round, c);
    el().w(36.0).h(38.0).center().child(canvas(shape).size(17.0, 17.0))
}

fn search_suffix(has_query: bool) -> El {
    if has_query {
        return el()
            .key("library-search-clear")
            .role("button")
            .label("Clear search")
            .size(42.0, layout::HEADER_CONTROL_HEIGHT)
            .center()
            .focusable(true)
            .child(text("×").font(TextStyle::new(17.0, 400.0)).color(theme::subtext()))
            .on_press(actions::clear_search);
    }
    let hint = format_shortcut("⌘/", is_mac_style());
    el().pr(10.0).child(
        el().px(6.0).py(3.0).radius(5.0).fill(theme::surface1()).child(text(hint).font(TextStyle::new(10.0, 500.0)).color(theme::subtext())),
    )
}

fn search_field(ui: &LibraryUi) -> El {
    TextField::new(SEARCH_KEY, "Search canvases…")
        .compact(true)
        .prefix(search_icon())
        .suffix(search_suffix(!ui.search.text.is_empty()))
        .build::<State>(&ui.search, |s| &mut s.library_ui.search, None)
}

fn sort_button(mode: DocumentSortMode, compact: bool) -> El {
    StyledButton::new(SORT_KEY, mode.button_label(), ButtonVariant::Secondary)
        .glyph("↕")
        .compact(compact)
        .build(|s: &mut State| s.library_ui.overlay = Overlay::Sort)
}

pub fn view(ui: &LibraryUi) -> El {
    let compact = layout::is_compact(ui.window.0);
    let pad = layout::horizontal_padding(ui.window.0);
    let search = search_field(ui);
    let mut bar = row().w_full().max_w(layout::MAX_WIDTH).items_center().gap(10.0).px(pad).py(14.0).child(brand());
    bar = if compact { bar.child(el().w(2.0)).child(el().grow(1.0).min_w(0.0).child(search)) } else { bar.child(el().grow(1.0)).child(el().w(250.0).child(search)) };
    bar = bar.child(sort_button(ui.sort, compact)).child(
        StyledButton::new("library-new", "New canvas", ButtonVariant::Primary)
            .glyph("+")
            .compact(compact)
            .build(actions::open_new_dialog),
    );
    col()
        .key("library-header")
        .w_full()
        .items_center()
        .fill(theme::base())
        .child(bar)
        .child(el().w_full().h(1.0).fill(theme::surface0()))
}

/// The sort dropdown (`LibrarySortButton`'s menu), open under the sort button.
pub fn sort_menu(current: DocumentSortMode) -> El {
    let item = |key: &'static str, label: &'static str, mode: DocumentSortMode| {
        MenuItem::new(key, label, move |s: &mut State| s.library_ui.sort = mode).checked(current == mode)
    };
    let items = vec![
        item("sort-recent", "Last edited", DocumentSortMode::Recent),
        item("sort-oldest", "Oldest first", DocumentSortMode::Oldest),
        item("sort-name", "Name A–Z", DocumentSortMode::Name),
    ];
    menu_layer("sort-menu", items, Placement::Below { anchor: SORT_KEY.into() }, actions::close_overlay)
}

