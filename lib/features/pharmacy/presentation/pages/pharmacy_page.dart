// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_header.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/pharmacy_data_mock.dart';
import '../../domain/models/pharmacy.dart';
import '../../domain/models/optimized_cart_result.dart';
import '../../domain/services/global_search_optimization_service.dart';
import '../../domain/services/prescription_scanner_service.dart';
import 'pharmacy_detail_screen.dart';

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  final List<Pharmacy> _pharmacies = PharmacyDataMock.pharmacies;
  final GlobalSearchOptimizationService _optimizationService =
      GlobalSearchOptimizationService();
  final PrescriptionScannerService _scannerService =
      PrescriptionScannerService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _globalSearchController = TextEditingController();
  OptimizedCartResult? _bestDeal;
  bool _isProcessing = false;
  String _deliveryType = 'pickup'; // 'pickup' o 'delivery'
  final double _deliveryFee = 3.50;

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  Future<void> _scanPrescription() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final List<String> detectedMeds = await _scannerService
          .processPrescription(File(image.path));
      if (detectedMeds.isNotEmpty) {
        final result = _optimizationService.findBestPharmacyCart(detectedMeds);
        setState(() {
          _bestDeal = result;
          _isProcessing = false;
        });
        if (result == null) {
          _showError(
            'Ninguna farmacia tiene todos los medicamentos de tu receta.',
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideAppBar: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ExperienceHeader(
                  title: 'Farmacia',
                  subtitle: 'Busca medicinas, escanea recetas y compara precios.',
                  badge: '${_pharmacies.length} aliadas',
                  icon: Icons.local_pharmacy_rounded,
                  gradient: AppColors.pharmacyGradient,
                  actions: [
                    IconButton(
                      onPressed: () => AppNavigation.safeBack(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: PromoCarousel(
                    offers: PromoMockData.pharmacyPromos,
                    onOfferTap: (_) {},
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildSearchHeader()),
              if (_bestDeal != null)
                SliverFillRemaining(child: _buildBestDealCard())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pharmacy = _pharmacies[index];
                        return FadeSlideIn(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildPharmacyCard(pharmacy),
                          ),
                        );
                      },
                      childCount: _pharmacies.length,
                    ),
                  ),
                ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analizando receta…',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanPrescription,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Escanear receta'),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscador inteligente',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _globalSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar medicina…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _bestDeal = _optimizationService.findBestPharmacyCart(
                            [value],
                          );
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDealCard() {
    final result = _bestDeal!;
    final double finalTotal = _deliveryType == 'delivery'
        ? result.total + _deliveryFee
        : result.total;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Mejor Precio Encontrado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Hemos optimizado tu carrito globalmente.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Farmacia Seleccionada'),
            const SizedBox(height: 12),
            _buildPharmacyCard(result.pharmacy, isWinner: true),
            const SizedBox(height: 24),
            _buildSectionHeader('Logística de Entrega'),
            const SizedBox(height: 12),
            _buildLogisticsSelector(),
            const SizedBox(height: 24),
            _buildSectionHeader('Resumen de Pago'),
            const SizedBox(height: 12),
            _buildCheckoutSummary(result, finalTotal),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() => _bestDeal = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pedido confirmado con éxito')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirmar Compra Optimizada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _bestDeal = null),
                child: const Text(
                  'Cancelar y volver al directorio',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text(
            'Pick-up en Farmacia',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Retira tú mismo sin costo de envío',
            style: TextStyle(fontSize: 12),
          ),
          value: 'pickup',
          groupValue: _deliveryType,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _deliveryType = value!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
        ),
        const SizedBox(height: 12),
        RadioListTile<String>(
          title: const Text(
            'Delivery a Domicilio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Llega en 30-45 min (+\$${_deliveryFee.toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 12),
          ),
          value: 'delivery',
          groupValue: _deliveryType,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _deliveryType = value!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildCheckoutSummary(OptimizedCartResult result, double finalTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('\$${result.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (12%)'),
              Text('\$${result.tax.toStringAsFixed(2)}'),
            ],
          ),
          if (_deliveryType == 'delivery') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Envío'),
                Text(
                  '\$${_deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Final',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, {bool isWinner = false}) {
    return AppMarketplaceTile(
      title: pharmacy.name,
      subtitle: pharmacy.address.isEmpty
          ? 'Farmacia aliada con inventario conectado.'
          : pharmacy.address,
      imageUrl: pharmacy.logoUrl,
      icon: Icons.local_pharmacy_rounded,
      color: isWinner ? AppColors.secondary : AppColors.primary,
      actionLabel: isWinner ? 'Seleccionada' : 'Comprar',
      chips: [
        AppStatusPill(
          label: pharmacy.isActive ? 'Disponible' : 'No disponible',
          color: pharmacy.isActive
              ? AppColors.secondary
              : AppColors.textTertiary,
          icon: pharmacy.isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_rounded,
        ),
      ],
      onTap: isWinner
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
              ),
            ),
    );
  }
}
