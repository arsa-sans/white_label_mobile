class ApiEndpoints {
  // Base Backend URL — change to your server IP when testing on device
  // Android emulator: use '10.0.2.2'; iOS simulator: 'localhost'
  static const String baseUrl = 'http://10.0.2.2:4000/api/v1';
  static const String devLocalhostUrl = 'http://localhost:4000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Events
  static const String events = '/events';
  static String eventDetail(String id) => '/events/$id';

  // Tickets & Seat Locking
  static const String lockSeat = '/tickets/lock-seat';
  static const String releaseSeat = '/tickets/release-seat';
  static const String myTickets = '/tickets/my-tickets';
  static String qrToken(String ticketId) => '/tickets/$ticketId/qr-token';

  // Waiting Room
  static const String joinQueue = '/tickets/queue/join';
  static const String queueStatus = '/tickets/queue/status';

  // Payments
  static const String createOrder = '/payments/create-order';

  // Gate Scan
  static const String gateScan = '/gate/scan';
  static const String gateSync = '/gate/sync';

  // Cashless & Booth
  static const String wallet = '/cashless/wallet';
  static const String walletTopup = '/cashless/wallet/topup';
  static const String boothDebit = '/cashless/booth/debit';

  // Analytics
  static const String analyticsDashboard = '/analytics/dashboard';
}
