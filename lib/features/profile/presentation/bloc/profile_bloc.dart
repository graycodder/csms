import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      final result = await repository.getProfile(event.userId);
      result.fold(
        (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
        (profile) => emit(ProfileLoaded(profile)),
      );
    });

    on<UpdateProfile>((event, emit) async {
      emit(ProfileLoading());
      final result = await repository.updateProfile(event.profile);
      result.fold(
        (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
        (_) => emit(ProfileUpdateSuccess()),
      );
    });
  }

  String _mapFailureToMessage(dynamic failure) {
    return failure.toString();
  }
}
