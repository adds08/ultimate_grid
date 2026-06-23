import 'package:flutter/foundation.dart';

import 'mock_data.dart';
import 'models.dart';

const double kDailyRegularHours = 8;
const int kHistoryCap = 50;

@immutable
class LogSnapshot {
  final List<String> engineerIds;
  final List<String> columnIds;
  final Map<String, Map<String, double>> cells;
  final Map<String, AbsenceInfo> absent;
  final Map<String, double> budgets;
  final Map<String, CompHours> comp;

  const LogSnapshot({
    required this.engineerIds,
    required this.columnIds,
    required this.cells,
    required this.absent,
    required this.budgets,
    required this.comp,
  });

  LogSnapshot copyWith({
    List<String>? engineerIds,
    List<String>? columnIds,
    Map<String, Map<String, double>>? cells,
    Map<String, AbsenceInfo>? absent,
    Map<String, double>? budgets,
    Map<String, CompHours>? comp,
  }) {
    return LogSnapshot(
      engineerIds: engineerIds ?? this.engineerIds,
      columnIds: columnIds ?? this.columnIds,
      cells: cells ?? this.cells,
      absent: absent ?? this.absent,
      budgets: budgets ?? this.budgets,
      comp: comp ?? this.comp,
    );
  }
}

class OfficeLogState extends ChangeNotifier {
  LogSnapshot _snap;
  final List<LogSnapshot> _undo = [];
  final List<LogSnapshot> _redo = [];

  OfficeLogState() : _snap = _seedSnapshot();

  static LogSnapshot _seedSnapshot() {
    return LogSnapshot(
      engineerIds: List.of(kInitialEngineerIds),
      columnIds: List.of(kInitialSubTaskIds),
      cells: {
        for (final entry in seedCells().entries) entry.key: Map.of(entry.value),
      },
      absent: const {},
      budgets: const {},
      comp: const {},
    );
  }

  LogSnapshot get snapshot => _snap;
  List<String> get engineerIds => _snap.engineerIds;
  List<String> get columnIds => _snap.columnIds;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _commit(LogSnapshot next) {
    _undo.add(_snap);
    if (_undo.length > kHistoryCap) _undo.removeAt(0);
    _redo.clear();
    _snap = next;
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_snap);
    _snap = _undo.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_snap);
    _snap = _redo.removeLast();
    notifyListeners();
  }

  void setCell(String engineerId, String columnId, double value) {
    if (value.isNaN || value < 0) return;
    final next = Map<String, Map<String, double>>.from(_snap.cells);
    final row = Map<String, double>.from(next[engineerId] ?? const {});
    if (value == 0) {
      row.remove(columnId);
    } else {
      row[columnId] = value;
    }
    if (row.isEmpty) {
      next.remove(engineerId);
    } else {
      next[engineerId] = row;
    }
    _commit(_snap.copyWith(cells: next));
  }

  void setAbsent(String engineerId, bool absent) {
    final next = Map<String, AbsenceInfo>.from(_snap.absent);
    if (absent) {
      next[engineerId] = AbsenceInfo(
        absent: true,
        reason: next[engineerId]?.reason ?? '',
      );
    } else {
      next.remove(engineerId);
    }
    _commit(_snap.copyWith(absent: next));
  }

  void setBudget(String columnId, double value) {
    if (value.isNaN || value < 0) return;
    final next = Map<String, double>.from(_snap.budgets);
    if (value == 0) {
      next.remove(columnId);
    } else {
      next[columnId] = value;
    }
    _commit(_snap.copyWith(budgets: next));
  }

  void setCompGiven(String engineerId, bool given) {
    final next = Map<String, CompHours>.from(_snap.comp);
    if (given) {
      next[engineerId] = CompHours(
        given: true,
        amount: next[engineerId]?.amount,
      );
    } else {
      next.remove(engineerId);
    }
    _commit(_snap.copyWith(comp: next));
  }

  void setCompAmount(String engineerId, double? amount) {
    if (amount != null && (amount.isNaN || amount < 0)) return;
    final next = Map<String, CompHours>.from(_snap.comp);
    next[engineerId] = CompHours(given: true, amount: amount);
    _commit(_snap.copyWith(comp: next));
  }

  void addEngineer(String engineerId) {
    if (_snap.engineerIds.contains(engineerId)) return;
    final next = List<String>.from(_snap.engineerIds)..add(engineerId);
    _commit(_snap.copyWith(engineerIds: next));
  }

  void removeEngineer(String engineerId) {
    final ids = List<String>.from(_snap.engineerIds)..remove(engineerId);
    final cells = Map<String, Map<String, double>>.from(_snap.cells)
      ..remove(engineerId);
    final absent = Map<String, AbsenceInfo>.from(_snap.absent)
      ..remove(engineerId);
    final comp = Map<String, CompHours>.from(_snap.comp)..remove(engineerId);
    _commit(
      _snap.copyWith(
        engineerIds: ids,
        cells: cells,
        absent: absent,
        comp: comp,
      ),
    );
  }

  void addColumn(String subTaskId) {
    if (_snap.columnIds.contains(subTaskId)) return;
    final next = List<String>.from(_snap.columnIds)..add(subTaskId);
    _commit(_snap.copyWith(columnIds: next));
  }

  void removeColumn(String subTaskId) {
    final ids = List<String>.from(_snap.columnIds)..remove(subTaskId);
    final cells = <String, Map<String, double>>{};
    for (final entry in _snap.cells.entries) {
      final row = Map<String, double>.from(entry.value)..remove(subTaskId);
      if (row.isNotEmpty) cells[entry.key] = row;
    }
    final budgets = Map<String, double>.from(_snap.budgets)..remove(subTaskId);
    _commit(_snap.copyWith(columnIds: ids, cells: cells, budgets: budgets));
  }

  double rowHours(String engineerId) {
    final row = _snap.cells[engineerId];
    if (row == null) return 0;
    double sum = 0;
    for (final id in _snap.columnIds) {
      sum += row[id] ?? 0;
    }
    return sum;
  }

  double rowOt(String engineerId) {
    final h = rowHours(engineerId);
    return h > kDailyRegularHours ? h - kDailyRegularHours : 0;
  }

  double columnTotal(String columnId) {
    double sum = 0;
    for (final id in _snap.engineerIds) {
      if (_snap.absent[id]?.absent == true) continue;
      sum += _snap.cells[id]?[columnId] ?? 0;
    }
    return sum;
  }

  double get grandHours {
    double sum = 0;
    for (final id in _snap.engineerIds) {
      if (_snap.absent[id]?.absent == true) continue;
      sum += rowHours(id);
    }
    return sum;
  }

  double get grandOt {
    double sum = 0;
    for (final id in _snap.engineerIds) {
      if (_snap.absent[id]?.absent == true) continue;
      sum += rowOt(id);
    }
    return sum;
  }

  double get grandComp {
    double sum = 0;
    for (final id in _snap.engineerIds) {
      final c = _snap.comp[id];
      if (c?.given == true && c?.amount != null) sum += c!.amount!;
    }
    return sum;
  }
}
