import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class VisitorRepository {
  final ApiClient _apiClient;

  VisitorRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Ambil daftar event dari backend
  Future<Map<String, dynamic>> fetchEvents() async {
    final response = await _apiClient.dio.get(ApiEndpoints.events);
    return response.data as Map<String, dynamic>;
  }

  /// Ambil detail satu event
  Future<Map<String, dynamic>> fetchEventDetail(String eventId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.eventDetail(eventId));
    return response.data as Map<String, dynamic>;
  }

  /// Ambil daftar tiket yang dimiliki user
  Future<Map<String, dynamic>> fetchMyTickets() async {
    final response = await _apiClient.dio.get(ApiEndpoints.myTickets);
    return response.data as Map<String, dynamic>;
  }

  /// Ambil QR Token dinamis untuk tiket tertentu
  Future<Map<String, dynamic>> fetchQrToken(String ticketId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.qrToken(ticketId));
    return response.data as Map<String, dynamic>;
  }

  /// Ambil informasi wallet
  Future<Map<String, dynamic>> fetchWallet() async {
    final response = await _apiClient.dio.get(ApiEndpoints.wallet);
    return response.data as Map<String, dynamic>;
  }

  /// Lock seat sebelum checkout
  Future<Map<String, dynamic>> lockSeat(
      String eventId, String seatId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.lockSeat,
      data: {'event_id': eventId, 'seat_id': seatId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Buat order pembayaran
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.createOrder,
      data: orderData,
    );
    return response.data as Map<String, dynamic>;
  }
}
