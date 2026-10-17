import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Content-addressed PNG storage on disk.
///
/// An image id is the sha256 hex digest of its bytes, so storing the same
/// image twice yields the same id and a single file. Files from before ids
/// were hashes (`img_<ms>_<hex>.png`) are named by their id too, so they still
/// load.
class ImageStore {
  ImageStore({Directory? directory})
    : _directory = directory; // ignore: prefer_initializing_formals

  Directory? _directory;

  /// Stores [bytes] and returns their id.
  Future<String> put(Uint8List bytes) async {
    final id = sha256.convert(bytes).toString();
    final directory = await _resolveDirectory();
    final file = File('${directory.path}/$id');
    if (await file.exists()) {
      return id;
    }

    // Write beside the target and rename, so an interrupted write never leaves
    // a truncated file under the final name.
    final partial = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    return id;
  }

  /// Returns the bytes for [id], or null if no such image is stored.
  Future<Uint8List?> get(String id) async {
    final file = File('${(await _resolveDirectory()).path}/$id');
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  Future<Directory> _resolveDirectory() async {
    final directory = _directory ??= await _defaultDirectory();
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _defaultDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}/Squiggle/images');
  }
}
