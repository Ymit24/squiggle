use std::net::SocketAddr;

const MIN_API_TOKEN_LEN: usize = 32;

#[derive(Debug, Clone)]
pub struct Config {
    pub bind: SocketAddr,
    /// Shared secret clients send as `Authorization: Bearer <token>`.
    pub api_token: String,
    pub github_token: String,
    /// `owner/name`.
    pub github_repo: String,
    pub github_api: String,
    /// Label added to every submitted issue so they can be filtered.
    pub label: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        Self::from_lookup(|key| std::env::var(key).ok().filter(|value| !value.is_empty()))
    }

    fn from_lookup(get: impl Fn(&str) -> Option<String>) -> Result<Self, String> {
        let required = |key: &str| get(key).ok_or_else(|| format!("{key} is required"));

        let bind = get("FEEDBACK_BIND")
            .unwrap_or_else(|| "127.0.0.1:8787".into())
            .parse()
            .map_err(|err| format!("FEEDBACK_BIND is not a socket address: {err}"))?;

        let api_token = required("FEEDBACK_API_TOKEN")?;
        if api_token.len() < MIN_API_TOKEN_LEN {
            return Err(format!(
                "FEEDBACK_API_TOKEN must be at least {MIN_API_TOKEN_LEN} characters (try `openssl rand -hex 32`)"
            ));
        }

        let github_repo = required("FEEDBACK_GITHUB_REPO")?;
        if !is_repo_slug(&github_repo) {
            return Err("FEEDBACK_GITHUB_REPO must look like owner/name".into());
        }

        let label = get("FEEDBACK_LABEL").unwrap_or_else(|| "app-submission".into());
        if !is_label_slug(&label) {
            return Err("FEEDBACK_LABEL may only contain a-z, 0-9 and '-'".into());
        }

        Ok(Self {
            bind,
            api_token,
            github_token: required("FEEDBACK_GITHUB_TOKEN")?,
            github_repo,
            github_api: get("FEEDBACK_GITHUB_API")
                .unwrap_or_else(|| "https://api.github.com".into()),
            label,
        })
    }
}

fn is_repo_slug(value: &str) -> bool {
    let part_ok = |part: &str| {
        !part.is_empty()
            && part
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_' | '.'))
            && part != "."
            && part != ".."
    };
    matches!(value.split_once('/'), Some((owner, name)) if part_ok(owner) && part_ok(name))
}

fn is_label_slug(value: &str) -> bool {
    (1..=50).contains(&value.len())
        && value
            .chars()
            .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;

    fn load(pairs: &[(&str, &str)]) -> Result<Config, String> {
        let env: HashMap<_, _> = pairs
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect();
        Config::from_lookup(|key| env.get(key).cloned())
    }

    const BASE: [(&str, &str); 3] = [
        ("FEEDBACK_API_TOKEN", "0123456789abcdef0123456789abcdef"),
        ("FEEDBACK_GITHUB_TOKEN", "github_pat_x"),
        ("FEEDBACK_GITHUB_REPO", "Ymit24/squiggle"),
    ];

    #[test]
    fn loads_with_defaults() {
        let config = load(&BASE).unwrap();
        assert_eq!(config.bind.to_string(), "127.0.0.1:8787");
        assert_eq!(config.label, "app-submission");
        assert_eq!(config.github_api, "https://api.github.com");
    }

    #[test]
    fn rejects_short_api_token() {
        let mut env = BASE.to_vec();
        env[0].1 = "short";
        assert!(load(&env).unwrap_err().contains("FEEDBACK_API_TOKEN"));
    }

    #[test]
    fn rejects_bad_repo_and_label() {
        for repo in ["squiggle", "a/b/c", "../x", "a/..", "a/b?c"] {
            let mut env = BASE.to_vec();
            env[2].1 = repo;
            assert!(load(&env).is_err(), "{repo} should be rejected");
        }
        let mut env = BASE.to_vec();
        env.push(("FEEDBACK_LABEL", "Has Space"));
        assert!(load(&env).is_err());
    }

    #[test]
    fn reports_missing_variable() {
        assert_eq!(
            load(&BASE[..2]).unwrap_err(),
            "FEEDBACK_GITHUB_REPO is required"
        );
    }
}
