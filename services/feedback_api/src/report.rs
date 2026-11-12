//! Validation and sanitization of client reports, and how they render as
//! GitHub issues. Everything a client sends passes through
//! [`ReportRequest::validate`] before it can reach GitHub.

use serde::Deserialize;

pub const MAX_TITLE_CHARS: usize = 120;
pub const MAX_DESCRIPTION_CHARS: usize = 4000;
const MAX_APP_VERSION_CHARS: usize = 32;

/// The JSON body clients POST. Unknown fields are rejected so the accepted
/// surface stays exactly this.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ReportRequest {
    pub kind: ReportKind,
    pub title: String,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub app_version: Option<String>,
    #[serde(default)]
    pub platform: Option<Platform>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ReportKind {
    Bug,
    Feature,
}

impl ReportKind {
    /// The existing repository label for this kind of report.
    pub fn label(self) -> &'static str {
        match self {
            Self::Bug => "bug",
            Self::Feature => "enhancement",
        }
    }

    fn display(self) -> &'static str {
        match self {
            Self::Bug => "Bug report",
            Self::Feature => "Feature request",
        }
    }
}

/// Mirrors Dart's `Platform.operatingSystem` values.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Platform {
    Linux,
    Macos,
    Windows,
    Android,
    Ios,
    Fuchsia,
}

impl Platform {
    fn display(self) -> &'static str {
        match self {
            Self::Linux => "Linux",
            Self::Macos => "macOS",
            Self::Windows => "Windows",
            Self::Android => "Android",
            Self::Ios => "iOS",
            Self::Fuchsia => "Fuchsia",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReportError {
    TitleEmpty,
    TitleTooLong,
    DescriptionTooLong,
    InvalidAppVersion,
}

impl ReportError {
    pub fn code(self) -> &'static str {
        match self {
            Self::TitleEmpty => "title_empty",
            Self::TitleTooLong => "title_too_long",
            Self::DescriptionTooLong => "description_too_long",
            Self::InvalidAppVersion => "invalid_app_version",
        }
    }

    pub fn message(self) -> String {
        match self {
            Self::TitleEmpty => "Title is required.".into(),
            Self::TitleTooLong => format!("Title must be at most {MAX_TITLE_CHARS} characters."),
            Self::DescriptionTooLong => {
                format!("Description must be at most {MAX_DESCRIPTION_CHARS} characters.")
            }
            Self::InvalidAppVersion => "App version is malformed.".into(),
        }
    }
}

/// A report that passed validation; its fields are safe to send to GitHub.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Report {
    pub kind: ReportKind,
    pub title: String,
    pub description: String,
    pub app_version: Option<String>,
    pub platform: Option<Platform>,
}

impl ReportRequest {
    pub fn validate(self) -> Result<Report, ReportError> {
        let title = sanitize_title(&self.title);
        if title.is_empty() {
            return Err(ReportError::TitleEmpty);
        }
        if title.chars().count() > MAX_TITLE_CHARS {
            return Err(ReportError::TitleTooLong);
        }
        let description = sanitize_description(&self.description);
        if description.chars().count() > MAX_DESCRIPTION_CHARS {
            return Err(ReportError::DescriptionTooLong);
        }
        let app_version = self
            .app_version
            .map(|version| validate_app_version(&version))
            .transpose()?;
        Ok(Report {
            kind: self.kind,
            title,
            description,
            app_version,
            platform: self.platform,
        })
    }
}

impl Report {
    pub fn issue_body(&self) -> String {
        let description = if self.description.is_empty() {
            "_No description provided._".to_owned()
        } else {
            neutralize_mentions(&self.description)
        };
        let mut footer = vec![self.kind.display().to_owned()];
        if let Some(version) = &self.app_version {
            footer.push(format!("v{version}"));
        }
        if let Some(platform) = self.platform {
            footer.push(platform.display().to_owned());
        }
        format!(
            "{description}\n\n---\n<sub>Submitted from the Squiggle app · {}</sub>\n",
            footer.join(" · ")
        )
    }
}

/// Bidirectional overrides and isolates can make text render differently from
/// how it reads, so they are dropped along with control characters.
fn is_disallowed(c: char) -> bool {
    c.is_control() || matches!(c, '\u{202A}'..='\u{202E}' | '\u{2066}'..='\u{2069}')
}

/// Single line, no control characters, whitespace collapsed.
fn sanitize_title(raw: &str) -> String {
    raw.split(|c: char| c.is_whitespace() || is_disallowed(c))
        .filter(|word| !word.is_empty())
        .collect::<Vec<_>>()
        .join(" ")
}

/// Newlines normalized to `\n`; other control characters except tabs dropped.
fn sanitize_description(raw: &str) -> String {
    raw.replace("\r\n", "\n")
        .replace('\r', "\n")
        .chars()
        .filter(|&c| c == '\n' || c == '\t' || !is_disallowed(c))
        .collect::<String>()
        .trim()
        .to_owned()
}

fn validate_app_version(raw: &str) -> Result<String, ReportError> {
    let valid = !raw.is_empty()
        && raw.len() <= MAX_APP_VERSION_CHARS
        && raw
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '+' | '-'));
    if valid {
        Ok(raw.to_owned())
    } else {
        Err(ReportError::InvalidAppVersion)
    }
}

/// Puts a zero-width space after `@` when it starts a handle, so text from a
/// report can never notify a GitHub user or team.
fn neutralize_mentions(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        out.push(c);
        if c == '@'
            && chars
                .peek()
                .is_some_and(|next| next.is_ascii_alphanumeric())
        {
            out.push('\u{200B}');
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn request(title: &str, description: &str) -> ReportRequest {
        ReportRequest {
            kind: ReportKind::Bug,
            title: title.into(),
            description: description.into(),
            app_version: None,
            platform: None,
        }
    }

    #[test]
    fn title_is_collapsed_to_one_clean_line() {
        let report = request("  Crash\n on\t\u{202E}save\u{0007}  ", "")
            .validate()
            .unwrap();
        assert_eq!(report.title, "Crash on save");
    }

    #[test]
    fn blank_title_is_rejected() {
        let err = request(" \n\u{0000} ", "").validate().unwrap_err();
        assert_eq!(err, ReportError::TitleEmpty);
    }

    #[test]
    fn length_limits_count_characters_not_bytes() {
        assert!(request(&"é".repeat(MAX_TITLE_CHARS), "").validate().is_ok());
        assert_eq!(
            request(&"é".repeat(MAX_TITLE_CHARS + 1), "")
                .validate()
                .unwrap_err(),
            ReportError::TitleTooLong
        );
        assert_eq!(
            request("t", &"x".repeat(MAX_DESCRIPTION_CHARS + 1))
                .validate()
                .unwrap_err(),
            ReportError::DescriptionTooLong
        );
    }

    #[test]
    fn description_keeps_lines_but_drops_controls() {
        let report = request("t", "\n line one\r\nline\u{0008} two\rthree\t! \n")
            .validate()
            .unwrap();
        assert_eq!(report.description, "line one\nline two\nthree\t!");
    }

    #[test]
    fn app_version_must_look_like_a_version() {
        let mut ok = request("t", "");
        ok.app_version = Some("0.2.34+77".into());
        assert_eq!(
            ok.validate().unwrap().app_version.as_deref(),
            Some("0.2.34+77")
        );

        let mut bad = request("t", "");
        bad.app_version = Some("1.0 <img src=x>".into());
        assert_eq!(bad.validate().unwrap_err(), ReportError::InvalidAppVersion);
    }

    #[test]
    fn body_neutralizes_mentions_and_adds_footer() {
        let mut req = request("t", "cc @octocat and @org/team, mail me@x.dev, lone @ sign");
        req.kind = ReportKind::Feature;
        req.app_version = Some("1.2.3".into());
        req.platform = Some(Platform::Macos);
        let body = req.validate().unwrap().issue_body();
        assert!(body.starts_with(
            "cc @\u{200B}octocat and @\u{200B}org/team, mail me@\u{200B}x.dev, lone @ sign\n"
        ));
        assert!(body.ends_with(
            "<sub>Submitted from the Squiggle app · Feature request · v1.2.3 · macOS</sub>\n"
        ));
    }

    #[test]
    fn empty_description_gets_placeholder() {
        let body = request("t", "  ").validate().unwrap().issue_body();
        assert!(body.starts_with("_No description provided._"));
    }

    #[test]
    fn unknown_fields_are_rejected() {
        let json = r#"{"kind":"bug","title":"t","labels":["admin"]}"#;
        assert!(serde_json::from_str::<ReportRequest>(json).is_err());
    }
}
