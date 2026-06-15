import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/laboratory_models.dart';
import '../../domain/models/lab_data_mock.dart';
import 'lab_detail_screen.dart';

class LabMarketplaceScreen extends StatelessWidget {
  const LabMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ExperienceMarketplaceShell(
      title: 'Laboratorios',
      subtitle: 'Reserva exámenes, compara precios y recibe resultados digitales.',
      badge: '${LabDataMock.laboratories.length} aliados',
      icon: Icons.science_rounded,
      gradient: AppColors.labGradient,
      promos: PromoMockData.labPromos,
      children: LabDataMock.laboratories
          .map((lab) => _buildLabCard(context, lab))
          .toList(),
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
