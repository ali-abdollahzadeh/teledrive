import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../../../core/constants/app_text.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(SecureStorageService.instance);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ─── State ────────────────────────────────────────────────────────────────────

enum AuthStep {
  idle,
  sendingCode,
  codeSent,
  verifyingCode,
  needs2FA,
  verifyingPassword,
  authenticated,
  loggingOut,
}

class AuthState {
  final AuthStep step;
  final String? error;
  final String phoneNumber;

  const AuthState({
    this.step = AuthStep.idle,
    this.error,
    this.phoneNumber = '',
  });

  bool get isLoading =>
      step == AuthStep.sendingCode ||
      step == AuthStep.verifyingCode ||
      step == AuthStep.verifyingPassword ||
      step == AuthStep.loggingOut;

  AuthState copyWith({
    AuthStep? step,
    String? error,
    String? phoneNumber,
  }) {
    return AuthState(
      step: step ?? this.step,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> sendCode({
    required String phone,
  }) async {
    final cleanPhone = phone.trim();

    state = state.copyWith(
      step: AuthStep.sendingCode,
      phoneNumber: cleanPhone,
      error: null,
    );

    try {
      await _repository.sendCode(phone: cleanPhone);
      state = state.copyWith(step: AuthStep.codeSent);
    } catch (e) {
      state = state.copyWith(step: AuthStep.idle, error: _cleanError(e));
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(step: AuthStep.verifyingCode, error: null);
    try {
      final authenticated = await _repository.verifyCode(code);
      if (authenticated) {
        state = state.copyWith(step: AuthStep.authenticated);
        return true;
      } else {
        state = state.copyWith(step: AuthStep.needs2FA);
        return false;
      }
    } catch (e) {
      state = state.copyWith(step: AuthStep.codeSent, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    state = state.copyWith(step: AuthStep.verifyingPassword, error: null);
    try {
      final authenticated = await _repository.verifyPassword(password);
      if (authenticated) {
        state = state.copyWith(step: AuthStep.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(step: AuthStep.needs2FA, error: _cleanError(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(step: AuthStep.loggingOut);
    await _repository.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);

  String _cleanError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');

    // Make TDLib errors user-friendly
    if (msg.contains(AppText.registrationRequired)) {
      return AppText.registrationRequiredMessage;
    }

    if (msg.contains(AppText.phoneNumberInvalidKey)) {
      return AppText.phoneNumberInvalidMessage;
    }

    if (msg.contains('PHONE_CODE_INVALID')) {
      return AppText.phoneCodeInvalidMessage;
    }

    if (msg.contains('PHONE_CODE_EXPIRED')) {
      return AppText.phoneCodeExpiredMessage;
    }

    if (msg.contains('PASSWORD_HASH_INVALID')) {
      return AppText.passwordHashInvalidMessage;
    }

    if (msg.contains('timed out') ||
        msg.contains('TimeoutException') ||
        msg.contains('Network is unreachable') ||
        msg.contains('Connection refused') ||
        msg.contains('Failed host lookup')) {
      return AppText.connectionTimedOut;
    }

    return msg;
  }
}
