use super::{random_u24, unix_micros};
use crate::geom::Size;
use std::fs;
use std::path::{Path, PathBuf};

/// Result of importing image bytes into app storage.
#[derive(Clone, Debug, PartialEq)]
pub struct ImportedImage {
    pub image_id: String,
    pub intrinsic_size: Size,
}

/// Stores pasted images on disk keyed by id (`img_<millis>_<hex>.png`).
///
/// Decoding for rendering is the UI's job; this only validates the PNG header and reports
/// the intrinsic size.
#[derive(Clone, Debug)]
pub struct ImageRepository {
    dir: PathBuf,
}

impl ImageRepository {
    pub fn new(images_dir: impl Into<PathBuf>) -> Self {
        ImageRepository { dir: images_dir.into() }
    }

    /// Repository in `<app_dir>/images`.
    pub fn in_app_dir(app_dir: &Path) -> Self {
        Self::new(app_dir.join("images"))
    }

    pub fn images_dir(&self) -> &Path {
        &self.dir
    }

    pub fn initialize(&self) -> std::io::Result<()> {
        fs::create_dir_all(&self.dir)
    }

    pub fn file_for(&self, image_id: &str) -> PathBuf {
        self.dir.join(image_id)
    }

    pub fn exists(&self, image_id: &str) -> bool {
        self.file_for(image_id).is_file()
    }

    pub fn read_png_bytes(&self, image_id: &str) -> Option<Vec<u8>> {
        fs::read(self.file_for(image_id)).ok()
    }

    /// Intrinsic size of a stored image, read from its header.
    pub fn image_size(&self, image_id: &str) -> Option<Size> {
        png_size(&self.read_png_bytes(image_id)?)
    }

    /// Validates and stores `bytes`; `None` when they are not a PNG or the write fails.
    pub fn import_png_bytes(&self, bytes: &[u8]) -> Option<ImportedImage> {
        let intrinsic_size = png_size(bytes)?;
        self.initialize().ok()?;
        let image_id = generate_image_id();
        fs::write(self.file_for(&image_id), bytes).ok()?;
        Some(ImportedImage { image_id, intrinsic_size })
    }
}

/// Width and height from a PNG signature + IHDR chunk, or `None` for anything else.
pub fn png_size(bytes: &[u8]) -> Option<Size> {
    const SIGNATURE: [u8; 8] = [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A];
    if bytes.len() < 24 || bytes[..8] != SIGNATURE || &bytes[12..16] != b"IHDR" {
        return None;
    }
    let be = |i: usize| u32::from_be_bytes([bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]]);
    let (w, h) = (be(16), be(20));
    (w > 0 && h > 0).then(|| Size::new(w as f64, h as f64))
}

fn generate_image_id() -> String {
    format!("img_{}_{:06x}.png", unix_micros() / 1000, random_u24())
}

/// Scales very large pasted images down to a reasonable canvas size (Dart default max: 1024).
pub fn clamp_image_world_size(intrinsic: Size, max_dimension: f64) -> Size {
    let (w, h) = (intrinsic.width, intrinsic.height);
    if w <= 0.0 || h <= 0.0 {
        return Size::new(256.0, 256.0);
    }
    if w <= max_dimension && h <= max_dimension {
        return intrinsic;
    }
    let scale = max_dimension / w.max(h);
    Size::new(w * scale, h * scale)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repositories::test_util::{TempDir, test_png};

    #[test]
    fn clamp_returns_intrinsic_size_within_max() {
        assert_eq!(clamp_image_world_size(Size::new(400.0, 200.0), 1024.0), Size::new(400.0, 200.0));
    }

    #[test]
    fn clamp_scales_down_preserving_aspect_ratio() {
        assert_eq!(clamp_image_world_size(Size::new(2048.0, 1024.0), 1024.0), Size::new(1024.0, 512.0));
    }

    #[test]
    fn clamp_defaults_degenerate_sizes() {
        assert_eq!(clamp_image_world_size(Size::new(0.0, 5.0), 1024.0), Size::new(256.0, 256.0));
    }

    #[test]
    fn import_writes_file_and_returns_intrinsic_size() {
        let tmp = TempDir::new("image");
        let repo = ImageRepository::new(&tmp.0);
        repo.initialize().unwrap();
        let bytes = test_png(100, 50);
        let imported = repo.import_png_bytes(&bytes).unwrap();
        assert_eq!(imported.intrinsic_size, Size::new(100.0, 50.0));
        assert!(repo.file_for(&imported.image_id).is_file());
        assert_eq!(repo.read_png_bytes(&imported.image_id).unwrap(), bytes);
    }

    #[test]
    fn size_loads_from_disk_with_a_fresh_repository() {
        let tmp = TempDir::new("image");
        let repo = ImageRepository::new(&tmp.0);
        let imported = repo.import_png_bytes(&test_png(64, 32)).unwrap();
        let fresh = ImageRepository::new(&tmp.0);
        assert_eq!(fresh.image_size(&imported.image_id), Some(Size::new(64.0, 32.0)));
        assert_eq!(fresh.image_size("missing.png"), None);
    }

    #[test]
    fn rejects_non_png_bytes() {
        let tmp = TempDir::new("image");
        let repo = ImageRepository::new(tmp.0.join("nested"));
        assert!(repo.import_png_bytes(&[1, 2, 3]).is_none());
        assert!(!tmp.0.join("nested").exists());
    }
}
