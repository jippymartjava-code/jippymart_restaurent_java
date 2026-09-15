import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_restaurant/app/auth_screen/screens/phone_number_screen.dart';
import 'package:provider/provider.dart';
import 'package:jippymart_restaurant/app/auth_screen/screens/signup_screen.dart';
import 'package:jippymart_restaurant/app/forgot_password_screen/forgot_password_screen.dart';
import 'package:jippymart_restaurant/app/auth_screen/controllers/login_controller.dart';
import 'package:jippymart_restaurant/themes/app_them_data.dart';
import 'package:jippymart_restaurant/themes/round_button_fill.dart';
import 'package:jippymart_restaurant/themes/text_field_widget.dart';
import 'package:jippymart_restaurant/utils/dark_theme_provider.dart';

import '../../terms_and_condition/terms_and_condition_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange =
    Provider.of<DarkThemeProvider>(context);

    return GetBuilder<LoginController>(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.surfaceDark
                : AppThemeData.surface,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      'Restaurant Partner Login'.tr,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontSize: 22,
                        fontFamily:
                        AppThemeData.semiBold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Log in to manage your restaurant account, '
                          'accept orders, and handle reservations.'.tr,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey400
                            : AppThemeData.grey500,
                        fontSize: 16,
                        fontFamily:
                        AppThemeData.regular,
                      ),
                    ),

                    const SizedBox(height: 20),

// Username
                    TextFieldWidget(
                      title: 'Username'.tr,
                      controller:
                      controller.usernameController,
                      hintText: 'Enter userName'.tr,
                      prefix: Padding(
                        padding:
                        const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/ic_mail.svg',
                          colorFilter:
                          ColorFilter.mode(
                            themeChange.getThem()
                                ? AppThemeData.grey300
                                : AppThemeData.grey600,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

// Password
                    Obx(
                          () => TextFieldWidget(
                        title: 'Password'.tr,
                        controller:
                        controller.passwordController,
                        hintText: 'Enter Password'.tr,
                        obscureText:
                        controller.passwordVisible.value,
                        prefix: Padding(
                          padding:
                          const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/icons/ic_lock.svg',
                            colorFilter:
                            ColorFilter.mode(
                              themeChange.getThem()
                                  ? AppThemeData.grey300
                                  : AppThemeData.grey600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        suffix: Padding(
                          padding:
                          const EdgeInsets.all(12),
                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(20),
                            onTap: () {
                              controller
                                  .passwordVisible
                                  .value =
                              !controller
                                  .passwordVisible
                                  .value;
                            },
                            child: SvgPicture.asset(
                              controller
                                  .passwordVisible
                                  .value
                                  ? 'assets/icons/ic_password_close.svg'
                                  : 'assets/icons/ic_password_show.svg',
                              colorFilter:
                              ColorFilter.mode(
                                themeChange.getThem()
                                    ? AppThemeData.grey300
                                    : AppThemeData.grey600,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

// Forgot password
                    Align(
                      alignment:
                      Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Get.to(
                            const ForgotPasswordScreen(),
                          );
                        },
                        child: Text(
                          'Forgot Password'.tr,
                          style: TextStyle(
                            decoration:
                            TextDecoration.underline,
                            decorationColor:
                            AppThemeData.secondary300,
                            color:
                            AppThemeData.secondary300,
                            fontSize: 14,
                            fontFamily:
                            AppThemeData.regular,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

// Login
                    Obx(
                          () => RoundedButtonFill(
                        title: controller.isLoading.value
                            ? 'Please wait...'.tr
                            : 'Login'.tr,
                        color:
                        AppThemeData.secondary300,
                        textColor:
                        AppThemeData.grey50,
                        onPress:
                        controller.isLoading.value
                            ? null
                            : controller
                            .loginWithUserNameAndPassword,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: themeChange.getThem()
                                ? AppThemeData.grey700
                                : AppThemeData.grey300,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR".tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: themeChange.getThem()
                                ? AppThemeData.grey700
                                : AppThemeData.grey300,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    OutlinedButton(
                      onPressed: () {
                        Get.to(
                          const PhoneNumberScreen(),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          54,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        side:  BorderSide(
                          color: AppThemeData.secondary300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android_outlined,
                            color: AppThemeData.secondary300,
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "Login with Mobile Number".tr,
                            style: TextStyle(
                              color: AppThemeData.secondary300,
                              fontSize: 15,
                              fontFamily: AppThemeData.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical:
                Platform.isAndroid ? 30 : 20,
                horizontal: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
// Sign up
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                          'Didn’t have an account?'.tr,
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily:
                            AppThemeData.medium,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 10),
                        ),
                        TextSpan(
                          text: 'Sign up'.tr,
                          recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(
                                //const SignupScreen(),
                                const EmailVerificationScreen()
                              );
                            },
                          style: TextStyle(
                            color:
                            AppThemeData.secondary300,
                            fontFamily:
                            AppThemeData.bold,
                            fontWeight:
                            FontWeight.w500,
                            decoration:
                            TextDecoration.underline,
                            decorationColor:
                            AppThemeData.secondary300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

// Terms + Privacy
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      _BottomAction(
                        icon:
                        'assets/icons/ic_terms_condition.svg',
                        title:
                        'Terms and Conditions'.tr,
                        isDark:
                        themeChange.getThem(),
                        onTap: () {
                          Get.to(
                            const TermsAndConditionScreen(
                              type: 'termAndCondition',
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 20),

                      _BottomAction(
                        icon:
                        'assets/icons/ic_privacyPolicy.svg',
                        title: 'Privacy Policy'.tr,
                        isDark:
                        themeChange.getThem(),
                        onTap: () {
                          Get.to(
                            const TermsAndConditionScreen(
                              type: 'privacy',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomAction extends StatelessWidget {
  final String icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: ShapeDecoration(
              color: isDark
                  ? AppThemeData.grey800
                  : AppThemeData.grey100,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(120),
              ),
            ),
            child: Padding(
              padding:
              const EdgeInsets.all(10),
              child: SvgPicture.asset(
                icon,
                colorFilter:
                ColorFilter.mode(
                  isDark
                      ? AppThemeData.grey300
                      : AppThemeData.grey600,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppThemeData.grey50
                  : AppThemeData.grey900,
              fontFamily:
              AppThemeData.medium,
            ),
          ),
        ],
      ),
    );
  }
}