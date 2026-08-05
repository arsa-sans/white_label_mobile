import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class OrganizerRepository {
  final ApiClient _apiClient;

  OrganizerRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Ambil analytics dashboard organizer
  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await _apiClient.dio.get(ApiEndpoints.analyticsDashboard);
    return response.data as Map<String, dynamic>;
  }
}
