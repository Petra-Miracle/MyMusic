/// Konfigurasi build. Bisa diganti tanpa ubah kode:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api   (backend lokal dari emulator)
///   flutter run --dart-define=USE_MOCK=true                          (data contoh, tanpa internet)
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://my-music-backend-bejv.vercel.app/api',
  );

  static const useMock = bool.fromEnvironment('USE_MOCK');
}
