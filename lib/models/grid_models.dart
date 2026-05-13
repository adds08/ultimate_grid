class Worker {
  final String id;
  final String firstName;
  final String lastName;
  final String classification;
  final String employeeNumber;

  const Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.classification,
    required this.employeeNumber,
  });

  String get displayName => '$lastName, $firstName';
}

class CostCode {
  final String id;
  final String code;
  final String name;
  final String? phaseCode;
  final String? unitOfMeasure;

  const CostCode({
    required this.id,
    required this.code,
    required this.name,
    this.phaseCode,
    this.unitOfMeasure,
  });
}

class AbsentInfo {
  final bool absent;
  final String reason;
  const AbsentInfo({this.absent = false, this.reason = ''});
  AbsentInfo copyWith({bool? absent, String? reason}) =>
      AbsentInfo(absent: absent ?? this.absent, reason: reason ?? this.reason);
}

class PerDiem {
  final bool given;
  final double? amount;
  const PerDiem({this.given = false, this.amount});
}
