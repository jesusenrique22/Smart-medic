import '../../../core/network/api_client.dart';
import '../../appointments/domain/models/appointment.dart';

final _client = ApiClient();

class DoctorProfileContext {
  final String name;
  final String subtitle;
  final String avatarUrl;
  final double rating;
  final int ratingCount;

  const DoctorProfileContext({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.rating,
    required this.ratingCount,
  });
}

class DoctorFacilityItem {
  final String id;
  final String name;

  const DoctorFacilityItem({required this.id, required this.name});

  factory DoctorFacilityItem.fromJson(Map<String, dynamic> json) {
    return DoctorFacilityItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
    );
  }
}

class DoctorSpecialtyEntry {
  final String id;
  final String name;
  final int durationMinutes;

  const DoctorSpecialtyEntry({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });
}

class DoctorFullProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final String? licenseNumber;
  final double rating;
  final int ratingCount;
  final int defaultConsultationMinutes;
  final List<DoctorSpecialtyEntry> specialties;
  final List<DoctorFacilityItem> facilities;

  const DoctorFullProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    this.licenseNumber,
    required this.rating,
    required this.ratingCount,
    required this.defaultConsultationMinutes,
    required this.specialties,
    required this.facilities,
  });

  String get specialtySubtitle => specialties.isEmpty
      ? 'Médico'
      : specialties.map((s) => s.name).join(' · ');

  String get facilitySubtitle {
    final names = facilities
        .map((f) => f.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'VITA OS';
    return names.join(' · ');
  }

  factory DoctorFullProfile.fromApi(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final profile = data['profile'] as Map<String, dynamic>? ?? {};

    final specialtyList = profile['specialtyIds'] as List<dynamic>? ?? [];
    final durationRules = (profile['specialtyConsultationDurations'] as List<dynamic>? ??
            [])
        .whereType<Map<String, dynamic>>()
        .map(SpecialtyDurationRule.fromJson)
        .toList();

    final defaultMins =
        (profile['defaultConsultationMinutes'] as num?)?.toInt() ?? 30;

    int minutesFor(String specialtyId) {
      for (final rule in durationRules) {
        if (rule.specialtyId == specialtyId) return rule.durationMinutes;
      }
      return defaultMins;
    }

    final specialties = specialtyList.whereType<Map<String, dynamic>>().map((s) {
      final id = (s['_id'] ?? s['id'] ?? '').toString();
      return DoctorSpecialtyEntry(
        id: id,
        name: s['name'] as String? ?? '',
        durationMinutes: minutesFor(id),
      );
    }).toList();

    final facilities = <DoctorFacilityItem>[];
    for (final item in profile['facilityIds'] as List<dynamic>? ?? []) {
      if (item is Map<String, dynamic>) {
        facilities.add(DoctorFacilityItem.fromJson(item));
      } else if (item != null) {
        facilities.add(
          DoctorFacilityItem(id: item.toString(), name: ''),
        );
      }
    }

    return DoctorFullProfile(
      name: user['name'] as String? ?? 'Médico',
      email: user['email'] as String? ?? '',
      avatarUrl: user['profilePic'] as String? ?? '',
      bio: profile['bio'] as String? ?? '',
      licenseNumber: profile['licenseNumber'] as String?,
      rating: (profile['rating'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (profile['ratingCount'] as num?)?.toInt() ?? 0,
      defaultConsultationMinutes: defaultMins,
      specialties: specialties,
      facilities: facilities,
    );
  }

}

class DoctorWorkScheduleItem {
  final String id;
  final String dayLabel;
  final String facilityName;
  final String startTime;
  final String endTime;

  const DoctorWorkScheduleItem({
    required this.id,
    required this.dayLabel,
    required this.facilityName,
    required this.startTime,
    required this.endTime,
  });

  static const _dayLabels = {
    'MONDAY': 'Lunes',
    'TUESDAY': 'Martes',
    'WEDNESDAY': 'Miércoles',
    'THURSDAY': 'Jueves',
    'FRIDAY': 'Viernes',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  factory DoctorWorkScheduleItem.fromJson(Map<String, dynamic> json) {
    final facility = json['facilityId'];
    String facilityName = '';
    if (facility is Map<String, dynamic>) {
      facilityName = facility['name'] as String? ?? '';
    }
    final day = json['dayOfWeek'] as String? ?? '';
    return DoctorWorkScheduleItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      dayLabel: _dayLabels[day] ?? day,
      facilityName: facilityName,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }
}

class DoctorApiService {
  static String dayOfWeekFromSpanish(String spanishDay) {
    switch (spanishDay) {
      case 'Lunes':
        return 'MONDAY';
      case 'Martes':
        return 'TUESDAY';
      case 'Miércoles':
        return 'WEDNESDAY';
      case 'Jueves':
        return 'THURSDAY';
      case 'Viernes':
        return 'FRIDAY';
      case 'Sábado':
        return 'SATURDAY';
      case 'Domingo':
        return 'SUNDAY';
      default:
        return 'MONDAY';
    }
  }

  Future<DoctorFullProfile> getFullProfile() async {
    final data = await _client.get('/api/doctors/profile');
    return DoctorFullProfile.fromApi(data as Map<String, dynamic>);
  }

  Future<DoctorProfileContext> getProfileContext() async {
    final full = await getFullProfile();
    final parts = <String>[];
    if (full.specialtySubtitle.isNotEmpty &&
        full.specialtySubtitle != 'Médico') {
      parts.add(full.specialtySubtitle);
    }
    parts.add(full.facilitySubtitle);
    return DoctorProfileContext(
      name: full.name,
      subtitle: parts.join(' • '),
      avatarUrl: full.avatarUrl,
      rating: full.rating,
      ratingCount: full.ratingCount,
    );
  }

  Future<List<SpecialtyCatalogItem>> listCatalogSpecialties() async {
    final data = await _client.get('/api/catalog/specialties', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => SpecialtyCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorFullProfile> updateProfileDetails({
    String? name,
    String? bio,
    String? licenseNumber,
    int? defaultConsultationMinutes,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (licenseNumber != null) body['licenseNumber'] = licenseNumber;
    if (defaultConsultationMinutes != null) {
      body['defaultConsultationMinutes'] = defaultConsultationMinutes;
    }
    final data = await _client.patch('/api/doctors/profile', body);
    final user = data['user'] as Map<String, dynamic>?;
    final profile = data['profile'] as Map<String, dynamic>?;
    return DoctorFullProfile.fromApi({
      'user': user ?? {},
      'profile': profile ?? {},
    });
  }

  Future<DoctorFullProfile> addSpecialty(String specialtyId) async {
    await _client.post(
      '/api/doctors/profile/specialties',
      {'specialtyId': specialtyId},
      auth: true,
    );
    return getFullProfile();
  }

  Future<DoctorFullProfile> createAndAddSpecialty(String name) async {
    await _client.post(
      '/api/doctors/profile/specialties/new',
      {'name': name.trim()},
      auth: true,
    );
    return getFullProfile();
  }

  Future<DoctorFullProfile> removeSpecialty(String specialtyId) async {
    await _client.delete('/api/doctors/profile/specialties/$specialtyId');
    return getFullProfile();
  }

  Future<DoctorFullProfile> updateSpecialtyDuration(
    String specialtyId,
    int durationMinutes,
  ) async {
    await _client.patch(
      '/api/doctors/profile/specialties/$specialtyId/duration',
      {'durationMinutes': durationMinutes},
    );
    return getFullProfile();
  }

  Future<List<DoctorFacilityItem>> getMyFacilities() async {
    final full = await getFullProfile();
    return full.facilities;
  }

  Future<List<DoctorWorkScheduleItem>> getSchedules() async {
    final data = await _client.get('/api/doctors/schedules');
    final list = data as List<dynamic>;
    return list
        .map((e) => DoctorWorkScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createSchedule({
    required String facilityId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    await _client.post(
      '/api/doctors/schedules',
      {
        'facilityId': facilityId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      },
      auth: true,
    );
  }

  Future<void> deleteSchedule(String id) async {
    await _client.delete('/api/doctors/schedules/$id');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch('/api/doctors/profile/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<String> acceptClinicInvitation(String invitationId) async {
    final data = await _client.post(
      '/api/doctors/clinic-invitations/$invitationId/accept',
      {},
      auth: true,
    );
    return data['message'] as String? ?? 'Invitación aceptada';
  }

  Future<String> rejectClinicInvitation(String invitationId) async {
    final data = await _client.post(
      '/api/doctors/clinic-invitations/$invitationId/reject',
      {},
      auth: true,
    );
    return data['message'] as String? ?? 'Invitación rechazada';
  }
}
