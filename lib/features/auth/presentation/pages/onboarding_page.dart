import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_event.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/pages/shop_selection_page.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _shopNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0: Shop Details, 1: Account Details
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _shopNameController.dispose();
    _categoryController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _currentStep = 1);
    }
  }

  void _onComplete() {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please verify your details before proceeding:', style: TextStyle(fontSize: 14.sp, color: AppColors.textLight)),
              SizedBox(height: 16.h),
              _buildSummaryItem('Business Name', _shopNameController.text),
              _buildSummaryItem('Owner Name', _nameController.text),
              _buildSummaryItem('Email', _emailController.text.trim()),
              _buildSummaryItem('Contact', _shopPhoneController.text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Edit', style: TextStyle(color: AppColors.textLight, fontSize: 14.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(
                      OnboardingRequested(
                        ownerId: "",
                        name: _nameController.text,
                        mobile: _shopPhoneController.text,
                        email: _emailController.text.trim(),
                        shopName: _shopNameController.text,
                        shopCategory: _categoryController.text,
                        shopAddress: _shopAddressController.text,
                        password: _passwordController.text,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: const Text('Confirm & Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.textDark, fontSize: 14.sp),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            LoadingOverlayHelper.show(context);
          } else if (state is AuthAuthenticated) {
            LoadingOverlayHelper.hide();
            context.read<ShopContextBloc>().add(
                  LoadShops(
                    ownerId: state.ownerId,
                    shopId: state.shopId,
                    role: state.role,
                  ),
                );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ShopSelectionPage()),
            );
          } else if (state is AuthError) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 32.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildCurrentStep(state),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    String title = "Create Your Business";
    String subtitle = "Enter your business and account details";

    if (_currentStep == 1) {
      title = "Create Your Account";
      subtitle = "Step 2: Secure your business manager";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16.sp, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(AuthState state) {
    return Form(
      key: _formKey,
      child: _currentStep == 0 ? _buildShopStep(state) : _buildAccountStep(state),
    );
  }

  Widget _buildShopStep(AuthState state) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BUSINESS INFORMATION",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _shopNameController,
            maxLength: 20,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
            ],
            decoration: const InputDecoration(
              labelText: "Business Name *",
              prefixIcon: Icon(Icons.storefront_outlined),
              counterText: "",
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Business name is required';
              if (v.length > 20) return 'Max 20 characters';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _shopAddressController,
            maxLength: 40,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9,.\- ]')),
            ],
            decoration: const InputDecoration(
              labelText: "Business Address *",
              prefixIcon: Icon(Icons.location_on_outlined),
              counterText: "",
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Business address is required';
              if (v.length > 40) return 'Max 40 characters';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<String>(
            value: _categoryController.text.isEmpty ? null : _categoryController.text,
            decoration: const InputDecoration(
              labelText: "Category *",
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: TerminologyHelper.categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _categoryController.text = value ?? '';
              });
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Category is required';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _shopPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: "Business Contact Number *",
              prefixIcon: Icon(Icons.phone_outlined),
              counterText: "",
              hintText: "10-digit number",
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Contact number is required';
              if (v.length != 10) return 'Must be exactly 10 digits';
              return null;
            },
          ),
          SizedBox(height: 48.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
              child: Text(
                "Next",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountStep(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ACCOUNT INFORMATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _nameController,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          ],
          decoration: const InputDecoration(
            labelText: "Full Name *",
            prefixIcon: Icon(Icons.person_outline),
            counterText: "",
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Name is required';
            if (v.length > 20) return 'Max 20 characters';
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Email Address *",
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(v.trim())) return 'Invalid email format';
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password *",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFBDBDBD),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        SizedBox(height: 48.h),
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: _onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
            child: Text(
              "Complete Registration",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
