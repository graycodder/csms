import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/widgets/shop_edit_card.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopEditPageMobile extends StatelessWidget {
  final ShopEntity shop;
  final Function(String name, String shopAddress, String category, String phone)
  onSave;
  final VoidCallback onCancel;

  const ShopEditPageMobile({
    super.key,
    required this.shop,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Edit Business Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<ShopContextBloc, ShopContextState>(
        listener: (context, state) {
          if (state is ShopSelected && state.actionSuccessMessage != null) {
            LoadingOverlayHelper.hide();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccessMessage!),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is ShopContextError) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: ShopEditCard(shop: shop, onSave: onSave, onCancel: onCancel),
        ),
      ),
    );
  }
}
