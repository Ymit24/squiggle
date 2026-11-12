//! How a closed shape's interior is painted.
use crate::style_values::style_enum;

style_enum! {
    pub enum FillType { Solid => "solid", Lines => "lines", Crosshatch => "crosshatch" }
}
