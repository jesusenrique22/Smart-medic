import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/experience_header.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/insurance_models.dart';
import '../../domain/models/insurance_data_mock.dart';
import '../../domain/services/pdf_service.dart';

class InsuranceWalletScreen extends StatelessWidget {
  const InsuranceWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final policies = InsuranceDataMock.activePolicies;

    return ResponsiveScaffold(
      hideAppBar: true,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ExperienceHeader(
              title: 'Mis seguros',
              subtitle: 'Pólizas activas, copagos y actividad reciente.',
              badge: '${policies.length} pólizas',
              icon: Icons.shield_rounded,
              gradient: AppColors.insuranceGradient,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agregar seguro — próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: PromoCarousel(
                offers: PromoMockData.insurancePromos,
                onOfferTap: (_) {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Tus pólizas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.88),
                itemCount: policies.length,
                itemBuilder: (context, index) {
                  return FadeSlideIn(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildPolicyCard(context, policies[index]),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'Actividad reciente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            sliver: SliverToBoxAdapter(child: _buildRecentActivity(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final recentInvoices = [
      MedicalInvoice(
        id: 'INV-8801',
        requestId: 'req-9901',
        patientId: 'pat-123',
        insuranceId: 'ins-001',
        subtotal: 150.0,
        coveredAmount: 150.0,
        copayAmount: 0.0,
        status: InvoiceStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Column(
      children: recentInvoices.asMap().entries.map((entry) {
        final inv = entry.value;
        final insurance = InsuranceDataMock.companies.firstWhere(
          (c) => c.id == inv.insuranceId,
        );
        return FadeSlideIn(
          index: entry.key,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.promo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: AppColors.promo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergencia & traslado',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        insurance.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded,
                      color: AppColors.primary),
                  onPressed: () => PdfService.generateInvoicePdf(
                    invoice: inv,
                    insurance: insurance,
                    patientName: 'Juan Pérez',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPolicyCard(BuildContext context, PatientPolicy policy) {
    final insurance = InsuranceDataMock.companies.firstWhere(
      (c) => c.id == policy.insuranceId,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: insurance.isGlobal
              ? [const Color(0xFF064E3B), const Color(0xFF047857)]
              : [const Color(0xFF0369A1), const Color(0xFF075985)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insurance.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'ACTIVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            policy.policyNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TITULAR: JUAN PÉREZ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
