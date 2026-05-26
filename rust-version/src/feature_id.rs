#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct FeatureId(u64);

impl FeatureId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }

    pub fn next(&mut self) {
        self.0 += 1;
    }
}

pub const NO_ID: FeatureId = FeatureId(0);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_creates_feature_id() {
        let id = FeatureId::new(42);
        assert_eq!(id, FeatureId(42));
    }

    #[test]
    fn test_next_increments_id() {
        let mut id = FeatureId::new(5);
        id.next();
        assert_eq!(id, FeatureId(6));
        id.next();
        assert_eq!(id, FeatureId(7));
    }

    #[test]
    fn test_partial_eq() {
        let id1 = FeatureId::new(10);
        let id2 = FeatureId::new(10);
        let id3 = FeatureId::new(20);
        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_clone_and_copy() {
        let id1 = FeatureId::new(100);
        let id2 = id1;
        let id3 = id1.clone();
        assert_eq!(id1, id2);
        assert_eq!(id1, id3);
    }

    #[test]
    fn test_hash_consistency() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        let id1 = FeatureId::new(1);
        let id2 = FeatureId::new(1);
        let id3 = FeatureId::new(2);
        set.insert(id1);
        assert!(set.contains(&id2));
        assert!(!set.contains(&id3));
    }

    #[test]
    fn test_debug_trait() {
        let id = FeatureId::new(99);
        assert_eq!(format!("{:?}", id), "FeatureId(99)");
    }
}
