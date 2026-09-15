// import 'dart:io';
//
//
// import 'package:flutter/services.dart';
// import 'package:jippymart_restaurant/app/auth_screen/signup_screen.dart';
// import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
// import 'package:jippymart_restaurant/controller/phone_number_controller.dart';
// import 'package:jippymart_restaurant/themes/app_them_data.dart';
// import 'package:jippymart_restaurant/themes/round_button_fill.dart';
// import 'package:jippymart_restaurant/themes/text_field_widget.dart';
// import 'package:jippymart_restaurant/utils/dark_theme_provider.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// class PhoneNumberScreen extends StatelessWidget {
//   const PhoneNumberScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetX(
//         init: PhoneNumberController(),
//         builder: (controller) {
//           return Scaffold(
//             appBar: AppBar(
//               backgroundColor: themeChange.getThem()
//                   ? AppThemeData.surfaceDark
//                   : AppThemeData.surface,
//             ),
//             body: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Welcome Back! 👋".tr,
//                     style: TextStyle(
//                         color: themeChange.getThem()
//                             ? AppThemeData.grey50
//                             : AppThemeData.grey900,
//                         fontSize: 22,
//                         fontFamily: AppThemeData.semiBold),
//                   ),
//                   Text(
//                     "Log in to continue enjoying delicious food delivered to your doorstep."
//                         .tr,
//                     style: TextStyle(
//                         color: themeChange.getThem()
//                             ? AppThemeData.grey400
//                             : AppThemeData.grey500,
//                         fontSize: 16,
//                         fontFamily: AppThemeData.regular),
//                   ),
//                   const SizedBox(
//                     height: 32,
//                   ),
//                   TextFieldWidget(
//                     title: 'Phone Number'.tr,
//                     controller: controller.phoneNUmberEditingController.value,
//                     hintText: 'Enter Phone Number'.tr,
//                     textInputType: const TextInputType.numberWithOptions(
//                         signed: true, decimal: true),
//                     textInputAction: TextInputAction.done,
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp('[0-9]')),
//                     ],
//                     prefix: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             '🇮🇳',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '+91',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey50
//                                   : AppThemeData.grey900,
//                               fontFamily: AppThemeData.medium,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 36,
//                   ),
//                   RoundedButtonFill(
//                     title: "Send OTP".tr,
//                     color: AppThemeData.secondary300,
//                     textColor: AppThemeData.grey50,
//                     onPress: () async {
//                       if (controller
//                           .phoneNUmberEditingController.value.text.isEmpty) {
//                         ShowToastDialog.showToast(
//                             "Please enter mobile number".tr);
//                       } else {
//                         controller.sendCode();
//                       }
//                     },
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 40),
//                     child: Row(
//                       children: [
//                         const Expanded(child: Divider(thickness: 1)),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 30),
//                           child: Text(
//                             "or".tr,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey500
//                                   : AppThemeData.grey400,
//                               fontSize: 16,
//                               fontFamily: AppThemeData.medium,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const Expanded(child: Divider()),
//                       ],
//                     ),
//                   ),
//                   RoundedButtonFill(
//                     title: "Continue with Email".tr,
//                     color: themeChange.getThem()
//                         ? AppThemeData.grey700
//                         : AppThemeData.grey200,
//                     textColor: themeChange.getThem()
//                         ? AppThemeData.grey50
//                         : AppThemeData.grey900,
//                     onPress: () async {
//                       Get.back();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             bottomNavigationBar: Padding(
//               padding:
//                   EdgeInsets.symmetric(vertical: Platform.isAndroid ? 10 : 30),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text.rich(
//                     TextSpan(
//                       children: [
//                         TextSpan(
//                             text: 'Didn’t have an account?'.tr,
//                             style: TextStyle(
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey50
//                                   : AppThemeData.grey900,
//                               fontFamily: AppThemeData.medium,
//                               fontWeight: FontWeight.w500,
//                             )),
//                         const WidgetSpan(
//                             child: SizedBox(
//                           width: 10,
//                         )),
//                         TextSpan(
//                             recognizer: TapGestureRecognizer()
//                               ..onTap = () {
//                                 Get.to(const SignupScreen());
//                               },f
//                             text: 'Sign up'.tr,
//                             style: TextStyle(
//                                 color: AppThemeData.secondary300,
//                                 fontFamily: AppThemeData.bold,
//                                 fontWeight: FontWeight.w500,
//                                 decoration: TextDecoration.underline,
//                                 decorationColor: AppThemeData.secondary300)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         });
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jippymart_restaurant/controller/phone_number_controller.dart';
import 'package:jippymart_restaurant/themes/app_them_data.dart';
import 'package:jippymart_restaurant/themes/round_button_fill.dart';
import 'package:jippymart_restaurant/themes/text_field_widget.dart';
import 'package:jippymart_restaurant/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PhoneNumberController>(
      init: PhoneNumberController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.surfaceDark
                : AppThemeData.surface,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Login with Mobile Number".tr,
                  style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey50
                        : AppThemeData.grey900,
                    fontSize: 22,
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Enter your mobile number to receive a verification code."
                      .tr,
                  style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey400
                        : AppThemeData.grey500,
                    fontSize: 16,
                    fontFamily: AppThemeData.regular,
                  ),
                ),

                const SizedBox(height: 32),

                TextFieldWidget(
                  title: 'Mobile Number'.tr,
                  controller:
                  controller.phoneNUmberEditingController.value,
                  hintText: 'Enter Mobile Number'.tr,
                  textInputType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp('[0-9]'),
                    ),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  prefix: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🇮🇳',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(width: 4),

                        Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                RoundedButtonFill(
                  title: "Send OTP".tr,
                  color: AppThemeData.secondary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    await controller.sendLoginOtp();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}