// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class PhoneNumberController extends GetxController {
//   Rx<TextEditingController> phoneNUmberEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> countryCodeEditingController =
//       TextEditingController().obs;
//   @override
//   void onInit() {
//     super.onInit();
//     countryCodeEditingController.value.text = '+91';
//   }
//
//   @override
//   void onClose() {
//     phoneNUmberEditingController.value.dispose();
//     countryCodeEditingController.value.dispose();
//     super.onClose();
//   }
//
//   // sendCode() async {
//   //   ShowToastDialog.showLoader("please wait...".tr);
//   //   await FirebaseAuth.instance
//   //       .verifyPhoneNumber(
//   //           phoneNumber: countryCodeEditingController.value.text +
//   //               phoneNUmberEditingController.value.text,
//   //           verificationCompleted: (PhoneAuthCredential credential) {},
//   //           verificationFailed: (FirebaseAuthException e) {
//   //             debugPrint("FirebaseAuthException--->${e.message}");
//   //             ShowToastDialog.closeLoader();
//   //             if (e.code == 'invalid-phone-number') {
//   //               ShowToastDialog.showToast("invalid_phone_number".tr);
//   //             } else {
//   //               ShowToastDialog.showToast(e.message);
//   //             }
//   //           },
//   //           codeSent: (String verificationId, int? resendToken) {
//   //             ShowToastDialog.closeLoader();
//   //             Get.to(const OtpScreen(), arguments: {
//   //               "countryCode": countryCodeEditingController.value.text,
//   //               "phoneNumber": phoneNUmberEditingController.value.text,
//   //               "verificationId": verificationId,
//   //             });
//   //           },
//   //           codeAutoRetrievalTimeout: (String verificationId) {})
//   //       .catchError((error) {
//   //     debugPrint("catchError--->$error");
//   //     ShowToastDialog.closeLoader();
//   //     ShowToastDialog.showToast("multiple_time_request".tr);
//   //   });
//   // }
// }




import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
import 'package:jippymart_restaurant/utils/fire_store_utils.dart';

import '../app/auth_screen/screens/otp_screen.dart';

class PhoneNumberController extends GetxController {
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;

  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController().obs;

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    countryCodeEditingController.value.text = '+91';
  }

  @override
  void onClose() {
    phoneNUmberEditingController.value.dispose();
    countryCodeEditingController.value.dispose();

    super.onClose();
  }

  Future<void> sendLoginOtp() async {
    final mobileNumber =
    phoneNUmberEditingController.value.text.trim();

    if (mobileNumber.isEmpty) {
      ShowToastDialog.showToast(
        "Please enter mobile number",
      );
      return;
    }

    if (mobileNumber.length != 10) {
      ShowToastDialog.showToast(
        "Please enter valid 10 digit mobile number",
      );
      return;
    }

    try {
      isLoading.value = true;

      ShowToastDialog.showLoader(
        "Please wait...",
      );

      final response =
      await FireStoreUtils.sendLoginOtpForNumber(
        userType: "MERCHANT",
        mobileNumber: mobileNumber,
      );

      ShowToastDialog.closeLoader();

      debugPrint(
        "Send OTP Response: $response",
      );

      if (response != null &&
          response["error"] != true) {
        ShowToastDialog.showToast(
          response["message"] ??
              "OTP sent successfully",
        );

        Get.to(
          const OtpScreen(),
          arguments: {
            "mobileNumber": mobileNumber,
            "userType": "MERCHANT",
          },
        );
      } else {
        ShowToastDialog.showToast(
          response?["message"] ??
              "Failed to send OTP",
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();

      debugPrint(
        "Send OTP Error: $e",
      );

      ShowToastDialog.showToast(
        "Something went wrong",
      );
    } finally {
      isLoading.value = false;
    }
  }
}