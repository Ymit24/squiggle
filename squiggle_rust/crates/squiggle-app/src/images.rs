//! Decoded-image cache for image features: loads PNG bytes from the image repository on first use
//! and keeps Rune `Image` handles keyed by image id.

use rune::{Image, ImageCache};
use squiggle_core::repositories::ImageRepository;
use std::cell::RefCell;
use std::collections::HashMap;
use std::sync::Arc;

pub struct ImageStore {
    cache: ImageCache,
    loaded: RefCell<HashMap<String, Option<Image>>>,
}

impl ImageStore {
    /// `wake` is called from the decoder thread when an image finishes (it repaints the app).
    pub fn new(wake: rune::runtime::Waker) -> Self {
        ImageStore { cache: ImageCache::new(wake), loaded: RefCell::default() }
    }

    pub fn headless() -> Self {
        Self::new(Arc::new(|| {}))
    }

    /// The image for `id`, loading it from `repo` on first request; `None` if missing or corrupt.
    pub fn get(&self, repo: &ImageRepository, id: &str) -> Option<Image> {
        self.loaded
            .borrow_mut()
            .entry(id.to_owned())
            .or_insert_with(|| repo.read_png_bytes(id).map(|bytes| self.cache.load(bytes)))
            .clone()
    }
}
