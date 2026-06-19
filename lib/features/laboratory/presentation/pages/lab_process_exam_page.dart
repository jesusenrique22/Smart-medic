import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/lab_exam_catalog.dart';
import '../../domain/models/lab_work_order.dart';
import '../../domain/services/lab_workflow_service.dart';

class LabProcessExamPage extends StatefulWidget {
  const LabProcessExamPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<LabProcessExamPage> createState() => _LabProcessExamPageState();
}

class _LabProcessExamPageState extends State<LabProcessExamPage> {
  final _resultController = TextEditingController();
  final _notesController = TextEditingController();

  LabWorkOrder? get _order => LabWorkflowService.instance.findById(widget.orderId);

  @override
  void dispose() {
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setStatus(LabWorkOrderStatus status) {
    LabWorkflowService.instance.updateStatus(widget.orderId, status);
    setState(() {});
  }

  void _complete() {
    final summary = _resultController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un resumen de resultados')),
      );
      return;
    }
    LabWorkflowService.instance.completeOrder(
      id: widget.orderId,
      resultSummary: summary,
      technicianNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resultado publicado'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Orden no encontrada')),
      );
    }

    final exam = order.exam;
    final type = exam?.sampleType;
    final isDone = order.status == LabWorkOrderStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Orden ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBanner(status: order.status),
            const SizedBox(height: 16),
            if (order.isUrgent) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ATENCIÓN: Prioridad Urgente (STAT) requerida.',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.patientDocument != null)
                      Text(
                        'Cédula/Documento: ${order.patientDocument!}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (order.patientPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            order.patientPhone!,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    if (exam != null) ...[
                      Row(
                        children: [
                          if (type != null)
                            Icon(type.icon, color: type.color, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exam.preparation,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (order.clinicalNotes != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Indicación: ${order.clinicalNotes}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!isDone) ...[
              const SizedBox(height: 24),
              const Text(
                'Flujo de trabajo',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (order.status == LabWorkOrderStatus.pending)
                    FilledButton.icon(
                      onPressed: () => _setStatus(LabWorkOrderStatus.inProgress),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Iniciar procesamiento'),
                    ),
                  if (order.status == LabWorkOrderStatus.inProgress) ...[
                    OutlinedButton(
                      onPressed: () => _setStatus(LabWorkOrderStatus.pending),
                      child: const Text('Volver a pendiente'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Resultados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (exam != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preparación/Referencia: ${exam.preparation}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _resultController,
                maxLines: 4,
                enabled: order.status != LabWorkOrderStatus.pending,
                decoration: InputDecoration(
                  hintText: order.status == LabWorkOrderStatus.pending
                      ? 'Inicia el procesamiento para cargar resultados'
                      : 'Valores, interpretación, hallazgos…',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                enabled: order.status != LabWorkOrderStatus.pending,
                decoration: const InputDecoration(
                  labelText: 'Notas del técnico (opcional)',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjuntar PDF / imagen del informe',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: order.status == LabWorkOrderStatus.inProgress
                    ? _complete
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.green.shade700,
                ),
                child: const Text('Publicar resultado'),
              ),
              TextButton(
                onPressed: () {
                  LabWorkflowService.instance.cancelOrder(widget.orderId);
                  Navigator.pop(context, true);
                },
                child: const Text('Cancelar orden', style: TextStyle(color: Colors.red)),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resultado publicado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(order.resultSummary ?? '—'),
                      if (order.technicianNotes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notas: ${order.technicianNotes}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final LabWorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case LabWorkOrderStatus.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        icon = Icons.hourglass_top_rounded;
      case LabWorkOrderStatus.inProgress:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.biotech_rounded;
      case LabWorkOrderStatus.completed:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
      case LabWorkOrderStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.cancel_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Text(
            status.label,
            style: TextStyle(fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
