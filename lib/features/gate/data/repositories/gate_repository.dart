import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class GateRepository {
  final ApiClient _apiClient;

  GateRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Kirim QR token ke backend untuk validasi
  Future<Map<String, dynamic>> scanTicket(String qrToken) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.gateScan,
      data: {'token': qrToken},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Batch sync offline scan logs ke backend
  Future<Map<String, dynamic>> syncOfflineLogs(
      List<Map<String, dynamic>> logs) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.gateSync,
      data: {'logs': logs},
    );
    return response.data as Map<String, dynamic>;
  }
}
