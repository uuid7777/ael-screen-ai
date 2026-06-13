/// AEL Screen AI - App Configuration
/// Fill in your API keys here or use environment variables.

class AppConfig {
  // -------- Backend API --------
  // Change this to your deployed backend URL
  static const String baseUrl = 'http://localhost:8000';

  // -------- Supabase --------
  static const String supabaseUrl = 'https://lpxcbnwrlisvpozagxiq.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_CE-w85cBvhiV1m1_LGLK8A_ILU6TVnE';

  // -------- App Info --------
  static const String appName = 'AEL Screen AI';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.ael.screenai';
}
