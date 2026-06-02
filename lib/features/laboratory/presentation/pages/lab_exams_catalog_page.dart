import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/lab_exam_catalog.dart';
import 'lab_register_exam_page.dart';

class LabExamsCatalogPage extends StatefulWidget {
  const LabExamsCatalogPage({super.key, this.initialSampleType});

  final LabSampleType? initialSampleType;

  @override
  State<LabExamsCatalogPage> createState() => _LabExamsCatalogPageState();
}

class _LabExamsCatalogPageState extends State<LabExamsCatalogPage> {
  LabSampleType? _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialSampleType;
  }

  List<LabExamDefinition> get _filtered {
    var list = _filter == null
        ? LabExamCatalog.all
        : LabExamCatalog.bySampleType(_filter!);
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                e.id.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = LabExamCatalog.groupedBySampleType;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catálogo de exámenes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar examen…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Todos', null),
                ...LabSampleType.values.map(
                  (t) => _chip(t.label, t, count: LabExamCatalog.countForType(t)),
                ),
              ],
            ),
          ),
          if (_filter == null && _query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${LabExamCatalog.all.length} exámenes en ${grouped.length} categorías',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final type = grouped.keys.elementAt(index);
                  final exams = grouped[type]!;
                  return _CategorySection(
                    type: type,
                    exams: exams,
                    onSelect: _openRegister,
                    onSeeAll: () => setState(() => _filter = type),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final exam = _filtered[i];
                  return _ExamTile(exam: exam, onTap: () => _openRegister(exam));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, LabSampleType? type, {int? count}) {
    final selected = _filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          count != null ? '$label ($count)' : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        onSelected: (_) => setState(() => _filter = type),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  void _openRegister(LabExamDefinition exam) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LabRegisterExamPage(preselectedExam: exam),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.type,
    required this.exams,
    required this.onSelect,
    required this.onSeeAll,
  });

  final LabSampleType type;
  final List<LabExamDefinition> exams;
  final void Function(LabExamDefinition) onSelect;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final preview = exams.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(type.icon, color: type.color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
          ],
        ),
        ...preview.map(
          (e) => _ExamTile(exam: e, onTap: () => onSelect(e)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam, required this.onTap});

  final LabExamDefinition exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = exam.sampleType;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: type.color.withValues(alpha: 0.12),
          child: Icon(type.icon, color: type.color, size: 22),
        ),
        title: Text(
          exam.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${type.label} · ${exam.turnaround}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
      ),
    );
  }
}
