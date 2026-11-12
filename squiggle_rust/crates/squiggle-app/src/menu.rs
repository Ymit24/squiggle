//! In-app menus (port of `squiggle_menu_item/panel/context_menu.dart` and
//! `shortcut_hint`): a floating panel of rows opened either at a window point (context menu,
//! clamped inside the window) or under an anchor element (dropdown). Whether it is open is the
//! app's; Rune's modal stack gives it focus, Escape and outside-press dismissal, and arrow-key
//! roving through the `menu` focus group.

use crate::kit::{BODY, LABEL, floating_panel, metrics};
use crate::theme;
use rune::{Align, El, Side, row, text};
use std::rc::Rc;

/// Distance kept between a menu and the window edge (`spacing.panelPadding`).
pub const WINDOW_MARGIN: f32 = metrics::PANEL_PADDING;
const GLYPH_SLOT: f32 = 18.0;

/// Command-style shortcut notation adapted to the platform (`SquiggleShortcutHint`).
pub fn format_shortcut(label: &str, mac_style: bool) -> String {
    if mac_style {
        return label.to_owned();
    }
    label.replace('⌘', "Ctrl+").replace('⌃', "Ctrl+").replace('⌥', "Alt+").replace('⇧', "Shift+")
}

pub fn is_mac_style() -> bool {
    cfg!(target_os = "macos")
}

/// A subdued shortcut label. Disabled items keep their dimmed colour.
pub fn shortcut_hint(label: &str, enabled: bool) -> El {
    let color = if enabled { theme::subtext() } else { theme::subtext().alpha(0.5) };
    text(format_shortcut(label, is_mac_style())).font(LABEL).color(color)
}

/// One row of a menu. `on_press` runs after the menu has been asked to close.
pub struct MenuItem<S> {
    pub key: String,
    pub label: String,
    /// Leading text glyph (no icon font is bundled; short symbols stand in for Material icons).
    pub glyph: Option<&'static str>,
    pub shortcut: Option<String>,
    pub danger: bool,
    pub checked: bool,
    pub enabled: bool,
    pub on_press: Rc<dyn Fn(&mut S)>,
}

impl<S: 'static> MenuItem<S> {
    pub fn new(key: impl Into<String>, label: impl Into<String>, on_press: impl Fn(&mut S) + 'static) -> Self {
        MenuItem {
            key: key.into(),
            label: label.into(),
            glyph: None,
            shortcut: None,
            danger: false,
            checked: false,
            enabled: true,
            on_press: Rc::new(on_press),
        }
    }
    pub fn glyph(mut self, glyph: &'static str) -> Self {
        self.glyph = Some(glyph);
        self
    }
    pub fn shortcut(mut self, shortcut: impl Into<String>) -> Self {
        self.shortcut = Some(shortcut.into());
        self
    }
    pub fn danger(mut self, danger: bool) -> Self {
        self.danger = danger;
        self
    }
    pub fn checked(mut self, checked: bool) -> Self {
        self.checked = checked;
        self
    }
    pub fn enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }

    fn build(self, show_glyphs: bool, close: Rc<dyn Fn(&mut S)>) -> El {
        let ink = if self.danger { theme::danger() } else { theme::text() };
        let ink = if self.enabled { ink } else { theme::subtext().alpha(0.5) };
        let mut r = row()
            .key(self.key)
            .role("menuitem")
            .label(self.label.clone())
            .w_full()
            .h(metrics::MENU_ITEM_HEIGHT)
            .px(7.0)
            .gap(12.0)
            .items_center()
            .radius(metrics::BUTTON_RADIUS)
            .disabled(!self.enabled);
        if show_glyphs {
            let g = self.glyph.unwrap_or("");
            r = r.child(text(g).font(BODY).color(ink).w(GLYPH_SLOT).align(Align::Center));
        }
        r = r.child(text(self.label).font(crate::kit::BODY).color(ink).grow(1.0).truncate());
        if let Some(sc) = &self.shortcut {
            r = r.child(shortcut_hint(sc, self.enabled));
        }
        if self.checked {
            r = r.child(text("✓").font(BODY).color(theme::accent()).w(14.0).align(Align::Center));
        }
        if !self.enabled {
            return r;
        }
        let action = self.on_press;
        r.focusable(true).focus_highlight(theme::surface0()).on_press(move |s: &mut S| {
            close(s);
            action(s);
        })
    }
}

/// Where a menu opens.
#[derive(Clone, Debug, PartialEq)]
pub enum Placement {
    /// At a window point, clamped so the whole panel stays inside `window`.
    At { x: f32, y: f32, window: (f32, f32) },
    /// Below (flipping above when short on room) the element with this key, left edges aligned.
    Below { anchor: String },
}

/// Panel height for `rows` rows.
pub fn panel_height(rows: usize) -> f32 {
    rows as f32 * metrics::MENU_ITEM_HEIGHT + 2.0 * metrics::MENU_PADDING + 2.0
}

/// Top-left for a context menu requested at `(x, y)`: kept `WINDOW_MARGIN` inside the window.
pub fn clamp_menu_position(x: f32, y: f32, panel: (f32, f32), window: (f32, f32)) -> (f32, f32) {
    let clamp = |v: f32, extent: f32, limit: f32| v.clamp(WINDOW_MARGIN, (limit - extent - WINDOW_MARGIN).max(WINDOW_MARGIN));
    (clamp(x, panel.0, window.0), clamp(y, panel.1, window.1))
}

/// An open menu's layer elements to push at the page root, after the anchor. `close` is the
/// app's "dismiss" (Escape, outside press, and after a row is chosen).
pub fn menu_layer<S: 'static>(
    key: &str,
    items: Vec<MenuItem<S>>,
    placement: Placement,
    close: impl Fn(&mut S) + 'static,
) -> El {
    let close: Rc<dyn Fn(&mut S)> = Rc::new(close);
    let rows = items.len();
    let show_glyphs = items.iter().any(|i| i.glyph.is_some());
    let dismiss = close.clone();
    let mut panel = floating_panel()
        .key(key.to_owned())
        .role("menu")
        .w(metrics::MENU_WIDTH)
        .padding(metrics::MENU_PADDING)
        .focus_group()
        .modal(true, move |s: &mut S| dismiss(s));
    for item in items {
        panel = panel.child(item.build(show_glyphs, close.clone()));
    }
    match placement {
        Placement::At { x, y, window } => {
            let (x, y) = clamp_menu_position(x, y, (metrics::MENU_WIDTH, panel_height(rows)), window);
            panel.absolute(x, y)
        }
        Placement::Below { anchor } => panel.anchored(anchor, Side::Bottom, Align::Start, 8.0),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn shortcut_notation_adapts_to_the_platform() {
        assert_eq!(format_shortcut("⇧⌘1", true), "⇧⌘1");
        assert_eq!(format_shortcut("⇧⌘1", false), "Shift+Ctrl+1");
        assert_eq!(format_shortcut("⌘⌥[", false), "Ctrl+Alt+[");
        assert_eq!(format_shortcut("⌃Z", false), "Ctrl+Z");
    }

    #[test]
    fn context_menu_position_stays_inside_the_window() {
        let panel = (188.0, panel_height(3));
        let (x, y) = clamp_menu_position(990.0, 890.0, panel, (1000.0, 900.0));
        assert!(x + panel.0 <= 1000.0 && y + panel.1 <= 900.0);
        assert!(x >= WINDOW_MARGIN && y >= WINDOW_MARGIN);
        assert_eq!(clamp_menu_position(-5.0, -5.0, panel, (1000.0, 900.0)), (WINDOW_MARGIN, WINDOW_MARGIN));
        assert_eq!(clamp_menu_position(100.0, 120.0, panel, (1000.0, 900.0)), (100.0, 120.0));
    }

    #[test]
    fn menus_larger_than_the_window_pin_to_the_margin() {
        let (x, y) = clamp_menu_position(50.0, 50.0, (500.0, 500.0), (300.0, 300.0));
        assert_eq!((x, y), (WINDOW_MARGIN, WINDOW_MARGIN));
    }
}
