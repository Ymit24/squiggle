//! Label above a field's control, with an optional trailing widget (port of
//! `inspector_field_shell.dart`).

use crate::kit::{BODY, metrics};
use crate::theme;
use rune::{El, col, row, text};

pub fn field_shell(label: &str, trailing: Option<El>, child: El) -> El {
    let mut header = row().w_full().items_center().child(text(label).font(BODY).color(theme::text()).grow(1.0));
    if let Some(trailing) = trailing {
        header = header.child(trailing);
    }
    col().gap(metrics::PANEL_LABEL_SPACING / 2.0).child(header).child(child)
}
