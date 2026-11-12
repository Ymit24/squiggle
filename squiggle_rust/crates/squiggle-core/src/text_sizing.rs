//! How a text feature's box is derived from its contents.
use crate::style_values::style_enum;

style_enum! {
    pub enum TextSizing {
        /// Width and height both follow the contents; lines never wrap.
        Auto => "auto",
        /// Width is set by the user and lines wrap at it; height follows the contents.
        FixedWidth => "fixedWidth",
    }
}
