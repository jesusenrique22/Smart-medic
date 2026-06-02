import '../../../core/network/api_client.dart';
import 'admin_api_service.dart';

final _client = ApiClient();

class ClinicDoctorListItem {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? profilePic;
  final List<String> specialties;
  final List<String> facilityNames;
  final bool canInvite;
  final String? inviteBlockedReason;

  const ClinicDoctorListItem({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profilePic,
    required this.specialties,
    required this.facilityNames,
    this.canInvite = true,
    this.inviteBlockedReason,
  });

  static String _idFrom(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value['_id']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  factory ClinicDoctorListItem.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw const FormatException('Doctor sin datos de usuario');
    }
    final profile = j['profile'] as Map<String, dynamic>?;

    List<String> names(dynamic list) {
      if (list == null) return [];
      return (list as List).map((e) {
        if (e is Map<String, dynamic>) return e['name'] as String? ?? '';
        return '';
      }).toList();
    }

    return ClinicDoctorListItem(
      userId: _idFrom(user['_id'] ?? user['id']),
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      phone: user['phone'] as String?,
      profilePic: user['profilePic'] as String?,
      specialties: profile != null ? names(profile['specialtyIds']) : const [],
      facilityNames: profile != null ? names(profile['facilityIds']) : const [],
      canInvite: j['canInvite'] as bool? ?? true,
      inviteBlockedReason: j['inviteBlockedReason'] as String?,
    );
  }
}

class ClinicPendingInvitation {
  final String id;
  final String doctorName;
  final String doctorEmail;

  const ClinicPendingInvitation({
    required this.id,
    required this.doctorName,
    required this.doctorEmail,
  });

  factory ClinicPendingInvitation.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctor'] as Map<String, dynamic>? ?? {};
    return ClinicPendingInvitation(
      id: j['id'] as String? ?? j['_id'] as String? ?? '',
      doctorName: doctor['name'] as String? ?? '',
      doctorEmail: doctor['email'] as String? ?? '',
    );
  }
}

class ClinicDashboardData {
  final String facilityName;
  final String facilityId;
  final int doctorsCount;
  final int appointmentsToday;
  final int pendingInvitationsCount;
  final List<ClinicDoctorListItem> doctors;
  final List<ClinicPendingInvitation> pendingInvitations;

  const ClinicDashboardData({
    required this.facilityName,
    required this.facilityId,
    required this.doctorsCount,
    required this.appointmentsToday,
    required this.pendingInvitationsCount,
    required this.doctors,
    required this.pendingInvitations,
  });

  factory ClinicDashboardData.fromJson(Map<String, dynamic> j) {
    final facility = j['facility'] as Map<String, dynamic>? ?? {};
    final stats = j['stats'] as Map<String, dynamic>? ?? {};
    final rawDoctors = j['doctors'] as List<dynamic>? ?? [];
    final rawInvites = j['pendingInvitations'] as List<dynamic>? ?? [];

    return ClinicDashboardData(
      facilityName: facility['name'] as String? ?? 'Clínica',
      facilityId: facility['_id'] as String? ?? '',
      doctorsCount: (stats['doctorsCount'] as num?)?.toInt() ?? 0,
      appointmentsToday: (stats['appointmentsToday'] as num?)?.toInt() ?? 0,
      pendingInvitationsCount:
          (stats['pendingInvitationsCount'] as num?)?.toInt() ??
          rawInvites.length,
      doctors: rawDoctors
          .map((e) => ClinicDoctorListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingInvitations: rawInvites
          .map(
            (e) => ClinicPendingInvitation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ClinicAdminApiService {
  Future<Map<String, dynamic>> getMyContext() async {
    final data = await _client.get('/api/clinic-admin/me');
    return data as Map<String, dynamic>;
  }

  Future<ClinicDashboardData> getDashboard() async {
    final data = await _client.get('/api/clinic-admin/dashboard');
    return ClinicDashboardData.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ClinicDoctorListItem>> listFacilityDoctors() async {
    final data = await _client.get('/api/clinic-admin/doctors');
    final list = data as List<dynamic>;
    final doctors = <ClinicDoctorListItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        doctors.add(ClinicDoctorListItem.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    }
    return doctors;
  }

  Future<List<ClinicDoctorListItem>> listAssignableDoctors({String? search}) async {
    final query = search != null && search.trim().isNotEmpty
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    final data = await _client.get('/api/clinic-admin/doctors/assignable$query');
    final list = data as List<dynamic>;
    final doctors = <ClinicDoctorListItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        doctors.add(ClinicDoctorListItem.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // Omitir entradas corruptas del API.
      }
    }
    return doctors;
  }

  Future<String> assignDoctor(String doctorUserId) async {
    final data = await _client.post(
      '/api/clinic-admin/doctors/assign',
      {'doctorUserId': doctorUserId},
      auth: true,
    );
    return data['message'] as String? ??
        'Invitación enviada. El médico debe aceptarla.';
  }

  Future<void> unassignDoctor(String doctorUserId) async {
    await _client.delete('/api/clinic-admin/doctors/$doctorUserId');
  }

  Future<CreateDoctorResult> createDoctor({
    required String name,
    required String email,
    required String phone,
    required String documentId,
    required String specialtyId,
  }) async {
    final data = await _client.post(
      '/api/clinic-admin/doctors',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'documentId': documentId.trim(),
        'specialtyId': specialtyId,
      },
      auth: true,
    );
    return CreateDoctorResult.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '/api/clinic-admin/password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
