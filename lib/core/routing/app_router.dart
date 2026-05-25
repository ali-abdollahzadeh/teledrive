import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_credentials_screen.dart';
import '../../features/auth/presentation/screens/code_verification_screen.dart';
import '../../features/auth/presentation/screens/password_screen.dart';
import '../../features/drive/presentation/screens/drive_home_screen.dart';
import '../../features/drive/presentation/screens/share_to_drive_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../features/drive/presentation/screens/folder_screen.dart';
import '../../features/drive/presentation/screens/file_details_screen.dart';
import '../../features/preview/presentation/screens/image_preview_screen.dart';
import '../../features/preview/presentation/screens/video_preview_screen.dart';
import '../../features/preview/presentation/screens/audio_preview_screen.dart';
import '../../features/preview/presentation/screens/pdf_preview_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/terms_of_use_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../services/storage/secure_storage_service.dart';

// Route names
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String verifyCode = '/verify-code';
  static const String verifyPassword = '/verify-password';
  static const String drive = '/drive';
  static const String folder = '/folder/:folderId';
  static const String fileDetails = '/file/:fileId';
  static const String previewImage = '/preview/image/:fileId';
  static const String previewVideo = '/preview/video/:fileId';
  static const String previewAudio = '/preview/audio/:fileId';
  static const String previewPdf = '/preview/pdf/:fileId';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String termsOfUse = '/settings/terms-of-use';
  static const String shareToDrive = '/share-to-drive';
}

// ==========================================
// 🚪 DEV BACK DOOR SETTINGS
// ==========================================
const bool _isDevMode = false; // <-- SET TO FALSE BEFORE PUBLISHING APP

// Change this to the exact path of the page you want to design.
// If the route has parameters (like :fileId), provide mock data here:
// Example: '/file/mock_file_123' or AppRoutes.settings
const String _devTargetRoute = AppRoutes.drive;
// ==========================================

final appRouterProvider = Provider<GoRouter>((ref) {
  var isRestoringSession = false;

  return GoRouter(
    // 1. Boot directly into the screen you are designing
    initialLocation: _isDevMode ? _devTargetRoute : AppRoutes.welcome,

    redirect: (context, state) async {
      // 2. SHORT-CIRCUIT ALL AUTH CHECKS IF IN DEV MODE
      // Returning null tells GoRouter to just go to the requested page.
      if (_isDevMode) return null;

      final uriString = state.uri.toString();

      // Prevent GoRouter from crashing when Android passes file/content URIs
      // as deep links (e.g. when the user shares a file into the app).
      //
      // DO NOT call restoreSession() here — it calls NativeTelegramChannel.initialize()
      // which creates a new TDLib client. If TDLib is already running (warm start /
      // app resumed from background) this causes the "td.binlog already in use" error.
      // On a cold start, the normal isOnAuth block below handles session restore.
      // Here we only need to redirect to the right screen.
      if (uriString.startsWith('content://') ||
          uriString.startsWith('file://')) {
        final isLoggedIn = await SecureStorageService.instance.isLoggedIn();
        return isLoggedIn ? AppRoutes.drive : AppRoutes.welcome;
      }

      final isLoggedIn = await SecureStorageService.instance.isLoggedIn();
      final isOnAuth = state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.verifyCode ||
          state.matchedLocation == AppRoutes.verifyPassword;

      if (isLoggedIn && isOnAuth) {
        if (!isRestoringSession) {
          isRestoringSession = true;
          try {
            final authRepo = ref.read(authRepositoryProvider);
            await authRepo.restoreSession();
          } finally {
            isRestoringSession = false;
          }
        }
        return AppRoutes.drive;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginCredentialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyCode,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return CodeVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyPassword,
        builder: (context, state) => const PasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.drive,
        builder: (context, state) => const DriveHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shareToDrive,
        builder: (context, state) {
          final files = (state.extra as List<SharedMediaFile>?) ?? [];
          return ShareToDriveScreen(sharedFiles: files);
        },
      ),
      GoRoute(
        path: AppRoutes.folder,
        builder: (context, state) {
          final folderId = state.pathParameters['folderId'] ?? 'dev_mock_id';
          final folderName = state.uri.queryParameters['name'] ?? 'Folder';
          return FolderScreen(folderId: folderId, folderName: folderName);
        },
      ),
      GoRoute(
        path: AppRoutes.fileDetails,
        builder: (context, state) {
          final fileId = state.pathParameters['fileId'] ?? 'dev_mock_id';
          return FileDetailsScreen(fileId: fileId);
        },
      ),
      GoRoute(
        path: AppRoutes.previewImage,
        builder: (context, state) {
          final fileId = state.pathParameters['fileId'] ?? 'dev_mock_id';
          return ImagePreviewScreen(fileId: fileId);
        },
      ),
      GoRoute(
        path: AppRoutes.previewVideo,
        builder: (context, state) {
          final fileId = state.pathParameters['fileId'] ?? 'dev_mock_id';
          return VideoPreviewScreen(fileId: fileId);
        },
      ),
      GoRoute(
        path: AppRoutes.previewAudio,
        builder: (context, state) {
          final fileId = state.pathParameters['fileId'] ?? 'dev_mock_id';
          return AudioPreviewScreen(fileId: fileId);
        },
      ),
      GoRoute(
        path: AppRoutes.previewPdf,
        builder: (context, state) {
          final fileId = state.pathParameters['fileId'] ?? 'dev_mock_id';
          return PdfPreviewScreen(fileId: fileId);
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsOfUse,
        builder: (context, state) => const TermsOfUseScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
