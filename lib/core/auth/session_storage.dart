import 'dart:convert';

import 'session_storage_store.dart';
import '../../features/auth/data/role_mapper.dart';
import '../../features/auth/domain/models/user.dart';

const _sessionKey = 'vita_os_session';

/// Guarda la sesión JWT + usuario.
///
/// En **web** usa `sessionStorage` (una sesión por pestaña) para poder abrir
/// paciente y médico en dos pestañas sin pisarse el login.
/// En móvil/escritorio usa SharedPreferences.
class SessionStorage {
  static Future<void> save({required User user, required String token}) async {
    await SessionStorageStore.setString(
      _sessionKey,
      jsonEncode({
        'token': token,
        'user': {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': RoleMapper.toApi(user.role),
          'avatarUrl': user.avatarUrl,
          'phone': user.phone,
        },
      }),
    );
  }

  static Future<({User user, String token})?> load() async {
    final raw = await SessionStorageStore.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final token = map['token'] as String?;
      final userMap = map['user'] as Map<String, dynamic>?;
      if (token == null || token.isEmpty || userMap == null) return null;

      final roleStr = userMap['role'] as String? ?? 'PATIENT';
      final user = User(
        id: userMap['id']?.toString() ?? '',
        name: userMap['name'] as String? ?? '',
        email: userMap['email'] as String? ?? '',
        role: RoleMapper.fromApi(roleStr),
        avatarUrl: userMap['avatarUrl'] as String? ?? '',
        phone: userMap['phone'] as String?,
      );
      if (user.id.isEmpty) return null;
      return (user: user, token: token);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await SessionStorageStore.remove(_sessionKey);
  }
}
