/// Aşının veya sağlık işleminin durumunu ifade eden enum.
enum VaccineStatus { completed, upcoming, overdue }

/// Evcil hayvan aşı ve tedavi kaydını temsil eden saf iş alanı varlığı (Entity).
class Vaccination {
  final String id;
  final String title;
  final String dueDate;
  final VaccineStatus status;
  final String vetName;
  final String? completionDate;

  const Vaccination({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.vetName,
    this.completionDate,
  });

  Vaccination copyWith({
    String? id,
    String? title,
    String? dueDate,
    VaccineStatus? status,
    String? vetName,
    String? completionDate,
  }) {
    return Vaccination(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      vetName: vetName ?? this.vetName,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate,
      'status': status.name,
      'vetName': vetName,
      'completionDate': completionDate,
    };
  }

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      status: VaccineStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VaccineStatus.upcoming,
      ),
      vetName: map['vetName'] as String? ?? '',
      completionDate: map['completionDate'] as String?,
    );
  }
}
