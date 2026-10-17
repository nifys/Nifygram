/// Supabase project configuration.
/// Publishable/anon keys are intended for client apps; never use service_role here.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://airydnzaokarlpcmlczl.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_kL0KBEJD4VewmB3taeH5jQ_69RDcQ4W',
  );

  static bool get isConfigured => url.startsWith('https://') && anonKey.isNotEmpty;
}
