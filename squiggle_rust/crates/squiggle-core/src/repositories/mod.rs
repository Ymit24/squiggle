//! On-disk persistence: documents, library bookkeeping and pasted images.
//!
//! Layout under the app directory (identical to the Dart app):
//! `documents/<id>.json`, `active_document.txt`, `images/<imageId>`.

pub mod document_info;
pub mod document_library_repository;
pub mod document_storage;
pub mod image_repository;

use std::collections::hash_map::RandomState;
use std::hash::{BuildHasher, Hasher};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

pub use document_info::DocumentInfo;
pub use document_library_repository::{DocumentHost, DocumentLibraryRepository};
pub use document_storage::{DocumentStorage, StoredDocument};
pub use image_repository::{ImageRepository, ImportedImage, clamp_image_world_size};

/// Default application data directory (`.../squiggle`), computed from environment variables only.
pub fn default_app_dir() -> PathBuf {
    let env = |k: &str| std::env::var_os(k).filter(|v| !v.is_empty()).map(PathBuf::from);
    let home = || env("HOME").or_else(|| env("USERPROFILE")).unwrap_or_else(|| PathBuf::from("."));
    if cfg!(windows) {
        return env("APPDATA").unwrap_or_else(|| home().join("AppData/Roaming")).join("Squiggle");
    }
    if cfg!(target_os = "macos") {
        return home().join("Library/Application Support/Squiggle");
    }
    env("XDG_DATA_HOME").unwrap_or_else(|| home().join(".local/share")).join("squiggle")
}

/// Random 24-bit value (std-only; not cryptographic).
pub(crate) fn random_u24() -> u32 {
    (RandomState::new().build_hasher().finish() & 0xFF_FFFF) as u32
}

pub(crate) fn unix_micros() -> u128 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_micros()).unwrap_or(0)
}

#[cfg(test)]
pub(crate) mod test_util {
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicU32, Ordering};

    /// Self-deleting unique temp directory.
    pub struct TempDir(pub PathBuf);

    impl TempDir {
        pub fn new(tag: &str) -> Self {
            static N: AtomicU32 = AtomicU32::new(0);
            let n = N.fetch_add(1, Ordering::Relaxed);
            let dir = std::env::temp_dir().join(format!("squiggle_{tag}_{}_{n}", std::process::id()));
            std::fs::create_dir_all(&dir).unwrap();
            TempDir(dir)
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.0);
        }
    }

    /// Minimal PNG-looking bytes: signature plus an IHDR chunk.
    pub fn test_png(width: u32, height: u32) -> Vec<u8> {
        let mut b = vec![0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13];
        b.extend_from_slice(b"IHDR");
        b.extend_from_slice(&width.to_be_bytes());
        b.extend_from_slice(&height.to_be_bytes());
        b.extend_from_slice(&[8, 6, 0, 0, 0, 0, 0, 0, 0]);
        b
    }
}
