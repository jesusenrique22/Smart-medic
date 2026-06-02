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
  final String examId;
  final LabWorkOrderStatus status;
  final DateTime createdAt;
  final String? clinicalNotes;
  final String? technicianNotes;
  final String? resultSummary;

  LabWorkOrder({
    required this.id,
    required this.patientName,
    this.patientDocument,
    required this.examId,
    this.status = LabWorkOrderStatus.pending,
    required this.createdAt,
    this.clinicalNotes,
    this.technicianNotes,
    this.resultSummary,
  });

  LabExamDefinition? get exam => LabExamCatalog.findById(examId);

  LabWorkOrder copyWith({
    LabWorkOrderStatus? status,
    String? technicianNotes,
    String? resultSummary,
  }) {
    return LabWorkOrder(
      id: id,
      patientName: patientName,
      patientDocument: patientDocument,
      examId: examId,
      status: status ?? this.status,
      createdAt: createdAt,
      clinicalNotes: clinicalNotes,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      resultSummary: resultSummary ?? this.resultSummary,
    );
  }
}
