The Drift web worker is copied from drift 2.35.2, and `sqlite3.wasm` is from
sqlite3 3.5.2. Keep these assets aligned with the versions in pubspec.lock when
upgrading either dependency. Production hosting must serve `sqlite3.wasm` with
the `application/wasm` content type.
