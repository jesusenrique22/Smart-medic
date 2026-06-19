class MedicalEquipment {
  final String id;
  final String facilityId;
  final String name;
  final String? description;
  final double pricePerDay;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final String facilityName;
  final String? facilityAddress;

  const MedicalEquipment({
    required this.id,
    required this.facilityId,
    required this.name,
    this.description,
    required this.pricePerDay,
    required this.stock,
    this.imageUrl,
    required this.isActive,
    required this.facilityName,
    this.facilityAddress,
  });

  factory MedicalEquipment.fromJson(Map<String, dynamic> json) {
    final facility = json['facility'] as Map<String, dynamic>?;
    return MedicalEquipment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      facilityId: json['facilityId']?.toString() ?? json['facility_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      facilityName: facility?['name'] as String? ?? 'Clínica Asociada',
      facilityAddress: facility?['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facilityId': facilityId,
      'name': name,
      'description': description,
      'pricePerDay': pricePerDay,
      'stock': stock,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}

class EquipmentRental {
  final String id;
  final String patientId;
  final String equipmentId;
  final String facilityId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final String address;
  final String phone;
  final DateTime createdAt;
  final MedicalEquipment? equipment;
  final String facilityName;
  final String? patientName;
  final String? patientEmail;

  const EquipmentRental({
    required this.id,
    required this.patientId,
    required this.equipmentId,
    required this.facilityId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.address,
    required this.phone,
    required this.createdAt,
    this.equipment,
    required this.facilityName,
    this.patientName,
    this.patientEmail,
  });

  factory EquipmentRental.fromJson(Map<String, dynamic> json) {
    final eqData = json['equipment'] as Map<String, dynamic>?;
    final facData = json['facility'] as Map<String, dynamic>?;
    final patData = json['patient'] as Map<String, dynamic>?;

    return EquipmentRental(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
      equipmentId: json['equipmentId']?.toString() ?? json['equipment_id']?.toString() ?? '',
      facilityId: json['facilityId']?.toString() ?? json['facility_id']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.parse(json['start_date'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.parse(json['end_date'] as String),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['created_at'] as String),
      equipment: eqData != null ? MedicalEquipment.fromJson(eqData) : null,
      facilityName: facData?['name'] as String? ?? 'Clínica Asociada',
      patientName: patData?['name'] as String?,
      patientEmail: patData?['email'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'ACTIVE':
        return 'Entregado (Activo)';
      case 'COMPLETED':
        return 'Devuelto (Completado)';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
