//! Search filter and sort order (`_filtered`/`_sorted` in `document_library_page.dart`).

use squiggle_core::repositories::DocumentInfo;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum DocumentSortMode {
    #[default]
    Recent,
    Oldest,
    Name,
}

impl DocumentSortMode {
    /// Short label of the sort button.
    pub fn button_label(self) -> &'static str {
        match self {
            DocumentSortMode::Recent => "Recent",
            DocumentSortMode::Oldest => "Oldest",
            DocumentSortMode::Name => "Name",
        }
    }
}

/// Documents whose name contains `query` (case-insensitive, trimmed), in `mode` order.
pub fn filter_and_sort(documents: &[DocumentInfo], query: &str, mode: DocumentSortMode) -> Vec<DocumentInfo> {
    let query = query.trim().to_lowercase();
    let mut out: Vec<DocumentInfo> =
        documents.iter().filter(|d| query.is_empty() || d.name.to_lowercase().contains(&query)).cloned().collect();
    match mode {
        DocumentSortMode::Recent => out.sort_by(|a, b| b.updated_at.cmp(&a.updated_at)),
        DocumentSortMode::Oldest => out.sort_by(|a, b| a.updated_at.cmp(&b.updated_at)),
        DocumentSortMode::Name => out.sort_by_key(|d| d.name.to_lowercase()),
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{Duration, SystemTime};

    fn doc(id: &str, name: &str, age_secs: u64) -> DocumentInfo {
        DocumentInfo { id: id.into(), name: name.into(), updated_at: SystemTime::UNIX_EPOCH + Duration::from_secs(1_000_000 - age_secs) }
    }

    fn ids(v: &[DocumentInfo]) -> Vec<&str> {
        v.iter().map(|d| d.id.as_str()).collect()
    }

    fn sample() -> Vec<DocumentInfo> {
        vec![doc("a", "banana", 30), doc("b", "Apple", 10), doc("c", "cherry pie", 20)]
    }

    #[test]
    fn recent_puts_the_newest_first() {
        assert_eq!(ids(&filter_and_sort(&sample(), "", DocumentSortMode::Recent)), ["b", "c", "a"]);
    }

    #[test]
    fn oldest_puts_the_oldest_first() {
        assert_eq!(ids(&filter_and_sort(&sample(), "", DocumentSortMode::Oldest)), ["a", "c", "b"]);
    }

    #[test]
    fn name_sorts_case_insensitively() {
        assert_eq!(ids(&filter_and_sort(&sample(), "", DocumentSortMode::Name)), ["b", "a", "c"]);
    }

    #[test]
    fn query_matches_substrings_ignoring_case_and_outer_spaces() {
        assert_eq!(ids(&filter_and_sort(&sample(), "  ERR ", DocumentSortMode::Recent)), ["c"]);
        assert!(filter_and_sort(&sample(), "zzz", DocumentSortMode::Recent).is_empty());
    }
}
