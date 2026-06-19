import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/lab_exam_catalog.dart';
import '../../domain/services/lab_workflow_service.dart';
import 'lab_process_exam_page.dart';

class LabRegisterExamPage extends StatefulWidget {
  const LabRegisterExamPage({
    super.key,
    this.preselectedExam,
    this.initialSampleType,
  });

  final LabExamDefinition? preselectedExam;
  final LabSampleType? initialSampleType;

  @override
  State<LabRegisterExamPage> createState() => _LabRegisterExamPageState();
}

class _LabRegisterExamPageState extends State<LabRegisterExamPage> {
  final _nameController = TextEditingController();
  final _docController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  LabExamDefinition? _selected;
  LabSampleType? _categoryFilter;
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselectedExam;
    _categoryFilter = widget.initialSampleType ?? widget.preselectedExam?.sampleType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _docController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<LabExamDefinition> get _examOptions {
    if (_categoryFilter != null) {
      return LabExamCatalog.bySampleType(_categoryFilter!);
    }
    return LabExamCatalog.all;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Ingresa el nombre del paciente');
      return;
    }
    if (_selected == null) {
      _snack('Selecciona un tipo de examen');
      return;
    }

    final order = LabWorkflowService.instance.register(
      patientName: name,
      patientDocument: _docController.text.trim().isEmpty
          ? null
          : _docController.text.trim(),
      patientPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      examId: _selected!.id,
      clinicalNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isUrgent: _isUrgent,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Orden ${order.id} registrada'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LabProcessExamPage(orderId: order.id),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Registrar examen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Datos del paciente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _docController,
              decoration: const InputDecoration(
                labelText: 'Documento / cédula',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono del paciente',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Indicación clínica (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tipo de examen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LabSampleType?>(
              key: ValueKey(_categoryFilter),
              initialValue: _categoryFilter,
              decoration: const InputDecoration(
                labelText: 'Categoría de muestra',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...LabSampleType.values.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                ),
              ],
              onChanged: (v) => setState(() {
                _categoryFilter = v;
                if (_selected != null &&
                    v != null &&
                    _selected!.sampleType != v) {
                  _selected = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LabExamDefinition>(
              key: ValueKey('${selected?.id}_$_categoryFilter'),
              initialValue: selected != null &&
                      _examOptions.any((e) => e.id == selected.id)
                  ? selected
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Examen *',
              ),
              items: _examOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
            if (selected != null) ...[
              const SizedBox(height: 16),
              _PreparationCard(exam: selected),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(
                'Marcar como prioridad urgente (STAT)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              subtitle: const Text(
                'Destaca esta orden en el panel para procesamiento prioritario',
                style: TextStyle(fontSize: 12),
              ),
              value: _isUrgent,
              activeColor: Colors.red.shade700,
              onChanged: (val) => setState(() => _isUrgent = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Crear orden de laboratorio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparationCard extends StatelessWidget {
  const _PreparationCard({required this.exam});

  final LabExamDefinition exam;

  @override
  Widget build(BuildContext context) {
    final type = exam.sampleType;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: type.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, color: type.color, size: 20),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: type.color,
                ),
              ),
              const Spacer(),
              Text(
                exam.turnaround,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Preparación del paciente',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            exam.preparation,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          if (exam.referencePrice > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Referencia: \$${exam.referencePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
