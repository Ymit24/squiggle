import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/brush_profile.dart';

/// Document-local editor state. Canvas nodes never reference these profiles.
class DocumentSession {
  DocumentSession({
    Iterable<BrushProfile> brushes = const [],
    String? activeBrushId,
  }) : brushes = List.of(brushes),
       activeBrushId = activeBrushId ?? BrushProfile.scratchId {
    final ids = <String>{};
    this.brushes.removeWhere((brush) => !ids.add(brush.id));
    if (!this.brushes.any((brush) => brush.isScratch)) {
      this.brushes.insert(
        0,
        BrushProfile(id: BrushProfile.scratchId, name: 'Scratch'),
      );
    }
    scratch.name = 'Scratch';
    if (!this.brushes.any((brush) => brush.id == this.activeBrushId)) {
      this.activeBrushId = BrushProfile.scratchId;
    }
  }

  final List<BrushProfile> brushes;
  String activeBrushId;
  BrushProfile get scratch => brushes.firstWhere((brush) => brush.isScratch);
  BrushProfile get activeBrush =>
      brushes.firstWhere((brush) => brush.id == activeBrushId);

  factory DocumentSession.fromDataModel(data.DocumentSession raw) =>
      DocumentSession(
        brushes: raw.brushes.map(BrushProfile.fromDataModel),
        activeBrushId: raw.activeBrushId,
      );

  data.DocumentSession toDataModel() => data.DocumentSession(
    brushes: brushes.map((brush) => brush.toDataModel()).toList(),
    activeBrushId: activeBrushId,
  );
}
