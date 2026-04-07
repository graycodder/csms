import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'package:csms/features/staff/domain/repositories/staff_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class StaffEvent extends Equatable {
  const StaffEvent();
  @override
  List<Object?> get props => [];
}

class LoadStaff extends StaffEvent {
  final String shopId;
  final String ownerId;
  const LoadStaff(this.shopId, this.ownerId);
  @override
  List<Object?> get props => [shopId, ownerId];
}

class AddStaff extends StaffEvent {
  final String shopId;
  final String ownerId;
  final StaffEntity staff;
  final String password;
  const AddStaff({
    required this.shopId,
    required this.ownerId,
    required this.staff,
    required this.password,
  });
  @override
  List<Object?> get props => [shopId, ownerId, staff, password];
}

class UpdateStaff extends StaffEvent {
  final String shopId;
  final String ownerId;
  final StaffEntity staff;
  const UpdateStaff({
    required this.shopId,
    required this.ownerId,
    required this.staff,
  });
  @override
  List<Object?> get props => [shopId, ownerId, staff];
}

class ToggleStaffStatus extends StaffEvent {
  final String shopId;
  final String ownerId;
  final StaffEntity staff;
  const ToggleStaffStatus({
    required this.shopId,
    required this.ownerId,
    required this.staff,
  });
  @override
  List<Object?> get props => [shopId, ownerId, staff];
}

class ResetStaff extends StaffEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class StaffState extends Equatable {
  const StaffState();
  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffOperationInProgress extends StaffState {}

class StaffLoaded extends StaffState {
  final List<StaffEntity> staffList;
  const StaffLoaded(this.staffList);
  @override
  List<Object?> get props => [staffList];
}

class StaffActionSuccess extends StaffLoaded {
  final String message;
  const StaffActionSuccess(this.message, List<StaffEntity> staffList)
    : super(staffList);
  @override
  List<Object?> get props => [message, staffList];
}

class StaffError extends StaffState {
  final String message;
  const StaffError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository repository;

  StaffBloc({required this.repository}) : super(StaffInitial()) {
    on<LoadStaff>(_onLoadStaff);
    on<AddStaff>(_onAddStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<ToggleStaffStatus>(_onToggleStaffStatus);
    on<ResetStaff>((event, emit) => emit(StaffInitial()));
  }

  Future<void> _onLoadStaff(LoadStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    await emit.forEach<StaffState>(
      repository.getStaff(event.shopId, event.ownerId).map((result) {
        return result.fold(
          (failure) => StaffError(failure.message),
          (staffList) => StaffLoaded(staffList),
        );
      }),
      onData: (state) => state,
    );
  }

  Future<void> _onAddStaff(AddStaff event, Emitter<StaffState> emit) async {
    final currentList =
        state is StaffLoaded ? (state as StaffLoaded).staffList : <StaffEntity>[];
    emit(StaffOperationInProgress());
    final result = await repository.addStaff(
      event.shopId,
      event.ownerId,
      event.staff,
      password: event.password,
    );
    result.fold(
      (failure) => emit(StaffError(failure.message)),
      (newId) {
        final newStaff = StaffEntity(
          staffId: newId,
          shopId: event.staff.shopId,
          ownerId: event.staff.ownerId,
          name: event.staff.name,
          phone: event.staff.phone,
          email: event.staff.email,
          role: event.staff.role,
          status: event.staff.status,
          createdAt: event.staff.createdAt,
        );
        final newList = List<StaffEntity>.from(currentList)..add(newStaff);
        newList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(StaffActionSuccess('Staff added successfully!', newList));
      },
    );
  }

  Future<void> _onUpdateStaff(
    UpdateStaff event,
    Emitter<StaffState> emit,
  ) async {
    final currentList =
        state is StaffLoaded ? (state as StaffLoaded).staffList : <StaffEntity>[];
    emit(StaffOperationInProgress());
    final result = await repository.updateStaff(
      event.shopId,
      event.ownerId,
      event.staff,
    );
    result.fold(
      (failure) => emit(StaffError(failure.message)),
      (_) {
        final newList = currentList
            .map((s) => s.staffId == event.staff.staffId ? event.staff : s)
            .toList();
        emit(StaffActionSuccess('Staff member updated successfully!', newList));
      },
    );
  }

  Future<void> _onToggleStaffStatus(
    ToggleStaffStatus event,
    Emitter<StaffState> emit,
  ) async {
    final currentList =
        state is StaffLoaded ? (state as StaffLoaded).staffList : <StaffEntity>[];

    emit(StaffOperationInProgress());
    final newStatus = event.staff.status == 'active' ? 'inactive' : 'active';
    final updatedStaff = StaffEntity(
      staffId: event.staff.staffId,
      shopId: event.staff.shopId,
      ownerId: event.staff.ownerId,
      name: event.staff.name,
      phone: event.staff.phone,
      email: event.staff.email,
      role: event.staff.role,
      status: newStatus,
      createdAt: event.staff.createdAt,
    );
    final result = await repository.updateStaff(
      event.shopId,
      event.ownerId,
      updatedStaff,
    );
    result.fold(
      (failure) => emit(StaffError(failure.message)),
      (_) {
        final newList = currentList
            .map((s) => s.staffId == event.staff.staffId ? updatedStaff : s)
            .toList();
        emit(StaffLoaded(newList));
      },
    );
  }
}
