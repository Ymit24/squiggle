import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

class ToolbarBloc extends Bloc<ToolbarEvent, ToolbarState> {
  ToolbarBloc({
    required this._toolRepository,
    required this._selectionRepository,
  }) : super(const ToolbarState(activeTool: ActiveToolKind.select)) {
    on<ActivateSelectToolEvent>(_onActivateSelectTool);
  }

  final ToolRepository _toolRepository;
  final SelectionRepository _selectionRepository;

  void _onActivateSelectTool(
    ActivateSelectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(SelectTool(), _selectionRepository);
    emit(const ToolbarState(activeTool: ActiveToolKind.select));
  }
}
