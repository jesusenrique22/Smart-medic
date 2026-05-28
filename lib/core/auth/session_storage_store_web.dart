import 'package:web/web.dart' as web;

/// En web: [sessionStorage] es **por pestaña**, no compartido entre pestañas.
/// Permite probar paciente y médico a la vez en dos pestañas del mismo puerto.
class SessionStorageStore {
  static Future<void> setString(String key, String value) async {
    web.window.sessionStorage.setItem(key, value);
  }

  static Future<String?> getString(String key) async {
    return web.window.sessionStorage.getItem(key);
  }

  static Future<void> remove(String key) async {
    web.window.sessionStorage.removeItem(key);
  }
}
