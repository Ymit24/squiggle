//! HTTP surface: `GET /healthz`, `GET /v1/auth` and `POST /v1/reports`.

use std::{
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use axum::{
    Json, Router,
    extract::{DefaultBodyLimit, State, rejection::JsonRejection},
    http::{HeaderMap, HeaderValue, StatusCode, header},
    response::{IntoResponse, Response},
    routing::{get, post},
};
use serde_json::json;
use subtle::ConstantTimeEq;
use tower_http::{timeout::TimeoutLayer, trace::TraceLayer};

use crate::{
    github::{IssueTracker, NewIssue},
    rate_limit::TokenBucket,
    report::{ReportError, ReportRequest},
};

/// Comfortably above the largest valid report (4000 chars of 4-byte UTF-8).
const MAX_BODY_BYTES: usize = 24 * 1024;
const SUBMISSION_BURST: u32 = 5;
const SUBMISSION_REFILL: Duration = Duration::from_secs(120);

pub struct AppState<T> {
    tracker: T,
    api_token: String,
    label: String,
    submissions: Mutex<TokenBucket>,
}

impl<T: IssueTracker> AppState<T> {
    pub fn new(tracker: T, api_token: String, label: String) -> Self {
        Self {
            tracker,
            api_token,
            label,
            submissions: Mutex::new(TokenBucket::new(
                SUBMISSION_BURST,
                SUBMISSION_REFILL,
                Instant::now(),
            )),
        }
    }
}

pub fn router<T: IssueTracker>(state: Arc<AppState<T>>) -> Router {
    Router::new()
        .route("/healthz", get(|| async { "ok" }))
        .route("/v1/auth", get(check_auth::<T>))
        .route("/v1/reports", post(create_report::<T>))
        .layer(DefaultBodyLimit::max(MAX_BODY_BYTES))
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(20),
        ))
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

/// Lets a client verify its server URL and token without filing an issue.
async fn check_auth<T: IssueTracker>(
    State(state): State<Arc<AppState<T>>>,
    headers: HeaderMap,
) -> Result<StatusCode, ApiError> {
    authorize(&headers, &state.api_token)?;
    Ok(StatusCode::NO_CONTENT)
}

async fn create_report<T: IssueTracker>(
    State(state): State<Arc<AppState<T>>>,
    headers: HeaderMap,
    body: Result<Json<ReportRequest>, JsonRejection>,
) -> Result<Response, ApiError> {
    authorize(&headers, &state.api_token)?;
    let Json(request) = body.map_err(ApiError::from_rejection)?;
    let report = request.validate().map_err(ApiError::Invalid)?;

    state
        .submissions
        .lock()
        .expect("rate limiter lock poisoned")
        .try_take(Instant::now())
        .map_err(ApiError::RateLimited)?;

    let issue = NewIssue {
        title: report.title.clone(),
        body: report.issue_body(),
        labels: vec![state.label.clone(), report.kind.label().to_owned()],
    };
    let created = state.tracker.create_issue(issue).await.map_err(|err| {
        tracing::error!(error = %err, "failed to create issue");
        ApiError::Upstream
    })?;
    tracing::info!(number = created.number, kind = ?report.kind, "created issue");

    let body = json!({ "number": created.number, "url": created.html_url });
    Ok((StatusCode::CREATED, Json(body)).into_response())
}

fn authorize(headers: &HeaderMap, expected: &str) -> Result<(), ApiError> {
    let provided = headers
        .get(header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "))
        .ok_or(ApiError::Unauthorized)?;
    if bool::from(provided.as_bytes().ct_eq(expected.as_bytes())) {
        Ok(())
    } else {
        tracing::warn!("rejected request with invalid token");
        Err(ApiError::Unauthorized)
    }
}

#[derive(Debug)]
enum ApiError {
    Unauthorized,
    BadBody,
    TooLarge,
    Invalid(ReportError),
    RateLimited(Duration),
    Upstream,
}

impl ApiError {
    fn from_rejection(rejection: JsonRejection) -> Self {
        if rejection.status() == StatusCode::PAYLOAD_TOO_LARGE {
            Self::TooLarge
        } else {
            Self::BadBody
        }
    }

    fn parts(&self) -> (StatusCode, &'static str, String) {
        match self {
            Self::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                "unauthorized",
                "Missing or invalid API token.".into(),
            ),
            Self::BadBody => (
                StatusCode::BAD_REQUEST,
                "invalid_body",
                "Request body is not a valid report.".into(),
            ),
            Self::TooLarge => (
                StatusCode::PAYLOAD_TOO_LARGE,
                "too_large",
                "Report is too large.".into(),
            ),
            Self::Invalid(err) => (StatusCode::UNPROCESSABLE_ENTITY, err.code(), err.message()),
            Self::RateLimited(_) => (
                StatusCode::TOO_MANY_REQUESTS,
                "rate_limited",
                "Too many reports; try again in a few minutes.".into(),
            ),
            Self::Upstream => (
                StatusCode::BAD_GATEWAY,
                "upstream_failed",
                "Could not create the GitHub issue.".into(),
            ),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code, message) = self.parts();
        let mut response =
            (status, Json(json!({ "error": code, "message": message }))).into_response();
        if let Self::RateLimited(wait) = self {
            let seconds = wait.as_secs() + 1;
            response
                .headers_mut()
                .insert(header::RETRY_AFTER, HeaderValue::from(seconds));
        }
        response
    }
}

#[cfg(test)]
mod tests {
    use axum::body::Body;
    use axum::http::Request;
    use http_body_util::BodyExt;
    use serde_json::Value;
    use tower::ServiceExt;

    use super::*;
    use crate::github::{CreatedIssue, TrackerError};

    const TOKEN: &str = "0123456789abcdef0123456789abcdef";

    #[derive(Default)]
    struct FakeTracker {
        issues: Mutex<Vec<NewIssue>>,
        fail: bool,
    }

    impl IssueTracker for FakeTracker {
        async fn create_issue(&self, issue: NewIssue) -> Result<CreatedIssue, TrackerError> {
            if self.fail {
                return Err(TrackerError::Status(StatusCode::FORBIDDEN, "nope".into()));
            }
            let mut issues = self.issues.lock().unwrap();
            issues.push(issue);
            Ok(CreatedIssue {
                number: issues.len() as u64,
                html_url: format!("https://github.com/o/r/issues/{}", issues.len()),
            })
        }
    }

    fn app(tracker: FakeTracker) -> (Router, Arc<AppState<FakeTracker>>) {
        let state = Arc::new(AppState::new(
            tracker,
            TOKEN.into(),
            "app-submission".into(),
        ));
        (router(state.clone()), state)
    }

    fn post_report(token: Option<&str>, body: impl Into<Body>) -> Request<Body> {
        let mut builder = Request::post("/v1/reports").header("content-type", "application/json");
        if let Some(token) = token {
            builder = builder.header("authorization", format!("Bearer {token}"));
        }
        builder.body(body.into()).unwrap()
    }

    async fn send(router: &Router, request: Request<Body>) -> (StatusCode, HeaderMap, Value) {
        let response = router.clone().oneshot(request).await.unwrap();
        let status = response.status();
        let headers = response.headers().clone();
        let bytes = response.into_body().collect().await.unwrap().to_bytes();
        let body = serde_json::from_slice(&bytes).unwrap_or(Value::Null);
        (status, headers, body)
    }

    const VALID: &str = r#"{"kind":"bug","title":"Crash on save","description":"steps","app_version":"0.2.34+77","platform":"linux"}"#;

    #[tokio::test]
    async fn creates_labelled_issue() {
        let (router, state) = app(FakeTracker::default());
        let (status, _, body) = send(&router, post_report(Some(TOKEN), VALID)).await;

        assert_eq!(status, StatusCode::CREATED);
        assert_eq!(body["number"], 1);
        assert_eq!(body["url"], "https://github.com/o/r/issues/1");
        let issues = state.tracker.issues.lock().unwrap();
        assert_eq!(issues[0].title, "Crash on save");
        assert_eq!(issues[0].labels, ["app-submission", "bug"]);
        assert!(issues[0].body.contains("Bug report · v0.2.34+77 · Linux"));
    }

    #[tokio::test]
    async fn rejects_missing_or_wrong_token_before_reading_body() {
        let (router, state) = app(FakeTracker::default());
        for token in [None, Some("wrong"), Some(&TOKEN[..31])] {
            let (status, _, body) = send(&router, post_report(token, "not json")).await;
            assert_eq!(status, StatusCode::UNAUTHORIZED);
            assert_eq!(body["error"], "unauthorized");
        }
        assert!(state.tracker.issues.lock().unwrap().is_empty());
    }

    #[tokio::test]
    async fn auth_check_endpoint() {
        let (router, _) = app(FakeTracker::default());
        let ok = Request::get("/v1/auth")
            .header("authorization", format!("Bearer {TOKEN}"))
            .body(Body::empty())
            .unwrap();
        assert_eq!(send(&router, ok).await.0, StatusCode::NO_CONTENT);
        let bad = Request::get("/v1/auth").body(Body::empty()).unwrap();
        assert_eq!(send(&router, bad).await.0, StatusCode::UNAUTHORIZED);
    }

    #[tokio::test]
    async fn rejects_malformed_and_invalid_reports() {
        let (router, _) = app(FakeTracker::default());
        let cases = [
            ("{", StatusCode::BAD_REQUEST, "invalid_body"),
            (
                r#"{"kind":"admin","title":"x"}"#,
                StatusCode::BAD_REQUEST,
                "invalid_body",
            ),
            (
                r#"{"kind":"bug","title":"x","labels":["a"]}"#,
                StatusCode::BAD_REQUEST,
                "invalid_body",
            ),
            (
                r#"{"kind":"bug","title":"   "}"#,
                StatusCode::UNPROCESSABLE_ENTITY,
                "title_empty",
            ),
        ];
        for (body, expected_status, expected_code) in cases {
            let (status, _, json) = send(&router, post_report(Some(TOKEN), body)).await;
            assert_eq!(status, expected_status, "{body}");
            assert_eq!(json["error"], expected_code, "{body}");
        }
    }

    #[tokio::test]
    async fn rejects_oversized_body() {
        let (router, _) = app(FakeTracker::default());
        let huge = format!(
            r#"{{"kind":"bug","title":"x","description":"{}"}}"#,
            "a".repeat(MAX_BODY_BYTES)
        );
        let (status, _, json) = send(&router, post_report(Some(TOKEN), huge)).await;
        assert_eq!(status, StatusCode::PAYLOAD_TOO_LARGE);
        assert_eq!(json["error"], "too_large");
    }

    #[tokio::test]
    async fn rate_limits_submissions_but_not_validation_failures() {
        let (router, _) = app(FakeTracker::default());
        let invalid = r#"{"kind":"bug","title":""}"#;
        for _ in 0..10 {
            send(&router, post_report(Some(TOKEN), invalid)).await;
        }
        for _ in 0..SUBMISSION_BURST {
            assert_eq!(
                send(&router, post_report(Some(TOKEN), VALID)).await.0,
                StatusCode::CREATED
            );
        }
        let (status, headers, json) = send(&router, post_report(Some(TOKEN), VALID)).await;
        assert_eq!(status, StatusCode::TOO_MANY_REQUESTS);
        assert_eq!(json["error"], "rate_limited");
        assert!(headers.contains_key(header::RETRY_AFTER));
    }

    #[tokio::test]
    async fn hides_upstream_error_details() {
        let (router, _) = app(FakeTracker {
            fail: true,
            ..Default::default()
        });
        let (status, _, json) = send(&router, post_report(Some(TOKEN), VALID)).await;
        assert_eq!(status, StatusCode::BAD_GATEWAY);
        assert_eq!(json["error"], "upstream_failed");
        assert!(!json.to_string().contains("nope"));
    }
}
