import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/clinic_models.dart';
import '../../domain/models/clinic_data_mock.dart';

class ClinicNetworkScreen extends StatelessWidget {
  const ClinicNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ExperienceMarketplaceShell(
      title: 'Clínicas aliadas',
      subtitle: 'Urgencias, seguros aceptados y admisión coordinada.',
      badge: '${ClinicDataMock.clinics.length} centros',
      icon: Icons.local_hospital_rounded,
      gradient: AppColors.clinicGradient,
      promos: PromoMockData.clinicPromos,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.map_rounded),
        label: const Text('Ver mapa'),
      ),
      children: ClinicDataMock.clinics
          .map((clinic) => _buildClinicCard(context, clinic))
          .toList(),
    );
  }

  Widget _buildClinicCard(BuildContext context, AlliedClinic clinic) {
    return AppMarketplaceTile(
      title: clinic.name,
      subtitle: clinic.location.address,
      imageUrl: clinic.logoUrl,
      icon: Icons.business_rounded,
      color: AppColors.primary,
      actionLabel: 'Coordinar',
      chips: [
        AppStatusPill(
          label: clinic.hasEmergencyRoom
              ? 'Emergencia 24/7'
              : 'Atención regular',
          color: clinic.hasEmergencyRoom ? AppColors.emergency : AppColors.info,
          icon: clinic.hasEmergencyRoom
              ? Icons.emergency_rounded
              : Icons.local_hospital_rounded,
        ),
        AppStatusPill(
          label: '${clinic.acceptedInsurances.length} seguros',
          color: AppColors.secondary,
          icon: Icons.verified_user_rounded,
        ),
      ],
      onTap: () => Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
    );
  }
}
