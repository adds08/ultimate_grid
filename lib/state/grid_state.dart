import 'package:flutter/foundation.dart';
import '../models/grid_models.dart';
import '../data/mock_data.dart';

const double kDailyRegularHours = 8;
const int kHistoryCap = 50;

@immutable
class GridSnapshot {
  final List<String> workerIds;
  final List<String> columnIds;
  final Map<String, Map<String, double>> cells;
  final Map<String, AbsentInfo> absent;
  final Map<String, double> quantities;
  final Map<String, PerDiem> perDiem;

  const GridSnapshot({
    required this.workerIds,
    required this.columnIds,
    required this.cells,
    required this.absent,
    required this.quantities,
    required this.perDiem,
  });

  GridSnapshot copyWith({
    List<String>? workerIds,
    List<String>? columnIds,
    Map<String, Map<String, double>>? cells,
    Map<String, AbsentInfo>? absent,
    Map<String, double>? quantities,
    Map<String, PerDiem>? perDiem,
  }) {
    return GridSnapshot(
      workerIds: workerIds ?? this.workerIds,
      columnIds: columnIds ?? this.columnIds,
      cells: cells ?? this.cells,
      absent: absent ?? this.absent,
      quantities: quantities ?? this.quantities,
      perDiem: perDiem ?? this.perDiem,
    );
  }
}

class GridState extends ChangeNotifier {
  GridSnapshot _snap;
  final List<GridSnapshot> _undo = [];
  final List<GridSnapshot> _redo = [];

  GridState() : _snap = _seedSnapshot();

  static GridSnapshot _seedSnapshot() {
    return GridSnapshot(
      workerIds: List.of(kInitialWorkerIds),
      columnIds: List.of(kInitialCostCodeIds),
      cells: {
        for (final entry in seedCells().entries) entry.key: Map.of(entry.value),
      },
      absent: const {},
      quantities: const {},
      perDiem: const {},
    );
  }

  GridSnapshot get snapshot => _snap;
  List<String> get workerIds => _snap.workerIds;
  List<String> get columnIds => _snap.columnIds;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _commit(GridSnapshot next) {
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

  void setCell(String workerId, String columnId, double value) {
    if (value.isNaN || value < 0) return;
    final next = Map<String, Map<String, double>>.from(_snap.cells);
    final row = Map<String, double>.from(next[workerId] ?? const {});
    if (value == 0) {
      row.remove(columnId);
    } else {
      row[columnId] = value;
    }
    if (row.isEmpty) {
      next.remove(workerId);
    } else {
      next[workerId] = row;
    }
    _commit(_snap.copyWith(cells: next));
  }

  void setAbsent(String workerId, bool absent) {
    final next = Map<String, AbsentInfo>.from(_snap.absent);
    if (absent) {
      next[workerId] = AbsentInfo(absent: true, reason: next[workerId]?.reason ?? '');
    } else {
      next.remove(workerId);
    }
    _commit(_snap.copyWith(absent: next));
  }

  void setQuantity(String columnId, double value) {
    if (value.isNaN || value < 0) return;
    final next = Map<String, double>.from(_snap.quantities);
    if (value == 0) {
      next.remove(columnId);
    } else {
      next[columnId] = value;
    }
    _commit(_snap.copyWith(quantities: next));
  }

  void setPerDiemGiven(String workerId, bool given) {
    final next = Map<String, PerDiem>.from(_snap.perDiem);
    if (given) {
      next[workerId] = PerDiem(given: true, amount: next[workerId]?.amount);
    } else {
      next.remove(workerId);
    }
    _commit(_snap.copyWith(perDiem: next));
  }

  void setPerDiemAmount(String workerId, double? amount) {
    if (amount != null && (amount.isNaN || amount < 0)) return;
    final next = Map<String, PerDiem>.from(_snap.perDiem);
    next[workerId] = PerDiem(given: true, amount: amount);
    _commit(_snap.copyWith(perDiem: next));
  }

  void addWorker(String workerId) {
    if (_snap.workerIds.contains(workerId)) return;
    final next = List<String>.from(_snap.workerIds)..add(workerId);
    _commit(_snap.copyWith(workerIds: next));
  }

  void removeWorker(String workerId) {
    final ids = List<String>.from(_snap.workerIds)..remove(workerId);
    final cells = Map<String, Map<String, double>>.from(_snap.cells)..remove(workerId);
    final absent = Map<String, AbsentInfo>.from(_snap.absent)..remove(workerId);
    final perDiem = Map<String, PerDiem>.from(_snap.perDiem)..remove(workerId);
    _commit(_snap.copyWith(
      workerIds: ids,
      cells: cells,
      absent: absent,
      perDiem: perDiem,
    ));
  }

  void addColumn(String costCodeId) {
    if (_snap.columnIds.contains(costCodeId)) return;
    final next = List<String>.from(_snap.columnIds)..add(costCodeId);
    _commit(_snap.copyWith(columnIds: next));
  }

  void removeColumn(String costCodeId) {
    final ids = List<String>.from(_snap.columnIds)..remove(costCodeId);
    final cells = <String, Map<String, double>>{};
    for (final entry in _snap.cells.entries) {
      final row = Map<String, double>.from(entry.value)..remove(costCodeId);
      if (row.isNotEmpty) cells[entry.key] = row;
    }
    final qty = Map<String, double>.from(_snap.quantities)..remove(costCodeId);
    _commit(_snap.copyWith(columnIds: ids, cells: cells, quantities: qty));
  }

  // ---- computations ----

  double rowHours(String workerId) {
    final row = _snap.cells[workerId];
    if (row == null) return 0;
    double sum = 0;
    for (final id in _snap.columnIds) {
      sum += row[id] ?? 0;
    }
    return sum;
  }

  double rowOt(String workerId) {
    final h = rowHours(workerId);
    return h > kDailyRegularHours ? h - kDailyRegularHours : 0;
  }

  double columnTotal(String columnId) {
    double sum = 0;
    for (final wid in _snap.workerIds) {
      if (_snap.absent[wid]?.absent == true) continue;
      sum += _snap.cells[wid]?[columnId] ?? 0;
    }
    return sum;
  }

  double get grandHours {
    double sum = 0;
    for (final wid in _snap.workerIds) {
      if (_snap.absent[wid]?.absent == true) continue;
      sum += rowHours(wid);
    }
    return sum;
  }

  double get grandOt {
    double sum = 0;
    for (final wid in _snap.workerIds) {
      if (_snap.absent[wid]?.absent == true) continue;
      sum += rowOt(wid);
    }
    return sum;
  }

  double get grandPerDiem {
    double sum = 0;
    for (final wid in _snap.workerIds) {
      final pd = _snap.perDiem[wid];
      if (pd?.given == true && pd?.amount != null) sum += pd!.amount!;
    }
    return sum;
  }
}
