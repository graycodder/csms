import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'forgot_password_page_mobile.dart';
import 'forgot_password_page_web.dart';

class ForgotPasswordPage extends StatelessWidget {
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || MediaQuery.of(context).size.width > 600) {
      return ForgotPasswordPageWeb(initialEmail: initialEmail);
    }
    return ForgotPasswordPageMobile(initialEmail: initialEmail);
  }
}
