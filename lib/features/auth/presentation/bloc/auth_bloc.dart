import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/auth/domain/repositories/auth_repository.dart';
import 'package:csms/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:csms/core/services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';
import 'package:csms/injection_container.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'dart:async';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final OnboardingRepository onboardingRepository;
  final ShopRepository _shopRepository = sl<ShopRepository>();
  StreamSubscription<DatabaseEvent>? _userStatusSubscription;

  AuthBloc({required this.authRepository, required this.onboardingRepository})
    : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<VerifyPhoneRequested>(_onVerifyPhoneRequested);
    on<SubmitOtpRequested>(_onSubmitOtpRequested);
    on<OnboardingRequested>(_onOnboardingRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<_OtpSentInternal>(
      (event, emit) => emit(AuthOtpSent(event.verificationId)),
    );
    on<_AuthErrorInternal>((event, emit) => emit(AuthError(event.message)));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final userId = await authRepository.getSavedUser();
    if (userId != null && userId.isNotEmpty) {
      // Verify user exists and has a role on boot
      final profile = await authRepository.getUserFullProfile(userId);
      if (profile != null) {
        final status = profile['status']?.toString().toLowerCase() ?? 'active';
        if (status == 'inactive') {
          await authRepository.signOut();
          emit(const AuthError("Your account is inactive. Please contact support."));
          emit(AuthUnauthenticated());
          return;
        }

        final role = profile['role']?.toString().toLowerCase() ?? '';
        final ownerId = role == 'owner' ? userId : (profile['ownerId'] ?? '');
        final name = profile['name'] ?? 'User';
        final shopId = profile['shopId'] ?? '';
        _captureAndStoreFCMToken(userId);
        _listenToUserStatus(userId);
        emit(AuthAuthenticated(userId,
            ownerId: ownerId, name: name, role: role, shopId: shopId));
      } else {
        await authRepository.signOut();
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signIn(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (userId) async {
        final profile = await authRepository.getUserFullProfile(userId);
        final status = profile?['status']?.toString().toLowerCase() ?? 'active';
        if (status == 'inactive') {
          await authRepository.signOut();
          emit(const AuthError(
              "Your account is inactive. Please contact support."));
          return;
        }

        final role = profile?['role']?.toString().toLowerCase() ?? '';
        final ownerId = role == 'owner' ? userId : (profile?['ownerId'] ?? '');
        final name = profile?['name'] ?? 'User';
        final shopId = profile?['shopId'] ?? '';
        _listenToUserStatus(userId);
        emit(AuthAuthenticated(userId,
            ownerId: ownerId, name: name, role: role, shopId: shopId));
      },
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signUp(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (userId) async {
        final profile = await authRepository.getUserFullProfile(userId);
        final status = profile?['status']?.toString().toLowerCase() ?? 'active';
        if (status == 'inactive') {
          await authRepository.signOut();
          emit(const AuthError(
              "Your account is inactive. Please contact support."));
          return;
        }

        final role = profile?['role']?.toString().toLowerCase() ?? '';
        final ownerId = role == 'owner' ? userId : (profile?['ownerId'] ?? '');
        final name = profile?['name'] ?? 'User';
        final shopId = profile?['shopId'] ?? '';
        _listenToUserStatus(userId);
        emit(AuthAuthenticated(userId,
            ownerId: ownerId, name: name, role: role, shopId: shopId));
      },
    );
  }

  Future<void> _onVerifyPhoneRequested(
    VerifyPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.verifyPhoneNumber(
      phoneNumber: event.phoneNumber,
      onCodeSent: (verificationId) {
        add(_OtpSentInternal(verificationId));
      },
      onVerificationFailed: (error) {
        add(_AuthErrorInternal(error));
      },
    );

    result.fold((failure) => emit(AuthError(failure.message)), (_) => null);
  }

  Future<void> _onSubmitOtpRequested(
    SubmitOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Placeholder for consistency
  }

  Future<void> _onOnboardingRequested(
    OnboardingRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Step 1: Try to create or get the user
    String? userId;

    final signUpResult = await authRepository.signUp(
      email: event.email,
      password: event.password,
    );

    await signUpResult.fold(
      (failure) async {
        // If user already exists, try to sign in
        final msg = failure.message;
        final lMsg = msg.toLowerCase();
        if (lMsg.contains('email-already-in-use') ||
            lMsg.contains('already in use') ||
            lMsg.contains('already exists') ||
            lMsg.contains('email is already registered') ||
            (lMsg.contains('email') && lMsg.contains('already'))) {
          final signInResult = await authRepository.signIn(
            email: event.email,
            password: event.password,
          );
          await signInResult.fold((signInFailure) async {
            emit(AuthError(signInFailure.message));
          }, (uid) async => userId = uid);
        } else {
          emit(AuthError(failure.message));
        }
      },
      (uid) {
        userId = uid;
      },
    );

    if (userId == null) {
      if (state is! AuthError) {
        emit(const AuthError("Authentication failed during onboarding"));
      }
      return;
    }

    // Step 2: Check if this user was already invited as a staff member
    final profileSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .orderByChild('email')
        .equalTo(event.email)
        .get();

    String? existingStaffId;
    String? bossId;
    String? staffRole;
    String? staffShopId;
    
    if (profileSnapshot.value != null) {
      final data = profileSnapshot.value as Map<dynamic, dynamic>;
      final entry = data.entries.first;
      final userData = Map<String, dynamic>.from(entry.value as Map);
      
      final status = userData['status']?.toString().toLowerCase() ?? 'active';
      if (status == 'inactive') {
         emit(const AuthError("Your invitation is inactive. Please contact support."));
         return;
      }

      if (userData['role'] != 'owner') {
        existingStaffId = entry.key.toString();
        bossId = userData['ownerId'];
        staffRole = userData['role'];
        staffShopId = userData['shopId'] ?? '';
      }
    }

    if (existingStaffId != null) {
      // This is a staff member! 
      // MOVE their record to the new userId key for security rules natively
      final oldDataSnapshot = await FirebaseDatabase.instance.ref().child('users').child(existingStaffId).get();
      if (oldDataSnapshot.value != null) {
        final staffData = Map<String, dynamic>.from(oldDataSnapshot.value as Map);
        staffData['userId'] = userId;
        staffData['staffId'] = userId; // Update staffId to match UID natively
        staffData['updatedAt'] = ServerValue.timestamp;
        
        // 1. Write to new UID key
        await FirebaseDatabase.instance.ref().child('users').child(userId!).set(staffData);
        
        // 2. Remove old push key
        await FirebaseDatabase.instance.ref().child('users').child(existingStaffId).remove();
      }
      
      _captureAndStoreFCMToken(userId!);
      _listenToUserStatus(userId!);
      emit(AuthAuthenticated(userId!, ownerId: bossId ?? '', name: event.name, role: staffRole ?? 'staff', shopId: staffShopId ?? ''));
      return;
    }

    // Step 3: Register as a NEW owner since no staff invitation was found
    final onboardingResult = await onboardingRepository.registerOwnerAndShop(
      ownerId: userId!,
      name: event.name,
      mobile: event.mobile,
      email: event.email,
      shopName: event.shopName,
      shopCategory: event.shopCategory,
      shopAddress: event.shopAddress,
    );

    await onboardingResult.fold(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (_) async {
        // Safe binding to profile natively
        final profile = await authRepository.getUserFullProfile(userId!);
        final ownerId = profile?['role'] == 'owner' ? userId! : (profile?['ownerId'] ?? '');
        final name = profile?['name'] ?? 'User';
        final role = profile?['role']?.toString().toLowerCase() ?? 'owner';
        final shopId = profile?['shopId'] ?? '';

        _captureAndStoreFCMToken(userId!);
        _listenToUserStatus(userId!);
        emit(AuthAuthenticated(userId!,
            ownerId: ownerId, name: name, role: role, shopId: shopId));
      },
    );
  }

  Future<void> _captureAndStoreFCMToken(String userId) async {
    try {
      final token = await NotificationService().getToken();
      if (token != null) {
        await authRepository.saveUserFcmToken(userId, token);
      }
    } catch (_) {
      // Fail silently if messaging is not fully initialized online
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(email: event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Instantly cancel own internal listeners natively
    _userStatusSubscription?.cancel();
    _userStatusSubscription = null;

    // 2. Trigger reset in all other domain BLoCs
    try {
      sl<ShopContextBloc>().add(ResetShopContext());
      sl<DashboardBloc>().add(ResetDashboard());
      sl<NotificationBloc>().add(ResetNotification());
      sl<CustomerBloc>().add(ResetCustomer());
      sl<ProductBloc>().add(ResetProduct());
      sl<StaffBloc>().add(ResetStaff());
    } catch (e) {
      // Ignore if some blocs are not yet registered
    }

    // 3. CRITICAL: Give BLoC events a small window to process cancellations 
    // before the underlying Firebase Auth session is terminated natively.
    await Future.delayed(const Duration(milliseconds: 300));

    await _shopRepository.clearSelectedShopId();
    await authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  void _listenToUserStatus(String userId) {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('status')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final status = event.snapshot.value.toString().toLowerCase();
        if (status == 'inactive') {
          add(SignOutRequested());
          // Optionally add an error message to the stream if needed, 
          // but SignOutRequested will emit AuthUnauthenticated.
        }
      }
    });
  }

  @override
  Future<void> close() {
    _userStatusSubscription?.cancel();
    return super.close();
  }
}

class _OtpSentInternal extends AuthEvent {
  final String verificationId;
  const _OtpSentInternal(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}

class _AuthErrorInternal extends AuthEvent {
  final String message;
  const _AuthErrorInternal(this.message);
  @override
  List<Object?> get props => [message];
}
