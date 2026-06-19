enum LabResultStatus { pending, delivered }

class Laboratory {
  final String id;
  final String name;
  final String logoUrl;
  final bool offersHomeService;
  final List<LabService> services;

  Laboratory({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.offersHomeService,
    this.services = const [],
  });

  factory Laboratory.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'] as List? ?? [];
    return Laboratory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? 'https://images.unsplash.com/photo-1532187643603-ba119ca4109e?auto=format&fit=crop&q=80&w=600',
      offersHomeService: json['offersHomeService'] as bool? ?? true,
      services: rawServices.map((s) => LabService.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class LabService {
  final String id;
  final String laboratoryId;
  final String name;
  final double price;
  final String requirements; // Ej: 'Ayunas de 8 horas'

  LabService({
    required this.id,
    required this.laboratoryId,
    required this.name,
    required this.price,
    required this.requirements,
  });

  factory LabService.fromJson(Map<String, dynamic> json) {
    return LabService(
      id: json['id']?.toString() ?? '',
      laboratoryId: json['laboratoryId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      requirements: json['requirements'] as String? ?? '',
    );
  }
}

class LabResult {
  final String id;
  final String patientId;
  final String labServiceId;
  final String documentUrl; // Enlace al PDF
  final DateTime issueDate;
  final LabResultStatus status;

  LabResult({
    required this.id,
    required this.patientId,
    required this.labServiceId,
    required this.documentUrl,
    required this.issueDate,
    this.status = LabResultStatus.pending,
  });
}
