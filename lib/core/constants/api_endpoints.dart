/// Konstanta URL Endpoint Backend WhiteLabel API
///
/// ════════════════════════════════════════════════════════════════════════════
/// 🔧 KONFIGURASI WIRELESS DEBUG (WiFi Debugging dari HP ke Laptop)
/// ════════════════════════════════════════════════════════════════════════════
///
/// 1. Pastikan HP dan Laptop terhubung ke WiFi yang SAMA.
///
/// 2. Cari IP WiFi laptop:
///    - Windows:  Buka CMD → ketik `ipconfig` → cari "IPv4 Address" pada adapter WiFi
///    - macOS:    System Preferences → Network → WiFi → IP Address
///    - Linux:    `ip addr show wlan0` atau `hostname -I`
///
/// 3. Update [baseUrl] di bawah dengan IP yang ditemukan.
///    Contoh: Jika laptop IPv4 = 192.168.1.100, maka:
///    `static const String baseUrl = 'http://192.168.1.100:4000/api/v1';`
///
/// 4. Pastikan backend berjalan: `npm run dev` di folder wl_backend
///
/// 5. Jalankan app: `flutter run` — Flutter akan otomatis mendeteksi device
///    yang terhubung via USB maupun wireless debugging.
///
/// 6. Untuk wireless debugging via ADB:
///    a. Sambungkan HP via USB terlebih dahulu
///    b. Jalankan: `adb tcpip 5555`
///    c. Cabut USB, lalu: `adb connect <IP_HP>:5555`
///    d. Verifikasi: `adb devices` — harus muncul device wireless
///    e. Jalankan: `flutter run -d <device_id>`
/// ════════════════════════════════════════════════════════════════════════════
class ApiEndpoints {
  // ┌──────────────────────────────────────────────────────────────────────────┐
  // │  Base Backend URL — UPDATE IP INI sesuai IPv4 WiFi laptop kamu!        │
  // │  Laptop IPv4 saat ini: 192.168.110.132                                  │
  // └──────────────────────────────────────────────────────────────────────────┘
  static const String baseUrl = 'http://192.168.110.132:4000/api/v1';
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
