import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/radiology_models.dart';
import '../../domain/models/radiology_data_mock.dart';
import 'radiology_detail_screen.dart';

class RadiologyMarketplaceScreen extends StatelessWidget {
  const RadiologyMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ExperienceMarketplaceShell(
      title: 'Radiología',
      subtitle: 'Rayos X, ecos, resonancias y estudios especializados.',
      badge: '${RadiologyDataMock.centers.length} centros',
      icon: Icons.image_search_rounded,
      gradient: AppColors.radiologyGradient,
      promos: PromoMockData.radiologyPromos,
      children: RadiologyDataMock.centers
          .map((center) => _buildCenterCard(context, center))
          .toList(),
    );
  }

  Widget _buildCenterCard(BuildContext context, RadiologyCenter center) {
    return AppMarketplaceTile(
      title: center.name,
      subtitle: center.hasMRI
          ? 'Estudios avanzados con resonancia magnética y diagnóstico digital.'
          : 'Rayos X, ecos y estudios de imagen ambulatorios.',
      imageUrl: center.logoUrl,
      icon: Icons.image_search_rounded,
      color: AppColors.secondary,
      chips: [
        AppStatusPill(
          label: center.hasMRI ? 'MRI disponible' : 'Rayos X / Ecos',
          color: center.hasMRI ? AppColors.accent : AppColors.info,
          icon: center.hasMRI
              ? Icons.monitor_heart_rounded
              : Icons.medical_information_rounded,
        ),
      ],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RadiologyDetailScreen(center: center),
        ),
      ),
    );
  }
}
