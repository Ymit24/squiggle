use std::time::{Duration, Instant};

/// Classic token bucket: holds up to `capacity` tokens and regains one every
/// `refill_every`.
#[derive(Debug)]
pub struct TokenBucket {
    capacity: f64,
    refill_every: Duration,
    tokens: f64,
    updated: Instant,
}

impl TokenBucket {
    pub fn new(capacity: u32, refill_every: Duration, now: Instant) -> Self {
        Self {
            capacity: f64::from(capacity),
            refill_every,
            tokens: f64::from(capacity),
            updated: now,
        }
    }

    /// Takes a token, or returns how long until one is available.
    pub fn try_take(&mut self, now: Instant) -> Result<(), Duration> {
        let elapsed = now.saturating_duration_since(self.updated);
        self.tokens = (self.tokens + elapsed.as_secs_f64() / self.refill_every.as_secs_f64())
            .min(self.capacity);
        self.updated = now;
        if self.tokens >= 1.0 {
            self.tokens -= 1.0;
            return Ok(());
        }
        Err(self.refill_every.mul_f64(1.0 - self.tokens))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn allows_a_burst_then_refills_over_time() {
        let start = Instant::now();
        let minute = Duration::from_secs(60);
        let mut bucket = TokenBucket::new(2, minute, start);

        assert!(bucket.try_take(start).is_ok());
        assert!(bucket.try_take(start).is_ok());
        assert_eq!(bucket.try_take(start), Err(minute));

        let later = start + Duration::from_secs(45);
        assert_eq!(bucket.try_take(later), Err(Duration::from_secs(15)));
        assert!(bucket.try_take(start + minute).is_ok());
    }

    #[test]
    fn never_banks_more_than_capacity() {
        let start = Instant::now();
        let mut bucket = TokenBucket::new(1, Duration::from_secs(1), start);
        let much_later = start + Duration::from_secs(3600);
        assert!(bucket.try_take(much_later).is_ok());
        assert!(bucket.try_take(much_later).is_err());
    }
}
