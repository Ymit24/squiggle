//! Modal dialog (port of `squiggle_dialog.dart`): scrim plus a centred panel with a title row
//! (optional tinted glyph), content and a right-aligned action row. Whether it is open is the
//! app's; Rune's modal stack traps focus, makes the page inert and handles Escape and outside
//! presses by calling `on_dismiss`.

use crate::theme;
use rune::tok::TextStyle;
use rune::{Color, El, col, el, row, text};

pub const CONTENT_WIDTH: f32 = 360.0;

pub struct Dialog {
    key: String,
    title: String,
    glyph: Option<&'static str>,
    tint: Color,
    content: Vec<El>,
    actions: Vec<El>,
}

impl Dialog {
    pub fn new(key: impl Into<String>, title: impl Into<String>) -> Self {
        Dialog { key: key.into(), title: title.into(), glyph: None, tint: theme::accent(), content: Vec::new(), actions: Vec::new() }
    }
    /// A tinted rounded square with a text glyph before the title.
    pub fn glyph(mut self, glyph: &'static str, tint: Color) -> Self {
        self.glyph = Some(glyph);
        self.tint = tint;
        self
    }
    pub fn content(mut self, content: El) -> Self {
        self.content.push(content);
        self
    }
    pub fn action(mut self, action: El) -> Self {
        self.actions.push(action);
        self
    }

    /// The scrim and panel to push at the page root. Elements are keyed `{key}-scrim`,
    /// `{key}-dialog` (role `dialog`) and `{key}-actions`.
    pub fn build<S: 'static>(self, on_dismiss: impl Fn(&mut S) + 'static) -> Vec<El> {
        let mut title = row().items_center().gap(12.0).px(22.0).pt(20.0);
        if let Some(g) = self.glyph {
            title = title.child(
                el().size(36.0, 36.0).radius(10.0).fill(self.tint.alpha(0.12)).center().child(text(g).font(TextStyle::new(17.0, 700.0)).color(self.tint)),
            );
        }
        title = title.child(text(self.title.clone()).font(TextStyle::new(16.0, 700.0)).color(theme::text()).grow(1.0));
        let body = self.content.into_iter().fold(col().w(CONTENT_WIDTH + 44.0).px(22.0).pt(12.0), |c, e| c.child(e));
        let actions = self
            .actions
            .into_iter()
            .fold(row().key(format!("{}-actions", self.key)).gap(8.0).justify_end().padding(16.0).pt(16.0).pb(14.0), |r, a| r.child(a));
        let panel = col()
            .key(format!("{}-dialog", self.key))
            .role("dialog")
            .label(self.title)
            .fill(theme::base())
            .radius(16.0)
            .border(1.0, theme::surface1())
            .shadow(14.0, 40.0, Color::BLACK.alpha(0.5))
            .child(title)
            .child(body)
            .child(actions)
            .modal(true, on_dismiss);
        vec![
            el().key(format!("{}-scrim", self.key)).absolute(0.0, 0.0).w_full().h_full().fill(Color::BLACK.alpha(0.54)).a11y_hidden(),
            el().key(format!("{}-layer", self.key)).absolute(0.0, 0.0).w_full().h_full().padding(16.0).center().child(panel),
        ]
    }
}

/// Muted paragraph text for dialog bodies (`delete_document_dialog.dart` message style).
pub fn message(s: &str) -> El {
    text(s).font(TextStyle::new(13.5, 400.0).lh(19.5)).color(theme::subtext()).wrap().w_full()
}

