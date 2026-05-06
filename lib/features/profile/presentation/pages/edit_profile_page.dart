import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../domain/entities/profile_entity.dart';
import 'edit_profile_page_mobile.dart';
import 'edit_profile_page_web.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileEntity profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final updatedProfile = widget.profile.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      updatedAt: DateTime.now(),
    );
    context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProfileBloc>(),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context, true);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return ResponsiveLayout(
            mobile: EditProfilePageMobile(
              profile: widget.profile,
              state: state,
              nameController: _nameController,
              phoneController: _phoneController,
              onSave: () => _onSave(context),
            ),
            web: EditProfilePageWeb(
              profile: widget.profile,
              state: state,
              nameController: _nameController,
              phoneController: _phoneController,
              onSave: () => _onSave(context),
            ),
          );
        },
      ),
    );
  }
}
