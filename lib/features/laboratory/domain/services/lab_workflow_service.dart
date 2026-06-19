import '../models/lab_work_order.dart';

/// Estado local de órdenes de laboratorio (demo / hasta integrar API).
class LabWorkflowService {
  LabWorkflowService._();
  static final LabWorkflowService instance = LabWorkflowService._();

  final List<LabWorkOrder> _orders = [];
  int _seq = 5000;

  List<LabWorkOrder> get orders => List.unmodifiable(_orders);

  List<LabWorkOrder> get pending =>
      _orders.where((o) => o.status == LabWorkOrderStatus.pending).toList();

  List<LabWorkOrder> get inProgress => _orders
      .where((o) => o.status == LabWorkOrderStatus.inProgress)
      .toList();

  List<LabWorkOrder> get completedToday {
    final today = DateTime.now();
    return _orders.where((o) {
      if (o.status != LabWorkOrderStatus.completed) return false;
      return o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day;
    }).toList();
  }

  void seedDemoIfEmpty() {
    if (_orders.isNotEmpty) return;
    _seq = 5001;
    register(
      patientName: 'María López',
      patientDocument: 'V-12.345.678',
      patientPhone: '+58 412-111-2233',
      examId: 'hema-cbc',
      clinicalNotes: 'Control anual',
      isUrgent: true,
    );
    register(
      patientName: 'Carlos Ruiz',
      patientDocument: 'V-98.765.432',
      patientPhone: '+58 414-999-8877',
      examId: 'urine-routine',
    );
    final second = _orders.last;
    updateStatus(second.id, LabWorkOrderStatus.inProgress);
  }

  LabWorkOrder register({
    required String patientName,
    String? patientDocument,
    String? patientPhone,
    required String examId,
    String? clinicalNotes,
    bool isUrgent = false,
  }) {
    final order = LabWorkOrder(
      id: 'LAB-${_seq++}',
      patientName: patientName,
      patientDocument: patientDocument,
      patientPhone: patientPhone,
      examId: examId,
      createdAt: DateTime.now(),
      clinicalNotes: clinicalNotes,
      isUrgent: isUrgent,
    );
    _orders.insert(0, order);
    return order;
  }

  LabWorkOrder? findById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateStatus(String id, LabWorkOrderStatus status) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    _orders[i] = _orders[i].copyWith(status: status);
  }

  void completeOrder({
    required String id,
    required String resultSummary,
    String? technicianNotes,
  }) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    _orders[i] = _orders[i].copyWith(
      status: LabWorkOrderStatus.completed,
      resultSummary: resultSummary,
      technicianNotes: technicianNotes,
    );
  }

  void cancelOrder(String id) {
    updateStatus(id, LabWorkOrderStatus.cancelled);
  }
}
