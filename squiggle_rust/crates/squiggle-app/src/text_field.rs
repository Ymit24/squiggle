//! Bordered single-line text field (port of `squiggle_text_field.dart`) over Rune's `text_input`
//! and a `TextEdit` that lives in app state (reached by the `access` function). Set
//! `edit.focused = true` once to request focus (autofocus), and `select_all` to replace the
//! initial text on first keystroke.

use crate::kit::metrics;
use crate::theme;
use rune::tok::TextStyle;
use rune::{El, TextEdit, Tx, row, text_input};

pub struct TextField {
    key: String,
    hint: String,
    compact: bool,
    prefix: Option<El>,
    suffix: Option<El>,
}

/// Selects the whole text (what an autofocused field does so typing replaces it).
pub fn select_all(edit: &mut TextEdit) {
    let n = edit.text.len();
    edit.set_selection(0, n);
}

impl TextField {
    pub fn new(key: impl Into<String>, hint: impl Into<String>) -> Self {
        TextField { key: key.into(), hint: hint.into(), compact: false, prefix: None, suffix: None }
    }
    /// The library header's smaller text and padding.
    pub fn compact(mut self, compact: bool) -> Self {
        self.compact = compact;
        self
    }
    pub fn prefix(mut self, el: El) -> Self {
        self.prefix = Some(el);
        self
    }
    pub fn suffix(mut self, el: El) -> Self {
        self.suffix = Some(el);
        self
    }

    /// The field element: `{key}` is the box, `{key}-input` the editor inside it.
    pub fn build<S: 'static>(
        self,
        edit: &TextEdit,
        access: fn(&mut S) -> &mut TextEdit,
        on_submit: Option<Box<dyn Fn(&mut S, &mut Tx)>>,
    ) -> El {
        let (size, hint_alpha, focus_alpha, focus_width) =
            if self.compact { (13.5, 0.7, 0.6, 1.0) } else { (14.5, 0.6, 0.7, 1.4) };
        let mut input = text_input(edit, TextStyle::new(size, 400.0))
            .single_line()
            .key(format!("{}-input", self.key))
            .grow(1.0)
            .shrink()
            .min_w(0.0)
            .color(theme::text())
            .placeholder(self.hint, theme::subtext().alpha(hint_alpha))
            .caret(theme::text(), theme::accent().alpha(0.3))
            .on_edit(access);
        if let Some(f) = on_submit {
            input = input.on_submit(move |s: &mut S, tx: &mut Tx| f(s, tx));
        }
        let border = if edit.focused { (focus_width, theme::accent().alpha(focus_alpha)) } else { (1.0, theme::surface1()) };
        let mut r = row().key(self.key).items_center().w_full().radius(metrics::INPUT_RADIUS).fill(theme::surface0()).border(border.0, border.1);
        r = if self.compact { r.h(38.0) } else { r.px(13.0).py(11.0) };
        if let Some(p) = self.prefix {
            r = r.child(p);
        }
        r = r.child(input);
        if let Some(s) = self.suffix {
            r = r.child(s);
        }
        r
    }
}
