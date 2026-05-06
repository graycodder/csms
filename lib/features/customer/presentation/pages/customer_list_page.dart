import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'customer_list_page_mobile.dart';
import 'customer_list_page_web.dart';

class CustomerListPage extends StatelessWidget {
  final BusinessTerminology term;
  final VoidCallback onReturn;

  const CustomerListPage({
    super.key,
    required this.term,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardLoading) {
          LoadingOverlayHelper.show(context);
        } else {
          LoadingOverlayHelper.hide();
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return Material(
              type: MaterialType.transparency,
              child: ResponsiveLayout(
                mobile: CustomerListPageMobile(
                  term: term,
                  onReturn: onReturn,
                  state: state,
                ),
                web: CustomerListPageWeb(
                  term: term,
                  onReturn: onReturn,
                  state: state,
                ),
                breakpoint: 800,
              ),
            );
          } else if (state is DashboardLoading && state.lastLoadedState != null) {
            return Material(
              type: MaterialType.transparency,
              child: ResponsiveLayout(
                mobile: CustomerListPageMobile(
                  term: term,
                  onReturn: onReturn,
                  state: state.lastLoadedState!,
                ),
                web: CustomerListPageWeb(
                  term: term,
                  onReturn: onReturn,
                  state: state.lastLoadedState!,
                ),
                breakpoint: 800,
              ),
            );
          } else if (state is DashboardError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text(state.message)),
            );
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
