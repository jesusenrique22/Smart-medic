import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../domain/models/lab_exam_catalog.dart';
import '../../domain/models/lab_work_order.dart';
import '../../domain/services/lab_workflow_service.dart';
import 'lab_exams_catalog_page.dart';
import 'lab_process_exam_page.dart';
import 'lab_register_exam_page.dart';

class LabTechnicianDashboard extends StatefulWidget {
  const LabTechnicianDashboard({super.key});

  @override
  State<LabTechnicianDashboard> createState() => _LabTechnicianDashboardState();
}

class _LabTechnicianDashboardState extends State<LabTechnicianDashboard> {
  final _workflow = LabWorkflowService.instance;

  @override
  void initState() {
    super.initState();
    _workflow.seedDemoIfEmpty();
  }

  void _refresh() => setState(() {});

  Future<void> _openOrder(LabWorkOrder order) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => LabProcessExamPage(orderId: order.id),
      ),
    );
    if (updated == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _workflow.pending;
    final inProgress = _workflow.inProgress;
    final completedToday = _workflow.completedToday;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laboratorio clínico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              AppSession.clear();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const LabRegisterExamPage(),
            ),
          );
          _refresh();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo examen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsRow(
              pending: pending.length,
              inProgress: inProgress.length,
              completed: completedToday.length,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Realizar exámenes por muestra'),
            const SizedBox(height: 12),
            _buildSampleTypeGrid(),
            const SizedBox(height: 28),
            Row(
              children: [
                _buildSectionTitle('Órdenes activas'),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LabExamsCatalogPage(),
                      ),
                    );
                  },
                  child: const Text('Catálogo completo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty && inProgress.isEmpty)
              _emptyOrdersHint()
            else ...[
              ...inProgress.map((o) => _orderCard(o, highlight: true)),
              ...pending.map((o) => _orderCard(o)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final name = AppSession.currentUser?.name ?? 'Técnico de laboratorio';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de laboratorio',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hola, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${LabExamCatalog.all.length} tipos de examen · sangre, orina, heces y más',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.biotech_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required int pending,
    required int inProgress,
    required int completed,
  }) {
    return Row(
      children: [
        _stat('Pendientes', '$pending', Colors.orange),
        const SizedBox(width: 10),
        _stat('En proceso', '$inProgress', Colors.blue),
        const SizedBox(width: 10),
        _stat('Hoy', '$completed', Colors.green),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSampleTypeGrid() {
    final types = LabSampleType.values
        .where((t) => LabExamCatalog.countForType(t) > 0)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: types.length,
      itemBuilder: (context, i) {
        final type = types[i];
        final count = LabExamCatalog.countForType(type);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openCategory(type),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: type.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: type.color.withValues(alpha: 0.12),
                    child: Icon(type.icon, color: type.color),
                  ),
                  const Spacer(),
                  Text(
                    type.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$count exámenes',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCategory(LabSampleType type) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LabExamsCatalogPage(initialSampleType: type),
      ),
    ).then((_) => _refresh());
  }

  Widget _orderCard(LabWorkOrder order, {bool highlight = false}) {
    final exam = order.exam;
    final type = exam?.sampleType;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight
            ? BorderSide(color: Colors.blue.shade200, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => _openOrder(order),
        leading: CircleAvatar(
          backgroundColor: (type?.color ?? AppColors.primary)
              .withValues(alpha: 0.12),
          child: Icon(
            type?.icon ?? Icons.science_rounded,
            color: type?.color ?? AppColors.primary,
          ),
        ),
        title: Text(
          order.patientName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${exam?.name ?? order.examId} · ${order.status.label}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _emptyOrdersHint() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No hay órdenes pendientes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra un examen o elige una categoría arriba',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
