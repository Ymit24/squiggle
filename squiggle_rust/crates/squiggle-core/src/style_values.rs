//! Shared primitive conversions for feature persistence and inspector fields
//! (port of `style_value_serialization.dart`).

use crate::color::Color;
use serde_json::Value;

/// An enum persisted by its Dart-compatible lower-camel `name`.
pub trait StyleEnum: Copy + 'static {
    const VARIANTS: &'static [Self];
    fn variant_name(self) -> &'static str;
}

/// Declares a unit-variant enum with Dart-style persisted names and [`StyleEnum`].
macro_rules! style_enum {
    ($(#[$meta:meta])* $vis:vis enum $name:ident { $($(#[$vmeta:meta])* $variant:ident => $str:literal),+ $(,)? }) => {
        $(#[$meta])*
        #[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
        $vis enum $name { $($(#[$vmeta])* $variant),+ }

        impl $crate::style_values::StyleEnum for $name {
            const VARIANTS: &'static [Self] = &[$($name::$variant),+];
            fn variant_name(self) -> &'static str {
                match self { $($name::$variant => $str),+ }
            }
        }

        impl $name {
            /// All variants in declaration order.
            pub const ALL: &'static [$name] = &[$($name::$variant),+];

            /// Persisted name (`Enum.name` in Dart).
            pub fn name(self) -> &'static str {
                <Self as $crate::style_values::StyleEnum>::variant_name(self)
            }

            /// Variant with the given persisted name.
            pub fn from_name(name: &str) -> Option<Self> {
                Self::ALL.iter().copied().find(|v| v.name() == name)
            }
        }
    };
}
pub(crate) use style_enum;

/// ARGB integer in `0..=0xFFFFFFFF`.
pub fn decode_style_color(raw: Option<&Value>) -> Result<Color, String> {
    raw.and_then(Value::as_u64)
        .filter(|v| *v <= 0xFFFF_FFFF)
        .map(|v| Color(v as u32))
        .ok_or_else(|| "Expected an ARGB color integer.".to_owned())
}

/// Any finite JSON number.
pub fn decode_style_number(raw: Option<&Value>) -> Result<f64, String> {
    raw.and_then(Value::as_f64)
        .filter(|v| v.is_finite())
        .ok_or_else(|| "Expected a finite number.".to_owned())
}

/// A finite number greater than zero.
pub fn decode_positive_number(raw: Option<&Value>) -> Result<f64, String> {
    let value = decode_style_number(raw)?;
    if value <= 0.0 {
        return Err("Expected a positive number.".to_owned());
    }
    Ok(value)
}

/// Enum by persisted name; unknown or non-string values are an error.
pub fn decode_style_enum<T: StyleEnum>(raw: Option<&Value>) -> Result<T, String> {
    let name = raw.and_then(Value::as_str);
    name.and_then(|n| T::VARIANTS.iter().copied().find(|v| v.variant_name() == n))
        .ok_or_else(|| format!("Unknown enum value: {raw:?}"))
}

/// Like [`decode_style_enum`] but unknown values give `fallback`.
pub fn decode_style_enum_or<T: StyleEnum>(raw: Option<&Value>, fallback: T) -> T {
    decode_style_enum(raw).unwrap_or(fallback)
}

/// Required string field.
pub fn decode_string(raw: Option<&Value>, what: &str) -> Result<String, String> {
    raw.and_then(Value::as_str).map(str::to_owned).ok_or_else(|| format!("Expected string for {what}"))
}

/// JSON number from a double (finite assumed).
pub fn num(value: f64) -> Value {
    serde_json::Number::from_f64(value).map_or(Value::Null, Value::Number)
}
