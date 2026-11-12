//! "Edited 3h ago" labels (port of `library_time.dart`). Calendar dates are UTC: the standard
//! library has no local time zone.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

const MONTHS: [&str; 12] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/// `(year, month 1-12, day 1-31)` of a day count since 1970-01-01 (proleptic Gregorian).
fn civil_from_days(days: i64) -> (i64, usize, i64) {
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    (year, month as usize, day)
}

fn civil(t: SystemTime) -> (i64, usize, i64) {
    let days = match t.duration_since(UNIX_EPOCH) {
        Ok(d) => (d.as_secs() / 86_400) as i64,
        Err(e) => -(e.duration().as_secs().div_ceil(86_400) as i64),
    };
    civil_from_days(days)
}

/// The card's edit label relative to `now`.
pub fn format_edited_at(updated_at: SystemTime, now: SystemTime) -> String {
    let diff = now.duration_since(updated_at).unwrap_or(Duration::ZERO);
    let (minutes, hours, days) = (diff.as_secs() / 60, diff.as_secs() / 3600, diff.as_secs() / 86_400);
    if minutes < 1 {
        return "Edited just now".into();
    }
    if hours < 1 {
        return format!("Edited {minutes}m ago");
    }
    if days < 1 {
        return format!("Edited {hours}h ago");
    }
    if days < 7 {
        return format!("Edited {days}d ago");
    }
    let (year, month, day) = civil(updated_at);
    let month = MONTHS[month.clamp(1, 12) - 1];
    if civil(now).0 == year { format!("Edited {month} {day}") } else { format!("Edited {month} {day}, {year}") }
}

#[cfg(test)]
mod tests {
    use super::*;

    // 2024-06-15 12:00:00 UTC.
    const NOW: u64 = 1_718_452_800;

    fn at(secs: u64) -> SystemTime {
        UNIX_EPOCH + Duration::from_secs(secs)
    }

    fn label(ago: u64) -> String {
        format_edited_at(at(NOW - ago), at(NOW))
    }

    #[test]
    fn recent_edits_use_relative_units() {
        assert_eq!(label(30), "Edited just now");
        assert_eq!(label(5 * 60), "Edited 5m ago");
        assert_eq!(label(3 * 3600 + 10), "Edited 3h ago");
        assert_eq!(label(2 * 86_400), "Edited 2d ago");
    }

    #[test]
    fn older_edits_in_the_same_year_use_month_and_day() {
        assert_eq!(label(7 * 86_400), "Edited Jun 8");
    }

    #[test]
    fn older_years_include_the_year() {
        assert_eq!(format_edited_at(at(1_700_000_000), at(NOW)), "Edited Nov 14, 2023");
    }

    #[test]
    fn future_timestamps_read_as_just_now() {
        assert_eq!(format_edited_at(at(NOW + 500), at(NOW)), "Edited just now");
    }

    #[test]
    fn civil_dates_cross_leap_days() {
        assert_eq!(civil_from_days(0), (1970, 1, 1));
        assert_eq!(civil(at(1_709_164_800)), (2024, 2, 29));
        assert_eq!(civil(at(1_709_251_200)), (2024, 3, 1));
    }
}
