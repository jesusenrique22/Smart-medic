import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/laboratory_models.dart';
import '../../domain/models/lab_data_mock.dart';
import '../../data/services/lab_api_service.dart';
import 'lab_detail_screen.dart';

class LabMarketplaceScreen extends StatefulWidget {
  const LabMarketplaceScreen({super.key});

  @override
  State<LabMarketplaceScreen> createState() => _LabMarketplaceScreenState();
}

class _LabMarketplaceScreenState extends State<LabMarketplaceScreen> {
  final _api = LabApiService();
  List<Laboratory> _laboratories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLaboratories();
  }

  Future<void> _loadLaboratories() async {
    setState(() {
      _loading = true;
    });
    try {
      final labs = await _api.getLaboratories();
      setState(() {
        _laboratories = labs;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _laboratories = LabDataMock.laboratories;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLaboratories,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ExperienceMarketplaceShell(
                title: 'Laboratorios',
                subtitle: 'Reserva exámenes, compara precios y recibe resultados digitales.',
                badge: '${_laboratories.length} aliados',
                icon: Icons.science_rounded,
                gradient: AppColors.labGradient,
                promos: PromoMockData.labPromos,
                children: _laboratories
                    .map((lab) => _buildLabCard(context, lab))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildLabCard(BuildContext context, Laboratory lab) {
    return AppMarketplaceTile(
      title: lab.name,
      subtitle: lab.offersHomeService
          ? 'Toma de muestras a domicilio y atención en sede.'
          : 'Atención en sede con resultados digitales.',
      imageUrl: lab.logoUrl,
      icon: Icons.science_rounded,
      color: AppColors.info,
      chips: [
        AppStatusPill(
          label: lab.offersHomeService ? 'Domicilio' : 'En sede',
          color: lab.offersHomeService ? AppColors.secondary : AppColors.info,
          icon: lab.offersHomeService
              ? Icons.home_work_rounded
              : Icons.location_city_rounded,
        ),
      ],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LabDetailScreen(laboratory: lab)),
      ),
    );
  }
}
