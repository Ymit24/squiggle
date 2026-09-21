# squiggle_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Linux releases

A Linux release is created only when a pull request with the `release:minor`
label is merged into `main`. Ordinary merges and direct pushes do not run a
release build. The workflow runs the tests, builds the Flutter app in release
mode, and publishes the complete x64 Linux bundle as a `.tar.gz` file on the
GitHub Releases page.

The project uses pre-1.0, zero-based versions. Each release increments the
minor and Flutter build numbers and resets the patch number. For example,
`0.1.4+12` becomes `0.2.0+13`. The workflow commits this update to
`pubspec.yaml` and creates the matching `v0.2.0` tag.

The workflow can also be started manually from the repository's **Actions**
tab; manual runs always perform a minor release. It needs the repository's
workflow token to have write access so it can push the version commit and
create the tag and release. If branch protection blocks direct pushes to
`main`, allow GitHub Actions to bypass that rule or use a dedicated release
branch/process instead.
