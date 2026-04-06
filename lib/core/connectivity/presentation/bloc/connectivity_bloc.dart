import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;

  ConnectivityBloc({required Connectivity connectivity})
      : _connectivity = connectivity,
        super(ConnectivityChecking()) {
    on<MonitorConnectivity>(_onMonitorConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  Future<void> _onMonitorConnectivity(
    MonitorConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results, emit);

    // Subscribe to changes
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        add(ConnectivityChanged(results));
      },
    );
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    _updateStatus(event.results, emit);
  }

  void _updateStatus(List<ConnectivityResult> results, Emitter<ConnectivityState> emit) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      emit(ConnectivityOffline());
    } else {
      emit(ConnectivityOnline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
