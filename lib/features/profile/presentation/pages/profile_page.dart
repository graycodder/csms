import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'profile_page_mobile.dart';
import 'profile_page_web.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProfileBloc>()..add(LoadProfile(userId)),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Scaffold(body: LoadingOverlay());
          } else if (state is ProfileLoaded) {
            return ResponsiveLayout(
              mobile: ProfilePageMobile(userId: userId, state: state),
              web: ProfilePageWeb(userId: userId, state: state),
              breakpoint: 800,
            );
          } else if (state is ProfileError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ProfileBloc>().add(LoadProfile(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    );
  }
}
