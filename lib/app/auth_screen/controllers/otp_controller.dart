// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
//
// class OtpController extends GetxController {
//   Rx<TextEditingController> otpController = TextEditingController().obs;
//
//   RxString countryCode = "".obs;
//   RxString phoneNumber = "".obs;
//   RxString verificationId = "".obs;
//   RxInt resendToken = 0.obs;
//   RxBool isLoading = true.obs;
//
//   @override
//   void onInit() {
//     getArgument();
//     super.onInit();
//   }
//
//   getArgument() async {
//     dynamic argumentData = Get.arguments;
//     if (argumentData != null) {
//       countryCode.value = argumentData['countryCode'];
//       phoneNumber.value = argumentData['phoneNumber'];
//       verificationId.value = argumentData['verificationId'];
//     }
//     isLoading.value = false;
//     update();
//   }
//
//   @override
//   void onClose() {
//     otpController.value.dispose();
//     super.onClose();
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
import 'package:jippymart_restaurant/service/merchant_otp_service.dart';

import '../../../utils/fire_store_utils.dart';
import 'login_controller.dart';

class OtpController extends GetxController {
  // ---------------------------------------------------------------------------
  // OTP Text Controller
  // ---------------------------------------------------------------------------

  final Rx<TextEditingController> otpController =
      TextEditingController().obs;

  // ---------------------------------------------------------------------------
  // Mobile Number
  // ---------------------------------------------------------------------------

  final RxString mobileNumber = ''.obs;

  // ---------------------------------------------------------------------------
  // User Type
  //
  // Mobile OTP login is currently ONLY for MERCHANT
  // ---------------------------------------------------------------------------

  final RxString userType = 'MERCHANT'.obs;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  final RxBool isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // OTP Expiry
  // ---------------------------------------------------------------------------

  final RxInt expiresInMinutes = 5.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    // Get arguments from PhoneNumberScreen
    final arguments = Get.arguments;

    if (arguments != null && arguments is Map) {
      mobileNumber.value =
          arguments['mobileNumber']?.toString() ?? '';

      userType.value =
          arguments['userType']?.toString() ?? 'MERCHANT';

      final expiry = arguments['expiresInMinutes'];

      if (expiry != null) {
        expiresInMinutes.value =
            int.tryParse(expiry.toString()) ?? 5;
      }
    }

    debugPrint('================================');
    debugPrint('[OtpController] Initialized');
    debugPrint('[OtpController] Mobile: ${mobileNumber.value}');
    debugPrint('[OtpController] User Type: ${userType.value}');
    debugPrint(
      '[OtpController] Expiry: ${expiresInMinutes.value} minutes',
    );
    debugPrint('================================');
  }

  // ---------------------------------------------------------------------------
  // Verify OTP
  // ---------------------------------------------------------------------------

  Future<void> verifyOtp() async {
    if (isLoading.value) {
      return;
    }

    final otp = otpController.value.text.trim();

    // -------------------------------------------------------------------------
    // Validation
    // -------------------------------------------------------------------------

    if (mobileNumber.value.isEmpty) {
      ShowToastDialog.showToast(
        'Mobile number is missing'.tr,
      );
      return;
    }

    if (otp.isEmpty) {
      ShowToastDialog.showToast(
        'Please enter OTP'.tr,
      );
      return;
    }

    if (otp.length != 6) {
      ShowToastDialog.showToast(
        'Please enter valid 6 digit OTP'.tr,
      );
      return;
    }

    // -------------------------------------------------------------------------
    // Start Loader
    // -------------------------------------------------------------------------

    isLoading.value = true;

    ShowToastDialog.showLoader(
      'Please wait...'.tr,
    );

    try {
      debugPrint('================================');
      debugPrint('[OTP Verify] Starting verification');
      debugPrint('[OTP Verify] Mobile: ${mobileNumber.value}');
      debugPrint('[OTP Verify] UserType: ${userType.value}');
      debugPrint('[OTP Verify] OTP: $otp');
      debugPrint('================================');

      // -----------------------------------------------------------------------
      // Verify OTP API
      // -----------------------------------------------------------------------

      final response =
      await FireStoreUtils.verifyLoginOtpForNumber(
        userType: userType.value,
        mobileNumber: mobileNumber.value,
        otp: otp,
      );

      debugPrint('================================');
      debugPrint('[OTP Verify] Response: $response');
      debugPrint('================================');

      // -----------------------------------------------------------------------
      // Check Response
      // -----------------------------------------------------------------------

      if (response == null) {
        ShowToastDialog.showToast(
          'Unable to verify OTP. Please try again.'.tr,
        );
        return;
      }

      // -----------------------------------------------------------------------
      // Check JWT
      // -----------------------------------------------------------------------

      final jwt =
      response['jwt']?.toString().trim();

      if (jwt == null || jwt.isEmpty) {
        ShowToastDialog.showToast(
          response['message']?.toString() ??
              'Invalid OTP'.tr,
        );

        return;
      }

      // -----------------------------------------------------------------------
      // OTP Verified Successfully
      // -----------------------------------------------------------------------

      debugPrint('================================');
      debugPrint('[OTP Verify] SUCCESS');
      debugPrint('[OTP Verify] JWT received');
      debugPrint(
        '[OTP Verify] User ID: ${response['userId']}',
      );
      debugPrint(
        '[OTP Verify] User Type: ${response['userType']}',
      );
      debugPrint(
        '[OTP Verify] Roles: ${response['roles']}',
      );
      debugPrint('================================');

      // -----------------------------------------------------------------------
      // Get LoginController
      // -----------------------------------------------------------------------

      LoginController loginController;

      if (Get.isRegistered<LoginController>()) {
        loginController =
            Get.find<LoginController>();
      } else {
        loginController =
            Get.put(LoginController());
      }

      // -----------------------------------------------------------------------
      // IMPORTANT
      //
      // Use SAME login success flow as Username + Password Login
      //
      // Merchant:
      // Profile
      // → PENDING / APPROVED
      // → Outlet Flow
      // → Dashboard
      //
      // Outlet:
      // Existing Username/Password Flow
      // -----------------------------------------------------------------------

      final success =
      await loginController.handleLoginSuccess(
        Map<String, dynamic>.from(response),
      );

      if (success) {
        debugPrint(
          '[OTP Verify] Login flow completed successfully',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[OTP Verify] Error: $e');
      debugPrint('[OTP Verify] StackTrace: $stackTrace');

      ShowToastDialog.showToast(
        'Unable to verify OTP. Please try again.'.tr,
      );
    } finally {
      isLoading.value = false;

      ShowToastDialog.closeLoader();
    }
  }

  // ---------------------------------------------------------------------------
  // Resend OTP
  // ---------------------------------------------------------------------------

  Future<void> resendOtp() async {
    if (isLoading.value) {
      return;
    }

    // -------------------------------------------------------------------------
    // Validation
    // -------------------------------------------------------------------------

    if (mobileNumber.value.isEmpty) {
      ShowToastDialog.showToast(
        'Mobile number is missing'.tr,
      );
      return;
    }

    isLoading.value = true;

    ShowToastDialog.showLoader(
      'Sending OTP...'.tr,
    );

    try {
      debugPrint('================================');
      debugPrint('[OTP Resend] Starting');
      debugPrint('[OTP Resend] Mobile: ${mobileNumber.value}');
      debugPrint('[OTP Resend] UserType: ${userType.value}');
      debugPrint('================================');

      // -----------------------------------------------------------------------
      // Resend OTP API
      // -----------------------------------------------------------------------

      final response =
      await FireStoreUtils.resendLoginOtpForNumber(
        userType: userType.value,
        mobileNumber: mobileNumber.value,
      );

      debugPrint('================================');
      debugPrint('[OTP Resend] Response: $response');
      debugPrint('================================');

      if (response == null) {
        ShowToastDialog.showToast(
          'Unable to resend OTP. Please try again.'.tr,
        );

        return;
      }

      // -----------------------------------------------------------------------
      // Check API Error
      // -----------------------------------------------------------------------

      if (response['success'] == false) {
        ShowToastDialog.showToast(
          response['message']?.toString() ??
              'Unable to resend OTP'.tr,
        );

        return;
      }

      // -----------------------------------------------------------------------
      // Update Expiry
      // -----------------------------------------------------------------------

      final expiry =
      response['expiresInMinutes'];

      if (expiry != null) {
        expiresInMinutes.value =
            int.tryParse(
              expiry.toString(),
            ) ??
                5;
      }

      // -----------------------------------------------------------------------
      // Clear Previous OTP
      // -----------------------------------------------------------------------

      otpController.value.clear();

      // -----------------------------------------------------------------------
      // Success
      // -----------------------------------------------------------------------

      ShowToastDialog.showToast(
        response['message']?.toString() ??
            'OTP sent successfully'.tr,
      );
    } catch (e, stackTrace) {
      debugPrint('[OTP Resend] Error: $e');
      debugPrint(
        '[OTP Resend] StackTrace: $stackTrace',
      );

      ShowToastDialog.showToast(
        'Unable to resend OTP. Please try again.'.tr,
      );
    } finally {
      isLoading.value = false;

      ShowToastDialog.closeLoader();
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    otpController.value.dispose();

    super.onClose();
  }
}