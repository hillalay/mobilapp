/// Supabase bağlantı ayarları --dart-define ile veriliyor; anahtarlar repoya girmiyor.
///
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// Publishable key (eski adıyla anon key) istemciye gömülmek üzere tasarlanmış
/// açık bir anahtardır; veriyi koruyan şey RLS politikalarıdır. Yine de repoya
/// yazılmıyor. `service_role` anahtarı ASLA istemciye konmaz.
///
/// Tanımlı değilse uygulama tamamen yerel (offline) çalışır: giriş ekranı
/// çıkmaz, senkron devre dışı kalır.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
