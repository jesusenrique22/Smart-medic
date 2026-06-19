import '../../../core/network/api_client.dart';
import '../domain/models/equipment_model.dart';

class EquipmentApiService {
  final ApiClient _client = ApiClient.instance;

  // ==========================================
  // PACIENTE
  // ==========================================

  Future<List<MedicalEquipment>> getAllEquipment() async {
    final response = await _client.get('/api/equipment', auth: true);
    if (response is List) {
      return response
          .map((e) => MedicalEquipment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<EquipmentRental> rentEquipment({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    required String address,
    required String phone,
  }) async {
    final response = await _client.post(
      '/api/equipment/rent',
      {
        'equipmentId': equipmentId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'address': address.trim(),
        'phone': phone.trim(),
      },
      auth: true,
    );
    return EquipmentRental.fromJson(response);
  }

  Future<List<EquipmentRental>> getPatientRentals() async {
    final response = await _client.get('/api/equipment/my-rentals', auth: true);
    if (response is List) {
      return response
          .map((e) => EquipmentRental.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  // ==========================================
  // CLÍNICA ADMIN
  // ==========================================

  Future<List<MedicalEquipment>> getClinicEquipment() async {
    final response = await _client.get('/api/equipment/clinic', auth: true);
    if (response is List) {
      return response
          .map((e) => MedicalEquipment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<MedicalEquipment> addClinicEquipment({
    required String name,
    required String description,
    required double pricePerDay,
    required int stock,
    String? imageUrl,
  }) async {
    final response = await _client.post(
      '/api/equipment/clinic',
      {
        'name': name.trim(),
        'description': description.trim(),
        'pricePerDay': pricePerDay,
        'stock': stock,
        if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
      },
      auth: true,
    );
    return MedicalEquipment.fromJson(response);
  }

  Future<MedicalEquipment> updateClinicEquipment(
    String id, {
    String? name,
    String? description,
    double? pricePerDay,
    int? stock,
    String? imageUrl,
    bool? isActive,
  }) async {
    final response = await _client.put(
      '/api/equipment/clinic/$id',
      {
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (pricePerDay != null) 'pricePerDay': pricePerDay,
        if (stock != null) 'stock': stock,
        if (imageUrl != null) 'imageUrl': imageUrl.trim(),
        if (isActive != null) 'isActive': isActive,
      },
      auth: true,
    );
    return MedicalEquipment.fromJson(response);
  }

  Future<void> deleteClinicEquipment(String id) async {
    await _client.delete('/api/equipment/clinic/$id', auth: true);
  }

  Future<List<EquipmentRental>> getClinicRentals() async {
    final response = await _client.get('/api/equipment/clinic/rentals', auth: true);
    if (response is List) {
      return response
          .map((e) => EquipmentRental.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<EquipmentRental> updateRentalStatus(String rentalId, String status) async {
    final response = await _client.patch(
      '/api/equipment/clinic/rentals/$rentalId/status',
      {'status': status},
      auth: true,
    );
    return EquipmentRental.fromJson(response);
  }
}
