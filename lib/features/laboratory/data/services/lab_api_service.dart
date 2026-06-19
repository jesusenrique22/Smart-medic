import '../../../../core/network/api_client.dart';
import '../../domain/models/laboratory_models.dart';

class LabApiService {
  final ApiClient _client = ApiClient();

  Future<List<Laboratory>> getLaboratories() async {
    final response = await _client.get('/api/catalog/laboratories', auth: false);
    if (response is List) {
      return response.map((item) => Laboratory.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
