//! Outline pattern.
use crate::style_values::style_enum;

style_enum! {
    pub enum StrokeType { Solid => "solid", Dashed => "dashed", Dotted => "dotted" }
}
