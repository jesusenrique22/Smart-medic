import 'lab_exam_catalog.dart';

enum LabWorkOrderStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

extension LabWorkOrderStatusX on LabWorkOrderStatus {
  String get label {
    switch (this) {
      case LabWorkOrderStatus.pending:
        return 'Pendiente';
      case LabWorkOrderStatus.inProgress:
        return 'En proceso';
      case LabWorkOrderStatus.completed:
        return 'Completado';
      case LabWorkOrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// Orden de trabajo de laboratorio (muestra + examen).
class LabWorkOrder {
  final String id;
  final String patientName;
  final String? patientDocument;
  final String? patientPhone;
  final String examId;
  final LabWorkOrderStatus status;
  final DateTime createdAt;
  final String? clinicalNotes;
  final String? technicianNotes;
  final String? resultSummary;
  final bool isUrgent;

  LabWorkOrder({
    required this.id,
    required this.patientName,
    this.patientDocument,
    this.patientPhone,
    required this.examId,
    this.status = LabWorkOrderStatus.pending,
    required this.createdAt,
    this.clinicalNotes,
    this.technicianNotes,
    this.resultSummary,
    this.isUrgent = false,
  });

  LabExamDefinition? get exam => LabExamCatalog.findById(examId);

  LabWorkOrder copyWith({
    LabWorkOrderStatus? status,
    String? technicianNotes,
    String? resultSummary,
    bool? isUrgent,
  }) {
    return LabWorkOrder(
      id: id,
      patientName: patientName,
      patientDocument: patientDocument,
      patientPhone: patientPhone,
      examId: examId,
      status: status ?? this.status,
      createdAt: createdAt,
      clinicalNotes: clinicalNotes,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      resultSummary: resultSummary ?? this.resultSummary,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}
