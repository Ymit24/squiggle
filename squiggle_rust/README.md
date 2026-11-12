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

## Headless snapshots (no display or GPU)

`cargo run --release -p squiggle -- --snap out.png [--scene editor]` renders one frame to a PNG. On a
machine without a GPU, point the Vulkan loader at Mesa's software driver (lavapipe), e.g. from the
`libvulkan1` and `mesa-vulkan-drivers` packages: set `VK_ICD_FILENAMES` to `lvp_icd.json` and
`LD_LIBRARY_PATH` to the directory holding `libvulkan.so.1`, `libvulkan_lvp.so`, `libxcb-shm.so.0` and
`libwayland-client.so.0`. Reference snapshots: `docs/library.png`, `docs/editor.png`.
