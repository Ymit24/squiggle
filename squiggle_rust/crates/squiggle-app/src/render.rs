//! Rasterises core display lists into Rune elements: strokes/fills become one `Shape` in screen
//! space, text runs become absolutely positioned text elements.

use crate::theme::rune_color;
use rune::tok::TextStyle;
use crate::images::ImageStore;
use rune::{Align, El, LineCap, Shape, col, el, text};
use squiggle_core::repositories::ImageRepository;
use squiggle_core::camera::Camera;
use squiggle_core::geom::Point;
use squiggle_core::paint::{Cap, DrawCmd, HAlign, VAlign};

fn pt(camera: &Camera, p: Point) -> [f32; 2] {
    let s = camera.world_to_screen(p);
    [s.x as f32, s.y as f32]
}

/// Strokes and fills of `list`, mapped through `camera` to screen coordinates.
pub fn shape(list: &[DrawCmd], camera: &Camera) -> Shape {
    list.iter().fold(Shape::new(), |shape, cmd| match cmd {
        DrawCmd::Stroke { points, closed, width, color, cap } => {
            let pts: Vec<[f32; 2]> = points.iter().map(|p| pt(camera, *p)).collect();
            let cap = if *cap == Cap::Round { LineCap::Round } else { LineCap::Butt };
            shape.stroke_with(pts, *closed, camera.world_length_to_screen_length(*width) as f32, cap, rune_color(*color))
        }
        DrawCmd::Fill { points, color } => {
            shape.fill(points.iter().map(|p| pt(camera, *p)).collect::<Vec<_>>(), rune_color(*color))
        }
        _ => shape,
    })
}

/// Text runs of `list` as elements positioned in screen space.
pub fn text_elements(list: &[DrawCmd], camera: &Camera) -> Vec<El> {
    list.iter()
        .filter_map(|cmd| match cmd {
            DrawCmd::Text { text: content, rect, font_size, color, h_align, v_align } => {
                let r = camera.world_to_screen_bounds(*rect);
                let size = camera.world_length_to_screen_length(*font_size) as f32;
                let label = text(content.clone())
                    .font(TextStyle::new(size, 400.0))
                    .color(rune_color(*color))
                    .align(match h_align {
                        HAlign::Left => Align::Start,
                        HAlign::Center => Align::Center,
                        HAlign::Right => Align::End,
                    })
                    .wrap()
                    .w_full();
                let holder = col().absolute(r.left as f32, r.top as f32).size(r.width() as f32, r.height() as f32);
                Some(match v_align {
                    VAlign::Top => holder.justify_start(),
                    VAlign::Middle => holder.justify_center(),
                    VAlign::Bottom => holder.justify_end(),
                }
                .child(label))
            }
            _ => None,
        })
        .collect()
}

/// Image commands of `list` as elements positioned in screen space.
pub fn image_elements(list: &[DrawCmd], camera: &Camera, store: &ImageStore, repo: &ImageRepository) -> Vec<El> {
    image_elements_with(list, camera, |id| store.get(repo, id))
}

/// [`image_elements`] with a custom image lookup.
pub fn image_elements_with(list: &[DrawCmd], camera: &Camera, lookup: impl Fn(&str) -> Option<rune::Image>) -> Vec<El> {
    list.iter()
        .filter_map(|cmd| {
            let DrawCmd::Image { image_id, rect } = cmd else { return None };
            let r = camera.world_to_screen_bounds(*rect);
            let holder = el().absolute(r.left as f32, r.top as f32).size(r.width() as f32, r.height() as f32);
            Some(match lookup(image_id) {
                Some(image) => holder.pixels(image.pixels()),
                None => holder.fill(crate::theme::surface1()),
            })
        })
        .collect()
}
