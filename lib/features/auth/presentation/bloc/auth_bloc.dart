import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent {}

class AppStarted            extends AuthEvent {}
class LogoutRequested       extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String name, email, password;
  final String? phoneNumber;
  RegisterRequested({required this.name, required this.email,
      required this.password, this.phoneNumber});
}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested({required this.email, required this.password});
}

// ✅ NEW: Catches the Google Deep Link Token
class GoogleAuthTokenReceived extends AuthEvent {
  final String token;
  GoogleAuthTokenReceived(this.token);
}

// ✅ NEW: Triggers Forgot Password (FIXES YOUR ERROR)
class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested(this.email);
}

class CompleteProfileRequested extends AuthEvent {
  final String phoneNumber;
  final String? name;
  CompleteProfileRequested({required this.phoneNumber, this.name});
}

class UpdateProfileRequested extends AuthEvent {
  final String? name, phoneNumber;
  UpdateProfileRequested({this.name, this.phoneNumber});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState {}

class AuthInitial          extends AuthState {}
class AuthAuthenticated    extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated  extends AuthState {}
class AuthLoading          extends AuthState {}
class AuthError            extends AuthState {
  final String message;
  AuthError(this.message);
}

// ✅ NEW: Highly reusable success state for one-off actions like "Email Sent"
class AuthActionSuccess extends AuthState {
  final String message;
  AuthActionSuccess(this.message);
}

class AuthProfileIncomplete extends AuthState {
  final UserModel user;
  AuthProfileIncomplete(this.user);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<GoogleAuthTokenReceived>(_onGoogleAuthTokenReceived); // ✅ Added
    on<ForgotPasswordRequested>(_onForgotPassword); // ✅ Added
    on<LogoutRequested>(_onLogout);
    on<CompleteProfileRequested>(_onCompleteProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final restored = await _repo.tryRestoreSession();
    if (restored && _repo.currentUser != null) {
      final user = _repo.currentUser!;
      emit(user.profileComplete ? AuthAuthenticated(user) : AuthProfileIncomplete(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repo.register(
        name: event.name, email: event.email,
        password: event.password, phoneNumber: event.phoneNumber,
      );
      emit(result.user.profileComplete
          ? AuthAuthenticated(result.user)
          : AuthProfileIncomplete(result.user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Connection failed. Please check your network.'));
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repo.login(email: event.email, password: event.password);
      emit(result.user.profileComplete
          ? AuthAuthenticated(result.user)
          : AuthProfileIncomplete(result.user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Connection failed. Please check your network.'));
    }
  }

  // ✅ NEW: Handle Deep Link Token
  Future<void> _onGoogleAuthTokenReceived(GoogleAuthTokenReceived event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.handleGoogleSignIn(event.token);
      emit(user.profileComplete ? AuthAuthenticated(user) : AuthProfileIncomplete(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Google sign-in failed. Please try again.'));
    }
  }

  // ✅ NEW: Handle Forgot Password
  Future<void> _onForgotPassword(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.forgotPassword(event.email);
      emit(AuthActionSuccess('Password reset link sent to ${event.email}'));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Connection failed. Please check your network.'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCompleteProfile(CompleteProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.completeProfile(phoneNumber: event.phoneNumber, name: event.name);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Failed to save profile. Please try again.'));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.updateProfile(name: event.name, phoneNumber: event.phoneNumber);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }
}