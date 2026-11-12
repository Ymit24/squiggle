//! The only GitHub operations this service performs: create an issue and make
//! sure the submission label exists.

use std::{fmt, future::Future, time::Duration};

use reqwest::{RequestBuilder, StatusCode};
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Clone, Serialize)]
pub struct NewIssue {
    pub title: String,
    pub body: String,
    pub labels: Vec<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CreatedIssue {
    pub number: u64,
    pub html_url: String,
}

#[derive(Debug)]
pub enum TrackerError {
    Request(reqwest::Error),
    Status(StatusCode, String),
}

impl fmt::Display for TrackerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Request(err) => write!(f, "request to GitHub failed: {err}"),
            Self::Status(status, body) => write!(f, "GitHub responded {status}: {body}"),
        }
    }
}

impl std::error::Error for TrackerError {}

impl From<reqwest::Error> for TrackerError {
    fn from(err: reqwest::Error) -> Self {
        Self::Request(err)
    }
}

/// Where reports end up. Abstracted so the HTTP layer can be tested without
/// talking to GitHub.
pub trait IssueTracker: Send + Sync + 'static {
    fn create_issue(
        &self,
        issue: NewIssue,
    ) -> impl Future<Output = Result<CreatedIssue, TrackerError>> + Send;
}

pub struct GitHub {
    client: reqwest::Client,
    api_base: String,
    repo: String,
    token: String,
}

impl GitHub {
    pub fn new(api_base: &str, repo: &str, token: &str) -> reqwest::Result<Self> {
        let client = reqwest::Client::builder()
            .user_agent(concat!("squiggle-feedback-api/", env!("CARGO_PKG_VERSION")))
            .timeout(Duration::from_secs(10))
            .build()?;
        Ok(Self {
            client,
            api_base: api_base.trim_end_matches('/').to_owned(),
            repo: repo.to_owned(),
            token: token.to_owned(),
        })
    }

    /// Creates `name` unless it already exists. `name` is validated at config
    /// load to be URL-path safe.
    pub async fn ensure_label(
        &self,
        name: &str,
        color: &str,
        description: &str,
    ) -> Result<(), TrackerError> {
        let existing = self
            .send(self.client.get(self.url(&format!("labels/{name}"))))
            .await?;
        if existing.status().is_success() {
            return Ok(());
        }
        if existing.status() != StatusCode::NOT_FOUND {
            return Err(status_error(existing).await);
        }
        let body = json!({ "name": name, "color": color, "description": description });
        let created = self
            .send(self.client.post(self.url("labels")).json(&body))
            .await?;
        // 422 means someone created it in the meantime.
        if created.status().is_success() || created.status() == StatusCode::UNPROCESSABLE_ENTITY {
            return Ok(());
        }
        Err(status_error(created).await)
    }

    fn url(&self, path: &str) -> String {
        format!("{}/repos/{}/{path}", self.api_base, self.repo)
    }

    async fn send(&self, request: RequestBuilder) -> Result<reqwest::Response, TrackerError> {
        Ok(request
            .bearer_auth(&self.token)
            .header("Accept", "application/vnd.github+json")
            .header("X-GitHub-Api-Version", "2022-11-28")
            .send()
            .await?)
    }
}

impl IssueTracker for GitHub {
    async fn create_issue(&self, issue: NewIssue) -> Result<CreatedIssue, TrackerError> {
        let response = self
            .send(self.client.post(self.url("issues")).json(&issue))
            .await?;
        if !response.status().is_success() {
            return Err(status_error(response).await);
        }
        Ok(response.json().await?)
    }
}

async fn status_error(response: reqwest::Response) -> TrackerError {
    let status = response.status();
    let body = response.text().await.unwrap_or_default();
    TrackerError::Status(status, body.chars().take(500).collect())
}
