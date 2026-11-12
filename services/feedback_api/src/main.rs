mod api;
mod config;
mod github;
mod rate_limit;
mod report;

use std::{process::ExitCode, sync::Arc};

use tokio::net::TcpListener;
use tracing_subscriber::EnvFilter;

use crate::{api::AppState, config::Config, github::GitHub};

#[tokio::main]
async fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();

    match run().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            tracing::error!("{err}");
            ExitCode::FAILURE
        }
    }
}

async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env()?;
    let github = GitHub::new(
        &config.github_api,
        &config.github_repo,
        &config.github_token,
    )?;

    // Not fatal: GitHub also creates missing labels when an issue uses them,
    // just without the color and description.
    if let Err(err) = github
        .ensure_label(
            &config.label,
            "5319E7",
            "Submitted from the in-app report button",
        )
        .await
    {
        tracing::warn!("could not ensure label {:?} exists: {err}", config.label);
    }

    let state = Arc::new(AppState::new(github, config.api_token, config.label));
    let listener = TcpListener::bind(config.bind).await?;
    tracing::info!(
        "listening on {}, filing into {}",
        config.bind,
        config.github_repo
    );
    axum::serve(listener, api::router(state))
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c().await.ok();
    };
    let terminate = async {
        if let Ok(mut signal) =
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
        {
            signal.recv().await;
        }
    };
    tokio::select! {
        () = ctrl_c => {},
        () = terminate => {},
    }
}
