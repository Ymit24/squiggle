//! Inertial camera pan after a trackpad gesture ends (`fling_controller.dart`): Flutter's
//! `FrictionSimulation` per axis, `x(t) = v0 * (drag^t - 1) / ln(drag)`.

use crate::geom::Point;

pub const DEFAULT_FRICTION: f64 = 0.135;
/// Speed (px/s) under which the simulation counts as finished.
const TOLERANCE: f64 = 1.0;
/// Releases slower than this (px/s) do not fling.
pub const MIN_FLING_VELOCITY: f64 = 50.0;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Fling {
    velocity: Point,
    friction: f64,
    last: Point,
}

impl Fling {
    /// A fling released at `velocity` px/s; `None` when too slow to bother.
    pub fn start(velocity: Point) -> Option<Fling> {
        (velocity.length() >= MIN_FLING_VELOCITY).then_some(Fling { velocity, friction: DEFAULT_FRICTION, last: Point::ZERO })
    }

    fn position(&self, t: f64) -> Point {
        self.velocity * ((self.friction.powf(t) - 1.0) / self.friction.ln())
    }

    fn speed(&self, t: f64) -> f64 {
        self.velocity.length() * self.friction.powf(t)
    }

    pub fn is_done(&self, t: f64) -> bool {
        self.speed(t) < TOLERANCE
    }

    /// Screen-space distance travelled since the previous call, for elapsed time `t` seconds.
    pub fn delta_at(&mut self, t: f64) -> Point {
        let pos = self.position(t);
        let delta = pos - self.last;
        self.last = pos;
        delta
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slow_releases_do_not_fling() {
        assert!(Fling::start(Point::new(10.0, 0.0)).is_none());
    }

    #[test]
    fn decays_towards_a_finite_distance_and_finishes() {
        let mut fling = Fling::start(Point::new(1000.0, 0.0)).unwrap();
        let mut total = Point::ZERO;
        let mut t = 0.0;
        while !fling.is_done(t) && t < 10.0 {
            t += 1.0 / 60.0;
            total = total + fling.delta_at(t);
        }
        assert!(t < 5.0, "finished in {t}s");
        // Terminal distance is v0 / -ln(drag).
        let expected = 1000.0 / -(DEFAULT_FRICTION.ln());
        assert!((total.x - expected).abs() < 5.0, "{total:?} vs {expected}");
        assert_eq!(total.y, 0.0);
    }
}
