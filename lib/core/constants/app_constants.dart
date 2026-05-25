class AppConstants {
  AppConstants._();

  static const String appName = 'TeleDrive';
  static const String appVersion = '1.2.0';
  static const String appTagline = 'Your Telegram, your cloud.';
  static const String telegramHelpUrl = 'https://my.telegram.org/auth';
  static const String telegramAppUrl = 'https://my.telegram.org';

  // File size limits
  static const int maxUploadSizeBytes = 2 * 1024 * 1024 * 1024; // 2GB
  static const int maxUploadSizeMb = 2048;
  static const int thumbnailMaxSizeBytes = 200 * 1024; // 200KB
  static const int maxUploadBatchCount = 10;

  // Cache
  static const int maxCacheSizeMb = 500;
  static const int defaultCacheDurationDays = 7;

  // UI
  static const double gridItemAspectRatio = 1.0;
  static const int gridCrossAxisCount = 2;
  static const double cardBorderRadius = 16.0;
  static const double itemBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Animation
  static const Duration shortAnimDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimDuration = Duration(milliseconds: 350);
  static const Duration longAnimDuration = Duration(milliseconds: 500);

  // Mock data — set to false when TDLib is integrated
  static const bool useMockData = false;
}

class StorageKeys {
  StorageKeys._();

  static const String apiId = 'tg_api_id';
  static const String apiHash = 'tg_api_hash';
  static const String phone = 'tg_phone_number';         // real phone key
  static const String phoneNumber = 'tg_phone_number';   // alias
  static const String sessionString = 'tg_session_string';
  static const String isLoggedIn = 'tg_is_logged_in';
  static const String isAuthenticated = 'tg_is_authenticated';
  static const String themeMode = 'app_theme_mode';
  static const String viewMode = 'app_view_mode';
  static const String downloadPath = 'app_download_path';
  static const String cacheSize = 'app_cache_size';
}
