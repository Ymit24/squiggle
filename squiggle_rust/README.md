# Squiggle (Rust + Rune)

A port of the Flutter app in `../squiggle_flutter` to Rust, built on the
[Rune](https://github.com/anomalyco/rune) UI framework (pinned by git rev in `Cargo.toml`).

```
crates/squiggle-core   document model, history, tools, persistence; no UI dependency
crates/squiggle-app    Rune UI: library page, editor, toolbar, inspector, brush wheel
```

Documents use the same on-disk JSON format (version 2) as the Flutter app.

## Build and test

```sh
sudo apt-get install libxkbcommon-dev libwayland-dev   # Linux
cargo test --workspace
cargo run -p squiggle
```

UI tests run Rune's headless `Runtime`, so they need no GPU. Running the app needs a GPU/Vulkan driver.
See `PORTING.md` for architecture and how the Dart concepts map onto Rust.
