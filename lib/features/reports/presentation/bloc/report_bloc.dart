import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/domain/usecases/get_business_report.dart';

// ─── Events ────────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportEvent {
  final DashboardLoaded dashboardState;
  final ReportFilter filter;
  const LoadReport(this.dashboardState, {this.filter = ReportFilter.allTime});
  @override
  List<Object?> get props => [dashboardState, filter];
}

class ChangeReportFilter extends ReportEvent {
  final DashboardLoaded dashboardState;
  final ReportFilter filter;
  const ChangeReportFilter({required this.dashboardState, required this.filter});
  @override
  List<Object?> get props => [dashboardState, filter];
}

// ─── States ────────────────────────────────────────────────────────────────────

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoaded extends ReportState {
  final ReportEntity report;
  const ReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

// ─── Bloc ──────────────────────────────────────────────────────────────────────

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetBusinessReport getBusinessReport;

  ReportBloc({required this.getBusinessReport}) : super(ReportInitial()) {
    on<LoadReport>(_onLoadReport);
    on<ChangeReportFilter>(_onChangeReportFilter);
  }

  void _onLoadReport(LoadReport event, Emitter<ReportState> emit) {
    final report = getBusinessReport(event.dashboardState, filter: event.filter);
    emit(ReportLoaded(report));
  }

  void _onChangeReportFilter(ChangeReportFilter event, Emitter<ReportState> emit) {
    final report = getBusinessReport(event.dashboardState, filter: event.filter);
    emit(ReportLoaded(report));
  }
}
