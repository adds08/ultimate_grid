/// One row of the Office Time Log — a single engineer.
class Engineer {
  final String id;
  final String firstName;
  final String lastName;
  final String
  role; // Backend / Frontend / QA / DevOps / Mobile / SRE / Tech Lead
  final String employeeNumber;

  const Engineer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.employeeNumber,
  });

  String get displayName => '$lastName, $firstName';
}

/// One column of the Office Time Log — a sub-task inside a project.
class SubTask {
  final String id;
  final String code;
  final String name;
  final String? projectCode;
  final String? unitOfMeasure;

  const SubTask({
    required this.id,
    required this.code,
    required this.name,
    this.projectCode,
    this.unitOfMeasure,
  });
}

class AbsenceInfo {
  final bool absent;
  final String reason;
  const AbsenceInfo({this.absent = false, this.reason = ''});
  AbsenceInfo copyWith({bool? absent, String? reason}) =>
      AbsenceInfo(absent: absent ?? this.absent, reason: reason ?? this.reason);
}

class CompHours {
  final bool given;
  final double? amount;
  const CompHours({this.given = false, this.amount});
}
