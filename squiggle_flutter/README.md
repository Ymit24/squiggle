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

Every push to `main` (including a merged pull request) runs the Linux release
workflow. The workflow runs the tests, builds the Flutter app in release mode,
and publishes the complete x64 Linux bundle as a `.tar.gz` file on the GitHub
Releases page.

The project uses pre-1.0, zero-based versions. For example, a current Flutter
version of `0.0.1+2` becomes `0.0.2+3`: the patch and Flutter build numbers are
incremented for each release. The workflow commits this update to
`pubspec.yaml` and creates the matching `v0.0.2` tag. Add the `release:minor`
label to a pull request to increment the minor version and reset the patch
version when it merges. For example, merging a labeled pull request when the
current version is `0.0.3+4` produces `0.1.0+5` and the `v0.1.0` tag. Pull
requests without the label and direct pushes continue to increment the patch
version.

The workflow can also be started manually from the repository's **Actions**
tab with either a patch or minor bump. It needs the repository's workflow token
to have write access so it can push the version commit and create the tag and
release. If branch protection blocks direct pushes to `main`, allow GitHub
Actions to bypass that rule or use a dedicated release branch/process instead.
