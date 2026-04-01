import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/domain/usecases/get_business_report.dart';

// ─── Events ────────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportEvent {
  final String shopId;
  final String ownerId;
  final ReportFilter filter;
  final DateTime? referenceDate;
  const LoadReport({
    required this.shopId,
    required this.ownerId,
    this.filter = ReportFilter.daily,
    this.referenceDate,
  });
  @override
  List<Object?> get props => [shopId, ownerId, filter, referenceDate];
}

class ChangeReportFilter extends ReportEvent {
  final String shopId;
  final String ownerId;
  final ReportFilter filter;
  final DateTime? referenceDate;
  const ChangeReportFilter({
    required this.shopId,
    required this.ownerId,
    required this.filter,
    this.referenceDate,
  });
  @override
  List<Object?> get props => [shopId, ownerId, filter, referenceDate];
}

// ─── States ────────────────────────────────────────────────────────────────────

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {
  final ReportEntity? report;
  const ReportLoading({this.report});
  @override
  List<Object?> get props => [report];
}

class ReportLoaded extends ReportState {
  final ReportEntity report;
  const ReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ──────────────────────────────────────────────────────────────────────

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetBusinessReport getBusinessReport;

  ReportBloc({required this.getBusinessReport}) : super(ReportInitial()) {
    on<LoadReport>(_onLoadReport);
    on<ChangeReportFilter>(_onChangeReportFilter);
  }

  Future<void> _onLoadReport(LoadReport event, Emitter<ReportState> emit) async {
    final currentState = state;
    if (currentState is ReportLoaded) {
      emit(ReportLoading(report: currentState.report));
    } else {
      emit(const ReportLoading());
    }
    
    final result = await getBusinessReport(
      shopId: event.shopId,
      ownerId: event.ownerId,
      filter: event.filter,
      referenceDate: event.referenceDate,
    );
    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onChangeReportFilter(
    ChangeReportFilter event,
    Emitter<ReportState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReportLoaded) {
      emit(ReportLoading(report: currentState.report));
    } else {
      emit(const ReportLoading());
    }

    final result = await getBusinessReport(
      shopId: event.shopId,
      ownerId: event.ownerId,
      filter: event.filter,
      referenceDate: event.referenceDate,
    );
    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }
}
