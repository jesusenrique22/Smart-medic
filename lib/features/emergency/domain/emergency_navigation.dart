import '../../../core/geo/geo_point.dart';
import 'models/emergency_models.dart';

/// Destino de navegación según el estado del servicio (como delivery apps).
class EmergencyNavigation {
  EmergencyNavigation._();

  static bool routesToClinic(EmergencyStatus status) {
    return status == EmergencyStatus.patientOnboard ||
        status == EmergencyStatus.enRoute ||
        status == EmergencyStatus.arrived;
  }

  static GeoPoint destination(EmergencyRequest request) {
    if (routesToClinic(request.status) &&
        request.facility?.location != null &&
        request.facility!.location!.isValid) {
      return request.facility!.location!;
    }
    return request.origin;
  }

  static String destinationLabel(EmergencyRequest request) {
    if (routesToClinic(request.status)) {
      return request.facility?.name ?? 'Clínica de destino';
    }
    return request.originAddress ?? 'Ubicación del paciente';
  }

  static String destinationHint(EmergencyRequest request) {
    if (routesToClinic(request.status)) {
      return 'Traslado a urgencias';
    }
    return 'Recoger paciente';
  }
}
