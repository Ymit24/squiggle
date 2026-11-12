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

/// Port of `SquiggleButtonVariant` (`squiggle_button_style.dart`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ButtonVariant {
    /// Light filled button with a bold label.
    Primary,
    /// Dark bordered button.
    Secondary,
    /// Filled danger-coloured button for destructive actions.
    Danger,
    /// Borderless button for quiet actions such as Cancel.
    Ghost,
}

/// Standard Squiggle button (`SquiggleButton`). `glyph` is an optional leading text glyph;
/// `compact` shows only the glyph in a square. A disabled button has no press handler.
pub struct StyledButton {
    pub key: String,
    pub label: String,
    pub glyph: Option<&'static str>,
    pub variant: ButtonVariant,
    pub compact: bool,
    pub enabled: bool,
}

impl StyledButton {
    pub fn new(key: impl Into<String>, label: impl Into<String>, variant: ButtonVariant) -> Self {
        StyledButton { key: key.into(), label: label.into(), glyph: None, variant, compact: false, enabled: true }
    }
    pub fn glyph(mut self, glyph: &'static str) -> Self {
        self.glyph = Some(glyph);
        self
    }
    pub fn compact(mut self, compact: bool) -> Self {
        self.compact = compact && self.glyph.is_some();
        self
    }
    pub fn enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }

    pub fn build<S: 'static>(self, on_press: impl Fn(&mut S) + 'static) -> El {
        let (fill, hover, fg, weight, border) = match self.variant {
            ButtonVariant::Primary => (theme::text(), theme::base().alpha(0.12), theme::base(), 700.0, None),
            ButtonVariant::Secondary => (theme::surface0(), theme::text().alpha(0.06), theme::text(), 600.0, Some(theme::surface1())),
            ButtonVariant::Danger => (theme::on_danger(), theme::base().alpha(0.12), rune::Color::WHITE, 700.0, None),
            ButtonVariant::Ghost => (rune::Color::TRANSPARENT, theme::surface0(), theme::subtext(), 600.0, None),
        };
        let disabled = !self.enabled;
        let (fill, fg) = match (disabled, self.variant) {
            (false, _) => (fill, fg),
            (true, ButtonVariant::Ghost) => (rune::Color::TRANSPARENT, theme::subtext().alpha(0.5)),
            (true, _) => (theme::surface0(), theme::subtext().alpha(0.5)),
        };
        let font = TextStyle::new(13.5, weight);
        let mut b = row()
            .key(self.key)
            .role("button")
            .label(self.label.clone())
            .h(metrics::BUTTON_HEIGHT)
            .items_center()
            .justify_center()
            .gap(7.0)
            .radius(metrics::BUTTON_RADIUS)
            .fill(fill)
            .disabled(disabled)
            .focusable(!disabled);
        b = if self.compact { b.w(metrics::BUTTON_HEIGHT) } else { b.px(metrics::BUTTON_PAD) };
        if let Some(c) = border {
            b = b.border(1.0, c);
        }
        if let Some(g) = self.glyph {
            b = b.child(text(g).font(TextStyle::new(16.0, 600.0)).color(fg));
        }
        if !self.compact {
            b = b.child(text(self.label).font(font).color(fg));
        }
        if disabled { b } else { b.hover(hover).on_press(on_press) }
    }
}

/// Small translucent label chip (`SquigglePill`), e.g. the "Current" badge.
pub fn pill(label: &str) -> El {
    row()
        .px(9.0)
        .py(5.0)
        .radius(999.0)
        .fill(rune::Color::BLACK.alpha(0.55))
        .border(1.0, theme::accent().alpha(0.5))
        .child(text(label).font(TextStyle::new(10.5, 700.0)).color(theme::text()))
}
