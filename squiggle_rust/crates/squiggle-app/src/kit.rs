//! Shared UI metrics and small widgets (port of `lib/theme/*` tokens and `lib/widgets/*`).
//! Widgets are generic over the app state so any page can use them.

use crate::theme;
use rune::tok::TextStyle;
use rune::{El, col, el, row, text};

pub mod metrics {
    pub const OVERLAY_TOP: f32 = 20.0;
    pub const OVERLAY_SIDE: f32 = 20.0;
    pub const TOOLBAR_PADDING: f32 = 4.0;
    pub const TOOLBAR_GAP: f32 = 2.0;
    pub const TOOLBAR_BUTTON: f32 = 36.0;
    pub const TOOLBAR_ICON: f32 = 20.0;
    pub const PANEL_PADDING: f32 = 12.0;
    pub const PANEL_SECTION_SPACING: f32 = 12.0;
    pub const PANEL_LABEL_SPACING: f32 = 8.0;
    pub const SWATCH: f32 = 26.0;
    pub const SWATCH_GAP: f32 = 6.0;
    pub const BUTTON_HEIGHT: f32 = 38.0;
    pub const BUTTON_PAD: f32 = 14.0;
    pub const MENU_WIDTH: f32 = 188.0;
    pub const MENU_PADDING: f32 = 6.0;
    pub const MENU_ITEM_HEIGHT: f32 = 28.0;
    pub const FLOATING_PANEL_RADIUS: f32 = 12.0;
    pub const BUTTON_RADIUS: f32 = 6.0;
    pub const INPUT_RADIUS: f32 = 6.0;
    pub const SWATCH_RADIUS: f32 = 5.0;
}

pub const BODY: TextStyle = TextStyle::new(13.0, 400.0);
pub const LABEL: TextStyle = TextStyle::new(12.0, 500.0);
pub const SECTION: TextStyle = TextStyle::new(11.0, 600.0);

/// Floating chrome panel (toolbar, inspector, menus).
pub fn floating_panel() -> El {
    col().fill(theme::mantle()).radius(metrics::FLOATING_PANEL_RADIUS).border(1.0, theme::surface1())
}

pub fn section_label(s: &str) -> El {
    text(s.to_uppercase()).font(SECTION).color(theme::subtext())
}

pub fn divider_vertical() -> El {
    el().w(1.0).h(20.0).fill(theme::surface1())
}

pub fn divider_horizontal() -> El {
    el().h(1.0).w_full().fill(theme::surface1())
}

/// Text button used in dialogs and the library header.
pub fn button<S: 'static>(label: &str, on_press: impl Fn(&mut S) + 'static) -> El {
    row()
        .h(metrics::BUTTON_HEIGHT)
        .padding(metrics::BUTTON_PAD)
        .items_center()
        .justify_center()
        .radius(metrics::BUTTON_RADIUS)
        .fill(theme::surface0())
        .hover(theme::surface1())
        .focusable(true)
        .on_press(on_press)
        .child(text(label).font(BODY).color(theme::text()))
}

/// Square toolbar button; `active` fills it with the accent tint.
pub fn toolbar_button<S: 'static>(key: &str, active: bool, enabled: bool, content: El, on_press: impl Fn(&mut S) + 'static) -> El {
    let b = row()
        .key(key.to_owned())
        .size(metrics::TOOLBAR_BUTTON, metrics::TOOLBAR_BUTTON)
        .items_center()
        .justify_center()
        .radius(metrics::BUTTON_RADIUS)
        .fill(if active { theme::surface1() } else { rune::Color::TRANSPARENT })
        .opacity(if enabled { 1.0 } else { 0.35 })
        .child(content);
    if enabled { b.hover(theme::surface0()).on_press(on_press) } else { b }
}

/// A menu row with an optional shortcut hint on the right.
pub fn menu_item<S: 'static>(key: &str, label: &str, shortcut: Option<&str>, enabled: bool, on_press: impl Fn(&mut S) + 'static) -> El {
    let item = row()
        .key(key.to_owned())
        .w_full()
        .h(metrics::MENU_ITEM_HEIGHT)
        .padding(7.0)
        .items_center()
        .justify_between()
        .radius(4.0)
        .opacity(if enabled { 1.0 } else { 0.4 })
        .child(text(label).font(BODY).color(theme::text()))
        .child(text(shortcut.unwrap_or("")).font(LABEL).color(theme::subtext()));
    if enabled { item.hover(theme::surface1()).on_press(on_press) } else { item }
}

pub fn menu_panel() -> El {
    floating_panel().w(metrics::MENU_WIDTH).padding(metrics::MENU_PADDING)
}
