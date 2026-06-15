import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/experience_header.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class _ServiceCategory {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String description;

  const _ServiceCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    required this.description,
  });
}

const _allCategories = [
  _ServiceCategory(
    label: 'Agendar cita',
    icon: Icons.calendar_month_rounded,
    color: AppColors.primary,
    route: AppRoutes.schedule,
    description: 'Consulta presencial o por video',
  ),
  _ServiceCategory(
    label: 'Mis citas',
    icon: Icons.event_note_rounded,
    color: AppColors.info,
    route: AppRoutes.appointments,
    description: 'Agenda y llamadas pendientes',
  ),
  _ServiceCategory(
    label: 'Laboratorios',
    icon: Icons.science_rounded,
    color: AppColors.secondary,
    route: AppRoutes.labMarketplace,
    description: 'Pruebas, paquetes y promos',
  ),
  _ServiceCategory(
    label: 'Resultados',
    icon: Icons.assignment_turned_in_rounded,
    color: AppColors.info,
    route: AppRoutes.labResults,
    description: 'Consulta y descarga estudios',
  ),
  _ServiceCategory(
    label: 'Farmacia',
    icon: Icons.local_pharmacy_rounded,
    color: AppColors.promo,
    route: AppRoutes.pharmacy,
    description: 'Medicamentos y delivery',
  ),
  _ServiceCategory(
    label: 'Radiología',
    icon: Icons.image_search_rounded,
    color: AppColors.accent,
    route: AppRoutes.radiologyMarketplace,
    description: 'Rayos X, ecos y resonancia',
  ),
  _ServiceCategory(
    label: 'Clínicas',
    icon: Icons.business_rounded,
    color: AppColors.primaryDark,
    route: AppRoutes.clinicNetwork,
    description: 'Red aliada y cobertura',
  ),
  _ServiceCategory(
    label: 'Seguro',
    icon: Icons.shield_rounded,
    color: AppColors.warning,
    route: AppRoutes.insuranceWallet,
    description: 'Pólizas y copagos',
  ),
  _ServiceCategory(
    label: 'Exámenes',
    icon: Icons.upload_file_rounded,
    color: AppColors.primary,
    route: AppRoutes.patientShareExams,
    description: 'Comparte con tu médico',
  ),
  _ServiceCategory(
    label: 'Historial',
    icon: Icons.history_edu_rounded,
    color: AppColors.secondary,
    route: AppRoutes.medicalHistory,
    description: 'Visitas, antecedentes y recetas',
  ),
];

class HealthServicesHubPage extends StatefulWidget {
  const HealthServicesHubPage({super.key});

  @override
  State<HealthServicesHubPage> createState() => _HealthServicesHubPageState();
}

class _HealthServicesHubPageState extends State<HealthServicesHubPage> {
  String _query = '';

  List<_ServiceCategory> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allCategories;
    return _allCategories
        .where(
          (c) =>
              c.label.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final w = MediaQuery.sizeOf(context).width;
    final crossAxisCount = w >= 900 ? 3 : 2;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ExperienceHeader(
            title: 'Tu salud',
            subtitle: 'Citas, laboratorios, farmacia y más — sin complicaciones.',
            badge: '${_allCategories.length} servicios',
            icon: Icons.health_and_safety_rounded,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: PromoCarousel(
              offers: PromoMockData.offers,
              onOfferTap: (offer) {
                if (offer.route != null) {
                  Navigator.pushNamed(context, offer.route!);
                }
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SearchBar(
              hintText: 'Buscar servicio…',
              leading: const Icon(Icons.search_rounded),
              onChanged: (value) => setState(() => _query = value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(AppColors.surface),
              side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.border),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No encontramos ese servicio',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              80,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 120,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => FadeSlideIn(
                  index: index,
                  child: _ServiceCard(
                    category: filtered[index],
                    onTap: () =>
                        Navigator.pushNamed(context, filtered[index].route),
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceCategory category;
  final VoidCallback onTap;

  const _ServiceCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: category.color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthServicesHub extends StatelessWidget {
  const HealthServicesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScaffold(
      hideAppBar: true,
      child: HealthServicesHubPage(),
    );
  }
}
