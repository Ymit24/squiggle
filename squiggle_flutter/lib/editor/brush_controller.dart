import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/document_session.dart';

/// Mutates document-local brush preferences without touching canvas history.
class BrushController extends ChangeNotifier {
  BrushController(this._session);

  DocumentSession _session;
  BrushProfile get active => _session.activeBrush;
  List<BrushProfile> get profiles => List.unmodifiable(_session.brushes);
  bool get canCreate => _session.canCreateBrush;

  void bindSession(DocumentSession session) {
    _session = session;
    notifyListeners();
  }

  void activate(String id) {
    if (_session.activeBrushId == id) return;
    if (!_session.brushes.any((brush) => brush.id == id)) return;
    _session.activeBrushId = id;
    notifyListeners();
  }

  BrushProfile create(String name) {
    if (!_session.canCreateBrush) {
      throw StateError('A document can have at most nine brushes.');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    final id = const Uuid().v4();
    final brush = BrushProfile(id: id, name: trimmed, values: active.values);
    _session.brushes.add(brush);
    _session.activeBrushId = brush.id;
    notifyListeners();
    return brush;
  }

  void rename(String id, String name) {
    final brush = _session.brushes.where((brush) => brush.id == id).firstOrNull;
    if (brush == null || brush.isScratch || name.trim().isEmpty) return;
    brush.name = name.trim();
    notifyListeners();
  }

  void delete(String id) {
    final brush = _session.brushes.where((brush) => brush.id == id).firstOrNull;
    if (brush == null || brush.isScratch) return;
    if (active.id == id) {
      _session.scratch.values
        ..clear()
        ..addAll(brush.values);
      _session.activeBrushId = BrushProfile.scratchId;
    }
    _session.brushes.remove(brush);
    notifyListeners();
  }

  /// Moves a named brush to a final index in the full list, after Scratch.
  void move(String id, {required int toIndex}) {
    final oldIndex = _session.brushes.indexWhere((brush) => brush.id == id);
    if (oldIndex <= 0 ||
        toIndex < 1 ||
        toIndex >= _session.brushes.length ||
        oldIndex == toIndex) {
      return;
    }
    final brush = _session.brushes.removeAt(oldIndex);
    _session.brushes.insert(toIndex, brush);
    notifyListeners();
  }

  /// Values are JSON-compatible, encoded by the owning inspector field.
  void setField(String key, Object? value) {
    active.values[key] = value;
    notifyListeners();
  }

  void clearField(String key) {
    if (!active.values.containsKey(key)) return;
    active.values.remove(key);
    notifyListeners();
  }
}
