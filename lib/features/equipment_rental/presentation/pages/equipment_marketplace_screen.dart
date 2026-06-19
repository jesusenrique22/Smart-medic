import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../data/equipment_api_service.dart';
import '../../domain/models/equipment_model.dart';
import 'equipment_detail_screen.dart';

class EquipmentMarketplaceScreen extends StatefulWidget {
  const EquipmentMarketplaceScreen({super.key});

  @override
  State<EquipmentMarketplaceScreen> createState() => _EquipmentMarketplaceScreenState();
}

class _EquipmentMarketplaceScreenState extends State<EquipmentMarketplaceScreen> {
  final _apiService = EquipmentApiService();
  List<MedicalEquipment> _allEquipment = [];
  List<MedicalEquipment> _filteredEquipment = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedClinic;
  List<String> _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _loading = true);
    try {
      final list = await _apiService.getAllEquipment();
      if (!mounted) return;

      // Extraer clínicas únicas para el filtro
      final clinicsSet = list.map((e) => e.facilityName).toSet().toList()..sort();

      setState(() {
        _allEquipment = list;
        _clinics = clinicsSet;
        _loading = false;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allEquipment = [];
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEquipment = _allEquipment.where((eq) {
        final matchesSearch = eq.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (eq.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesClinic = _selectedClinic == null || eq.facilityName == _selectedClinic;
        return matchesSearch && matchesClinic;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ExperienceMarketplaceShell(
      title: 'Alquiler de Equipos',
      subtitle: 'Sillas de ruedas, tanques de oxígeno, camas clínicas y más para tu recuperación.',
      badge: '${_filteredEquipment.length} disponibles',
      icon: Icons.personal_injury_rounded,
      gradient: AppColors.pharmacyGradient,
      promos: PromoMockData.pharmacyPromos, // Reutilizamos promos de farmacia que lucen geniales
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.myRentals),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
        label: const Text(
          'Mis Alquileres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      children: [
        // Buscador y filtros
        _buildSearchAndFilters(),
        const SizedBox(height: 16),
        // Listado de equipos
        if (_filteredEquipment.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                'No se encontraron equipos médicos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          )
        else
          ..._filteredEquipment.map((eq) => _buildEquipmentTile(eq)),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBar(
          hintText: 'Buscar silla, muleta, nebulizador...',
          leading: const Icon(Icons.search_rounded),
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          side: WidgetStateProperty.all(const BorderSide(color: AppColors.border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (val) {
            _searchQuery = val;
            _applyFilters();
          },
        ),
        const SizedBox(height: 12),
        // Filtro de clínicas horizontal
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: const Text('Todas las Clínicas'),
                  selected: _selectedClinic == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedClinic = null;
                        _applyFilters();
                      });
                    }
                  },
                  selectedColor: AppColors.secondaryLight,
                  checkmarkColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: _selectedClinic == null ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: _selectedClinic == null ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
              ..._clinics.map((clinic) {
                final isSelected = _selectedClinic == clinic;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(clinic),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedClinic = selected ? clinic : null;
                        _applyFilters();
                      });
                    },
                    selectedColor: AppColors.secondaryLight,
                    checkmarkColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentTile(MedicalEquipment eq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppMarketplaceTile(
        title: eq.name,
        subtitle: eq.description ?? 'Sin descripción disponible.',
        imageUrl: eq.imageUrl,
        icon: Icons.personal_injury_rounded,
        color: AppColors.secondary,
        actionLabel: 'Ver detalle',
        chips: [
          AppStatusPill(
            label: '\$${eq.pricePerDay.toStringAsFixed(2)} / día',
            color: AppColors.primary,
            icon: Icons.monetization_on_outlined,
          ),
          AppStatusPill(
            label: eq.facilityName,
            color: AppColors.info,
            icon: Icons.local_hospital_outlined,
          ),
          AppStatusPill(
            label: 'Stock: ${eq.stock}',
            color: AppColors.secondary,
            icon: Icons.inventory_2_outlined,
          ),
        ],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(equipment: eq),
            ),
          ).then((_) => _loadEquipment()); // Recargar stock al volver
        },
      ),
    );
  }
}
