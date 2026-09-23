# squiggle_flutter

A new Flutter project.

## Tests

Run the full suite from this directory with `flutter test`. Related test cases
live in `test/**/*_cases.dart`; the eight `test/*_test.dart` files import them
and are the runner entry points. This keeps the existing test coverage while
reducing the number of Flutter test processes and compilations.

When adding test cases, put them in the appropriate cases file and keep its
`main()` registered in the corresponding runner. To run one group, pass its
runner path to `flutter test`, for example `flutter test test/models_core_test.dart`.

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

Every push to `main` increments the version in `pubspec.yaml`. By default, the
patch and Flutter build numbers increase, so `0.1.4+12` becomes `0.1.5+13`.
When a merged pull request has the `release:minor` label, the minor and build
numbers increase and the patch resets, so `0.1.4+12` becomes `0.2.0+13`.

Only minor version bumps generate a Linux release. For those bumps, the
workflow runs the tests, builds the Flutter app in release mode, and publishes
the complete x64 Linux bundle as a `.tar.gz` file on the GitHub Releases page.
Patch bumps only commit the updated `pubspec.yaml`; they do not build, tag, or
publish a release.

The workflow can also be started manually from the repository's **Actions**
tab with either a patch or minor bump. A manual minor bump generates a release,
while a manual patch bump only updates the version. The workflow token needs
write access so it can push the version commit and, for minor bumps, create the
tag and release. If branch protection blocks direct pushes to `main`, allow
GitHub Actions to bypass that rule or use a dedicated release branch/process
instead.
