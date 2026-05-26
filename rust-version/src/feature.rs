use gpui::{
    App, Bounds, FontWeight, Pixels, Point, Size, TextAlign, TextRun, Window, fill, point, size,
};

use crate::{
    colors,
    feature_id::{FeatureId, NO_ID},
};

#[derive(Clone)]
pub struct Feature {
    pub id: FeatureId,
    pub origin: Point<Pixels>,
    pub size: Size<Pixels>,
    pub kind: FeatureKind,
}

#[derive(Clone)]
pub enum FeatureKind {
    Rectangle,
    Circle,
    Text { contents: String },
}

impl Feature {
    pub fn new_rectangle(origin: Point<Pixels>, size: Size<Pixels>) -> Self {
        Self {
            id: NO_ID,
            origin,
            size,
            kind: FeatureKind::Rectangle,
        }
    }

    pub fn new_circle(origin: Point<Pixels>, size: Size<Pixels>) -> Self {
        Self {
            id: NO_ID,
            origin,
            size,
            kind: FeatureKind::Circle,
        }
    }

    pub fn new_text(origin: Point<Pixels>, size: Size<Pixels>, contents: String) -> Self {
        Self {
            id: NO_ID,
            origin,
            size,
            kind: FeatureKind::Text { contents },
        }
    }

    pub fn width(&self) -> Pixels {
        self.size.width
    }

    pub fn height(&self) -> Pixels {
        self.size.height
    }

    pub fn size(&self) -> Size<Pixels> {
        self.size
    }

    pub fn bounds(&self) -> Bounds<Pixels> {
        Bounds::new(self.origin, self.size())
    }

    pub fn set_bounds(&mut self, bounds: Bounds<Pixels>) {
        self.origin = bounds.origin;
        self.size = bounds.size;
    }

    pub fn center(&self) -> Point<Pixels> {
        self.bounds().center()
    }

    pub fn move_to(&mut self, origin: Point<Pixels>) {
        self.origin = origin;
    }

    pub fn render(&self, screen_bounds: Bounds<Pixels>, window: &mut Window, cx: &mut App) {
        match &self.kind {
            FeatureKind::Rectangle => {
                window.paint_quad(fill(screen_bounds, colors::mauve()));
            }
            FeatureKind::Circle => {
                draw_ellipse(screen_bounds.origin, screen_bounds.size, window);
            }
            FeatureKind::Text { contents } => {
                let font_size = screen_bounds.size.height;
                let text_run = TextRun {
                    len: contents.len(),
                    font: window.text_style().highlight(FontWeight::NORMAL).font(),
                    color: colors::text(),
                    background_color: None,
                    underline: None,
                    strikethrough: None,
                };

                if let Ok(lines) = window.text_system().shape_text(
                    contents.clone().into(),
                    font_size,
                    &[text_run],
                    Some(screen_bounds.size.width),
                    None,
                ) {
                    for line in lines {
                        let _ = line.paint(
                            screen_bounds.origin,
                            font_size,
                            TextAlign::Left,
                            Some(screen_bounds),
                            window,
                            cx,
                        );
                    }
                }
            }
        }
    }
}

fn draw_ellipse(origin: Point<Pixels>, size: Size<Pixels>, window: &mut Window) {
    let rx = size.width / 2.;
    let ry = size.height / 2.;
    let center = point(origin.x + rx, origin.y + ry);
    let radii = point(rx, ry);

    let mut builder = gpui::PathBuilder::fill();
    builder.move_to(point(center.x + rx, center.y));
    builder.arc_to(
        radii,
        gpui::px(0.),
        false,
        true,
        point(center.x - rx, center.y),
    );
    builder.arc_to(
        radii,
        gpui::px(0.),
        false,
        true,
        point(center.x + rx, center.y),
    );
    builder.close();

    if let Ok(path) = builder.build() {
        window.paint_path(path, colors::red());
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::px;

    #[test]
    fn test_new_rectangle_creates_rectangle_feature() {
        let feature = Feature::new_rectangle(point(px(10.0), px(20.0)), size(px(100.0), px(50.0)));
        assert_eq!(feature.id, NO_ID);
        assert_eq!(feature.origin, point(px(10.0), px(20.0)));
        assert_eq!(feature.size.width, px(100.0));
        assert_eq!(feature.size.height, px(50.0));
        assert!(matches!(feature.kind, FeatureKind::Rectangle));
    }

    #[test]
    fn test_new_circle_creates_circle_feature() {
        let feature = Feature::new_circle(point(px(50.0), px(50.0)), size(px(50.0), px(25.0)));
        assert_eq!(feature.id, NO_ID);
        assert_eq!(feature.origin, point(px(50.0), px(50.0)));
        assert_eq!(feature.size.width, px(50.0));
        assert_eq!(feature.size.height, px(25.0));
        assert!(matches!(feature.kind, FeatureKind::Circle));
    }

    #[test]
    fn test_width_rectangle_returns_width() {
        let feature = Feature::new_rectangle(point(px(0.0), px(0.0)), size(px(100.0), px(50.0)));
        assert_eq!(feature.width(), px(100.0));
    }

    #[test]
    fn test_width_circle_returns_width() {
        let feature = Feature::new_circle(point(px(0.0), px(0.0)), size(px(25.0), px(50.0)));
        assert_eq!(feature.width(), px(25.0));
    }

    #[test]
    fn test_height_rectangle_returns_height() {
        let feature = Feature::new_rectangle(point(px(0.0), px(0.0)), size(px(100.0), px(50.0)));
        assert_eq!(feature.height(), px(50.0));
    }

    #[test]
    fn test_height_circle_returns_height() {
        let feature = Feature::new_circle(point(px(0.0), px(0.0)), size(px(25.0), px(50.0)));
        assert_eq!(feature.height(), px(50.0));
    }

    #[test]
    fn test_size_returns_correct_dimensions() {
        let rectangle = Feature::new_rectangle(point(px(0.0), px(0.0)), size(px(100.0), px(50.0)));
        let dimensions = rectangle.size();
        assert_eq!(dimensions.width, px(100.0));
        assert_eq!(dimensions.height, px(50.0));

        let circle = Feature::new_circle(point(px(0.0), px(0.0)), size(px(25.0), px(25.0)));
        let dimensions = circle.size();
        assert_eq!(dimensions.width, px(25.0));
        assert_eq!(dimensions.height, px(25.0));
    }

    #[test]
    fn test_bounds_returns_correct_bounds() {
        let feature = Feature::new_rectangle(point(px(10.0), px(20.0)), size(px(100.0), px(50.0)));
        let bounds = feature.bounds();
        assert_eq!(bounds.origin, point(px(10.0), px(20.0)));
        assert_eq!(bounds.size.width, px(100.0));
        assert_eq!(bounds.size.height, px(50.0));
    }

    #[test]
    fn test_center_calculates_midpoint_correctly() {
        let rectangle = Feature::new_rectangle(point(px(0.0), px(0.0)), size(px(100.0), px(50.0)));
        let center = rectangle.center();
        assert_eq!(center.x, px(50.0));
        assert_eq!(center.y, px(25.0));

        let circle = Feature::new_circle(point(px(10.0), px(20.0)), size(px(25.0), px(25.0)));
        let center = circle.center();
        assert_eq!(center.x, px(22.5));
        assert_eq!(center.y, px(32.5));
    }

    #[test]
    fn test_move_to_updates_origin() {
        let mut feature =
            Feature::new_rectangle(point(px(0.0), px(0.0)), size(px(100.0), px(50.0)));
        feature.move_to(point(px(200.0), px(300.0)));
        assert_eq!(feature.origin, point(px(200.0), px(300.0)));
        assert_eq!(feature.size.width, px(100.0));
        assert_eq!(feature.size.height, px(50.0));
        assert!(matches!(feature.kind, FeatureKind::Rectangle));
    }

    #[test]
    fn test_feature_is_clone() {
        let feature = Feature::new_circle(point(px(10.0), px(20.0)), size(px(15.0), px(15.0)));
        let cloned = feature.clone();
        assert_eq!(cloned.origin, feature.origin);
    }
}
