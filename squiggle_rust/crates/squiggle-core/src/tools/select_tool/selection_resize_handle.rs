//! The eight resize handles around a selection (`selection_resize_handle.dart`).

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SelectionResizeHandle {
    TopLeft,
    Top,
    TopRight,
    Right,
    BottomRight,
    Bottom,
    BottomLeft,
    Left,
}

impl SelectionResizeHandle {
    pub fn is_corner(self) -> bool {
        use SelectionResizeHandle::*;
        matches!(self, TopLeft | TopRight | BottomLeft | BottomRight)
    }

    pub fn moves_left(self) -> bool {
        use SelectionResizeHandle::*;
        matches!(self, TopLeft | Left | BottomLeft)
    }

    pub fn moves_right(self) -> bool {
        use SelectionResizeHandle::*;
        matches!(self, TopRight | Right | BottomRight)
    }

    pub fn moves_top(self) -> bool {
        use SelectionResizeHandle::*;
        matches!(self, TopLeft | Top | TopRight)
    }

    pub fn moves_bottom(self) -> bool {
        use SelectionResizeHandle::*;
        matches!(self, BottomLeft | Bottom | BottomRight)
    }
}
