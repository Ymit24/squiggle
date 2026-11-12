//! Document cards, the new-document card and the empty-results panel
//! (`document_card.dart`, `new_document_card.dart`, `empty_library_results.dart`).

use super::actions;
use super::preview::{self, Preview};
use super::time::format_edited_at;
use super::{Overlay, layout};
use crate::kit::{ButtonVariant, StyledButton, pill};
use crate::menu::{format_shortcut, is_mac_style};
use crate::state::State;
use crate::theme;
use rune::tok::TextStyle;
use rune::{Color, El, PointerPress, Tx, col, el, row, text};
use squiggle_core::repositories::DocumentInfo;
use std::rc::Rc;
use std::time::SystemTime;

pub struct CardProps {
    pub info: DocumentInfo,
    pub is_current: bool,
    pub can_delete: bool,
    pub size: (f32, f32),
    pub preview: Rc<Preview>,
    /// Decoded images the preview's drawing refers to.
    pub images: std::collections::HashMap<String, rune::Image>,
    pub now: SystemTime,
    /// Pointer over the card, keyboard focus on it, or its menu open.
    pub elevated: bool,
}

pub fn card_key(id: &str) -> String {
    format!("card-{id}")
}

pub fn menu_button_key(id: &str) -> String {
    format!("card-menu-{id}")
}

fn card_border(is_current: bool, elevated: bool) -> Color {
    if is_current {
        theme::accent().alpha(0.6)
    } else if elevated {
        theme::accent().alpha(0.45)
    } else {
        theme::surface1()
    }
}

fn footer(info: &DocumentInfo, elevated: bool, now: SystemTime) -> El {
    let arrow = if elevated { theme::text().alpha(0.8) } else { theme::subtext().alpha(0.4) };
    let labels = col()
        .grow(1.0)
        .min_w(0.0)
        .gap(3.0)
        .child(text(info.name.clone()).key("card-name").font(TextStyle::new(14.5, 600.0)).color(theme::text()).truncate())
        .child(
            text(format_edited_at(info.updated_at, now))
                .key("card-time")
                .font(TextStyle::new(11.5, 400.0))
                .color(theme::subtext().alpha(0.85)),
        );
    row()
        .w_full()
        .h(layout::CARD_FOOTER_HEIGHT)
        .items_center()
        .gap(4.0)
        .pl(14.0)
        .pr(10.0)
        .child(labels)
        .child(text("↗").font(TextStyle::new(16.0, 400.0)).color(arrow))
}

pub fn document_card(p: CardProps) -> El {
    let id = p.info.id.clone();
    let (open_id, rename_id, ctx_id, hover_id) = (id.clone(), id.clone(), id.clone(), id.clone());
    let (pw, ph) = layout::preview_size(p.size);

    let mut art = preview::view(&format!("card-preview-{id}"), &p.preview, (pw, ph), &p.images);
    if p.elevated {
        art = art.child(
            el().absolute(0.0, 0.0).size(pw, ph).radius(10.0).gradient(Color::TRANSPARENT, Color::BLACK.alpha(0.42)).inert(),
        );
    }
    if p.is_current {
        art = art.child(el().key(format!("card-badge-{id}")).absolute(8.0, 8.0).inert().child(pill("Current")));
    }
    if p.elevated || p.is_current {
        let menu_id = id.clone();
        let button = StyledButton::new(menu_button_key(&id), "Document actions", ButtonVariant::Secondary)
            .glyph("…")
            .compact(true)
            .build(move |s: &mut State| s.library_ui.overlay = Overlay::CardMenu(menu_id.clone()));
        art = art.child(el().absolute(pw - 8.0 - layout::HEADER_CONTROL_HEIGHT, 8.0).child(button));
    }

    col()
        .key(card_key(&id))
        .role("button")
        .label(p.info.name.clone())
        .size(p.size.0, p.size.1)
        .radius(16.0)
        .fill(theme::base())
        .border(1.0, card_border(p.is_current, p.elevated))
        .shadow(
            if p.elevated { 14.0 } else { 4.0 },
            if p.elevated { 28.0 } else { 12.0 },
            Color::BLACK.alpha(if p.elevated { 0.45 } else { 0.28 }),
        )
        .focusable(true)
        .child(el().pl(layout::PREVIEW_INSET).pr(layout::PREVIEW_INSET).pt(layout::PREVIEW_INSET).child(art))
        .child(footer(&p.info, p.elevated, p.now))
        .on_press(move |s: &mut State| actions::open_document(s, &open_id))
        .on_double_press(move |s: &mut State| actions::open_rename_dialog(s, &rename_id))
        .on_secondary_press(move |s: &mut State, at: PointerPress, _tx: &mut Tx| {
            s.library_ui.overlay = Overlay::Context { id: ctx_id.clone(), x: at.x, y: at.y };
        })
        .on_hover_change(move |s: &mut State, inside: bool, _tx: &mut Tx| {
            let ui = &mut s.library_ui;
            if inside {
                ui.hovered = Some(hover_id.clone());
            } else if ui.hovered.as_deref() == Some(hover_id.as_str()) {
                ui.hovered = None;
            }
        })
}

pub fn new_document_card(size: (f32, f32)) -> El {
    let hint = format!("Start blank · {}", format_shortcut("⌘N", is_mac_style()));
    let disc = el()
        .size(52.0, 52.0)
        .radius(26.0)
        .fill(theme::surface0().alpha(0.7))
        .center()
        .child(text("+").font(TextStyle::new(28.0, 400.0)).color(theme::text()));
    col()
        .key("new-card")
        .role("button")
        .label("New canvas")
        .size(size.0, size.1)
        .radius(16.0)
        .fill(theme::base())
        .border(1.0, theme::surface1())
        .hover(theme::surface0()).motion(rune::tok::motion::SNAPPY)
        .focusable(true)
        .center()
        .gap(0.0)
        .child(disc)
        .child(el().h(14.0))
        .child(text("New canvas").font(TextStyle::new(14.5, 700.0)).color(theme::text().alpha(0.85)))
        .child(el().h(4.0))
        .child(text(hint).font(TextStyle::new(11.5, 400.0)).color(theme::subtext().alpha(0.7)))
        .on_press(|s: &mut State| actions::create_and_open(s, None))
}

/// "No canvases found" / "No canvases yet".
pub fn empty_results(is_searching: bool) -> El {
    let (title, hint) = if is_searching {
        ("No canvases found", "Try a different search term.")
    } else {
        ("No canvases yet", "Create your first canvas to get started.")
    };
    let glyph = el()
        .size(52.0, 52.0)
        .radius(14.0)
        .fill(theme::surface0())
        .border(1.0, theme::surface1())
        .center()
        .child(text(if is_searching { "⌀" } else { "▦" }).font(TextStyle::new(22.0, 400.0)).color(theme::subtext()));
    let action = if is_searching {
        StyledButton::new("empty-clear", "Clear search", ButtonVariant::Ghost).build(actions::clear_search)
    } else {
        StyledButton::new("empty-create", "New canvas", ButtonVariant::Primary)
            .glyph("+")
            .build(|s: &mut State| actions::create_and_open(s, None))
    };
    col()
        .key("empty-results")
        .w_full()
        .items_center()
        .px(24.0)
        .py(64.0)
        .radius(18.0)
        .fill(theme::base())
        .border(1.0, theme::surface0())
        .child(glyph)
        .child(el().h(16.0))
        .child(text(title).font(TextStyle::new(16.0, 700.0)).color(theme::text()))
        .child(el().h(6.0))
        .child(text(hint).font(TextStyle::new(13.5, 400.0)).color(theme::subtext()))
        .child(el().h(18.0))
        .child(action)
}
