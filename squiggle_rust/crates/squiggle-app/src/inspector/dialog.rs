//! Modal dialog frame and buttons (port of `squiggle_dialog.dart` and `squiggle_button.dart`).

use crate::kit::BODY;
use crate::state::State;
use crate::theme;
use rune::tok::TextStyle;
use rune::{Color, El, col, el, row, text};

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum ButtonVariant {
    Primary,
    Ghost,
    Danger,
}

/// A dialog button; `enabled == false` draws it dimmed and ignores presses.
pub fn dialog_button(key: &str, label: &str, variant: ButtonVariant, enabled: bool, on_press: impl Fn(&mut State) + 'static) -> El {
    let (fill, ink) = match variant {
        ButtonVariant::Primary => (theme::accent(), theme::base()),
        ButtonVariant::Ghost => (Color::TRANSPARENT, theme::text()),
        ButtonVariant::Danger => (theme::danger(), theme::base()),
    };
    let button = row()
        .key(key.to_owned())
        .h(34.0)
        .padding(14.0)
        .items_center()
        .justify_center()
        .radius(crate::kit::metrics::BUTTON_RADIUS)
        .fill(fill)
        .opacity(if enabled { 1.0 } else { 0.4 })
        .child(text(label).font(BODY).color(ink));
    if enabled { button.hover(Color::WHITE.alpha(0.1)).motion(rune::tok::motion::SNAPPY).focusable(true).on_press(on_press) } else { button }
}

/// A full-window scrim with a centred panel. Escape or a click outside calls `dismiss`.
pub fn dialog(key: &str, title: &str, content: El, actions: Vec<El>, dismiss: impl Fn(&mut State) + 'static) -> El {
    let panel = col()
        .key(format!("{key}-dialog"))
        .role("dialog")
        .label(title.to_owned())
        .w(360.0 + 44.0)
        .padding(22.0)
        .gap(12.0)
        .radius(16.0)
        .fill(theme::base())
        .border(1.0, theme::surface1())
        .child(text(title).font(TextStyle::new(16.0, 700.0)).color(theme::text()))
        .child(content)
        .child(row().justify_end().gap(8.0).children(actions))
        .modal(true, dismiss);
    el().key(format!("{key}-layer"))
        .absolute(0.0, 0.0)
        .w_full()
        .h_full()
        .fill(Color::BLACK.alpha(0.5))
        .items_center()
        .justify_center()
        .child(panel)
}
