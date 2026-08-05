import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class BoothRepository {
  final ApiClient _apiClient;

  BoothRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Proses transaksi debit wristband NFC melalui backend
  Future<Map<String, dynamic>> debitBooth({
    required int amount,
    required String nfcUid,
    required String referenceId,
    String boothName = 'Mobile Booth Cashier',
    String? itemsSummary,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.boothDebit,
      data: {
        'amount': amount,
        'nfc_uid': nfcUid,
        'reference_id': referenceId,
        'booth_name': boothName,
        if (itemsSummary != null && itemsSummary.isNotEmpty)
          'items_summary': itemsSummary,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
