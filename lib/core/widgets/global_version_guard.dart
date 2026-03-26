import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/app_config/presentation/bloc/version_bloc.dart';
import 'package:csms/features/app_config/presentation/pages/force_update_page.dart';

class GlobalVersionGuard extends StatelessWidget {
  final Widget child;

  const GlobalVersionGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VersionBloc, VersionState>(
      builder: (context, state) {
        if (state is UpdateRequired) {
          return ForceUpdatePage(
            minVersion: state.minVersion,
            currentVersion: state.currentVersion,
            updateUrl: state.updateUrl,
          );
        }
        return child;
      },
    );
  }
}
