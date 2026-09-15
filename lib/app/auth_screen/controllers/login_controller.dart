// import 'dart:convert';
// import 'package:jippymart_restaurant/app/dash_board_screens/dash_board_screen.dart';
// import 'package:jippymart_restaurant/app/landing_screen.dart';
// import 'package:jippymart_restaurant/app/verification_screen/verification_screen.dart';
// import 'package:jippymart_restaurant/constant/constant.dart';
// import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
// import 'package:jippymart_restaurant/service/audio_player_service.dart';
// import 'package:jippymart_restaurant/utils/fire_store_utils.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import '../../../utils/common.dart';
// import '../../../utils/preferences.dart' show Preferences;
// import '../../../controller/dash_board_controller.dart';
// import '../../../controller/merchant_outlet_controller.dart';
//
//
// class LoginController extends GetxController {
//   // ---------------------------------------------------------------------------
//   // Session Keys
//   // ---------------------------------------------------------------------------
//
//   static const String _keyIsLoggedIn = 'is_logged_in';
//   static const String _keyFirebaseId = 'firebase_id';
//   static const String _keyUserId = 'user_id';
//   static const String _keyUserIdInt = 'userId';
//   static const String _keyRole = 'role';
//   static const String _keyLoginType = 'loginType';
//   static const String _keyAuthToken = 'authToken';
//   static const String _keyMerchantId = 'merchantId';
//   static const String _keyOutletId = 'outletId';
//   static const String _keySelectedOutletId = 'selectedOutletId';
//   static const String _keySelectedOutletName = 'selectedOutletName';
//
//   // ---------------------------------------------------------------------------
//   // Controllers / State
//   // ---------------------------------------------------------------------------
//
//   final TextEditingController usernameController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   final RxBool passwordVisible = true.obs;
//   final RxBool isLoading = false.obs;
//
//   // ---------------------------------------------------------------------------
//   // Lifecycle
//   // ---------------------------------------------------------------------------
//
//   @override
//   void onClose() {
//     usernameController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }
//
//   // ---------------------------------------------------------------------------
//   // Login API
//   // ---------------------------------------------------------------------------
//
//   static Future<Map<String, dynamic>> loginWithUserNameAndPasswordApi({
//     required String username,
//     required String password,
//   }) async {
//     final response = await http.post(
//       Uri.parse('${Constant.baseUrl}fm/auth/login'),
//       headers: await getHeaders(),
//       body: jsonEncode({'username': username, 'password': password}),
//     );
//
//     debugPrint('[LoginApi] status=${response.statusCode}');
//
//     Map<String, dynamic>? responseData;
//
//     try {
//       final decoded = jsonDecode(response.body);
//
//       if (decoded is Map<String, dynamic>) {
//         responseData = decoded;
//       }
//     } catch (_) {
//       // Response was not valid JSON.
//     }
//
//     // Successful login.
//     if (response.statusCode >= 200 &&
//         response.statusCode < 300 &&
//         responseData != null) {
//       return responseData;
//     }
//
//     // Backend returned an error.
//     if (responseData != null) {
//       return {
//         'success': false,
//         'statusCode': response.statusCode,
//         'message': _getApiErrorMessage(response.statusCode, responseData),
//       };
//     }
//
//     // Invalid/non-JSON server response.
//     return {
//       'success': false,
//       'statusCode': response.statusCode,
//       'message': _getStatusMessage(response.statusCode),
//     };
//   }
//
//   static String _getApiErrorMessage(int statusCode,
//       Map<String, dynamic> response,) {
//     final backendMessage =
//         response['message'] ?? response['error'] ?? response['detail'];
//
//     if (backendMessage != null && backendMessage
//         .toString()
//         .trim()
//         .isNotEmpty) {
//       return backendMessage.toString();
//     }
//
//     return _getStatusMessage(statusCode);
//   }
//
//   static String _getStatusMessage(int statusCode) {
//     switch (statusCode) {
//       case 400:
//         return 'Invalid login request.';
//       case 401:
//         return 'Invalid username or password.';
//       case 403:
//         return 'You do not have permission to access this account.';
//       case 404:
//         return 'Login service not found.';
//       case 500:
//       case 502:
//       case 503:
//         return 'Server error. Please try again later.';
//       default:
//         return 'Login failed. Please try again.';
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Login
//   // ---------------------------------------------------------------------------
//
//   Future<void> loginWithUserNameAndPassword() async {
//     if (isLoading.value) {
//       return;
//     }
//
//     final username = usernameController.text.trim();
//     final password = passwordController.text.trim();
//
//     // ------------------------------------------------------------
//     // Validation
//     // ------------------------------------------------------------
//
//     if (username.isEmpty) {
//       ShowToastDialog.showToast(
//         'Please enter valid username'.tr,
//       );
//       return;
//     }
//
//     if (password.isEmpty) {
//       ShowToastDialog.showToast(
//         'Please enter valid password'.tr,
//       );
//       return;
//     }
//
//     isLoading.value = true;
//     ShowToastDialog.showLoader('Please wait.'.tr);
//
//     try {
//       // ----------------------------------------------------------
//       // STEP 1: Login API
//       // ----------------------------------------------------------
//
//       final response = await loginWithUserNameAndPasswordApi(
//         username: username,
//         password: password,
//       );
//
//       // ----------------------------------------------------------
//       // STEP 2: Check login response
//       // ----------------------------------------------------------
//
//       if (response['success'] == false) {
//         ShowToastDialog.showToast(
//           response['message'] ?? 'Login failed'.tr,
//         );
//         return;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 3: Get JWT token
//       // ----------------------------------------------------------
//
//       final token = response['jwt']?.toString().trim();
//
//       if (token == null || token.isEmpty) {
//         ShowToastDialog.showToast(
//           'Login failed. Authentication token missing.'.tr,
//         );
//         return;
//       }
//
//       debugPrint('[Login] JWT token received');
//
//       // ----------------------------------------------------------
//       // STEP 4: Get user information
//       // ----------------------------------------------------------
//
//       final userId = _parseInt(response['userId']) ?? 0;
//
//       final role = _getRole(response);
//
//       final loginType = _resolveLoginType(
//         role: role,
//         response: response,
//       );
//
//       debugPrint(
//         '[Login] '
//             'userId=$userId '
//             'role=$role '
//             'loginType=$loginType',
//       );
//
//       // ----------------------------------------------------------
//       // STEP 5: Validate login type
//       // ----------------------------------------------------------
//
//       if (loginType.isEmpty) {
//         await clearSession();
//
//         ShowToastDialog.showToast(
//           'Unknown user role'.tr,
//         );
//         return;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 6: SAVE TOKEN FIRST
//       //
//       // This MUST happen before getMerchantProfile()
//       // ----------------------------------------------------------
//
//       await _saveLoginSession(
//         userId: userId,
//         token: token,
//         role: role,
//         loginType: loginType,
//       );
//
//       debugPrint(
//         '[Login] Session/token saved successfully',
//       );
//
//       // ----------------------------------------------------------
//       // STEP 7: Now initialize Merchant / Outlet session
//       //
//       // getMerchantProfile() will now have access to authToken
//       // ----------------------------------------------------------
//
//       final sessionResult = await _initializeLoginSession(
//         loginType: loginType,
//         response: response,
//         userId: userId,
//         token: token,
//         role: role,
//       );
//
//       // ----------------------------------------------------------
//       // STEP 8: Check session initialization
//       // ----------------------------------------------------------
//
//       if (!sessionResult) {
//         await clearSession();
//
//         ShowToastDialog.showToast(
//           'Unable to initialize account. Please try again.'.tr,
//         );
//         return;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 9: Login successful
//       // ----------------------------------------------------------
//
//       ShowToastDialog.showToast(
//         'Login Successful'.tr,
//       );
//
//       // ----------------------------------------------------------
//       // STEP 10: Navigate to dashboard
//       // ----------------------------------------------------------
//
//       await _navigateToDashboard();
//     } catch (e, stackTrace) {
//       debugPrint('[Login] error=$e');
//       debugPrint('[Login] stackTrace=$stackTrace');
//
//       ShowToastDialog.showToast(
//         _getLoginErrorMessage(e),
//       );
//     } finally {
//       isLoading.value = false;
//       ShowToastDialog.closeLoader();
//     }
//   }
// // ---------------------------------------------------------------------------
// // Reusable Login Success
// //
// // Used by:
// // 1. Username + Password Login
// // 2. Merchant Mobile OTP Login
// // ---------------------------------------------------------------------------
//
//   Future<bool> handleLoginSuccess(
//       Map<String, dynamic> response,
//       ) async {
//     try {
//       debugPrint('========================================');
//       debugPrint('[LoginSuccess] Processing login response');
//       debugPrint('[LoginSuccess] $response');
//       debugPrint('========================================');
//
//       // ----------------------------------------------------------
//       // STEP 1: Check response
//       // ----------------------------------------------------------
//
//       if (response['success'] == false) {
//         ShowToastDialog.showToast(
//           response['message'] ?? 'Login failed'.tr,
//         );
//
//         return false;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 2: Get JWT token
//       // ----------------------------------------------------------
//
//       final token = response['jwt']?.toString().trim();
//
//       if (token == null || token.isEmpty) {
//         ShowToastDialog.showToast(
//           'Login failed. Authentication token missing.'.tr,
//         );
//
//         return false;
//       }
//
//       debugPrint('[LoginSuccess] JWT token received');
//
//       // ----------------------------------------------------------
//       // STEP 3: Get User ID
//       // ----------------------------------------------------------
//
//       final userId = _parseInt(response['userId']) ?? 0;
//
//       if (userId <= 0) {
//         ShowToastDialog.showToast(
//           'Login failed. User ID missing.'.tr,
//         );
//
//         return false;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 4: Get Role
//       // ----------------------------------------------------------
//
//       final role = _getRole(response);
//
//       // ----------------------------------------------------------
//       // STEP 5: Resolve Login Type
//       //
//       // MERCHANT
//       // OUTLET
//       // ----------------------------------------------------------
//
//       final loginType = _resolveLoginType(
//         role: role,
//         response: response,
//       );
//
//       debugPrint(
//         '[LoginSuccess] '
//             'userId=$userId '
//             'role=$role '
//             'loginType=$loginType',
//       );
//
//       // ----------------------------------------------------------
//       // STEP 6: Validate Login Type
//       // ----------------------------------------------------------
//
//       if (loginType.isEmpty) {
//         await clearSession();
//
//         ShowToastDialog.showToast(
//           'Unknown user role'.tr,
//         );
//
//         return false;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 7: Save Login Session
//       //
//       // JWT MUST be saved before profile API
//       // ----------------------------------------------------------
//
//       await _saveLoginSession(
//         userId: userId,
//         token: token,
//         role: role,
//         loginType: loginType,
//       );
//
//       debugPrint(
//         '[LoginSuccess] Session/token saved successfully',
//       );
//
//       // ----------------------------------------------------------
//       // STEP 8: Initialize Merchant / Outlet
//       // ----------------------------------------------------------
//
//       final sessionResult = await _initializeLoginSession(
//         loginType: loginType,
//         response: response,
//         userId: userId,
//         token: token,
//         role: role,
//       );
//
//       // ----------------------------------------------------------
//       // STEP 9: Check initialization
//       // ----------------------------------------------------------
//
//       if (!sessionResult) {
//         await clearSession();
//
//         ShowToastDialog.showToast(
//           'Unable to initialize account. Please try again.'.tr,
//         );
//
//         return false;
//       }
//
//       // ----------------------------------------------------------
//       // STEP 10: Navigate
//       //
//       // Merchant PENDING
//       //      ↓
//       // Verification Screen
//       //
//       // Approved
//       //      ↓
//       // Dashboard
//       // ----------------------------------------------------------
//
//       await _navigateToDashboard();
//
//       return true;
//     } catch (e, stackTrace) {
//       debugPrint('[LoginSuccess] error=$e');
//       debugPrint('[LoginSuccess] stackTrace=$stackTrace');
//
//       await clearSession();
//
//       ShowToastDialog.showToast(
//         _getLoginErrorMessage(e),
//       );
//
//       return false;
//     }
//   }
//   // ---------------------------------------------------------------------------
//   // Login Type
//   // ---------------------------------------------------------------------------
//
//   String _getRole(Map<String, dynamic> response) {
//     final roles = response['roles'];
//
//     if (roles is List && roles.isNotEmpty) {
//       return roles.first.toString();
//     }
//
//     return '';
//   }
//
//   String _resolveLoginType({
//     required String role,
//     required Map<String, dynamic> response,
//   }) {
//     if (role == 'ROLE_ADMIN' || role == 'ROLE_MERCHANT') {
//       return 'MERCHANT';
//     }
//
//     final outletId = response['outletId'];
//     final userType = response['userType']?.toString().toUpperCase();
//
//     if (role == 'ROLE_OUTLET' || outletId != null || userType == 'OUTLET') {
//       return 'OUTLET';
//     }
//
//     return '';
//   }
//
//   // ---------------------------------------------------------------------------
//   // Session Initialization
//   // ---------------------------------------------------------------------------
//
//   Future<bool> _initializeLoginSession({
//     required String loginType,
//     required Map<String, dynamic> response,
//     required int userId,
//     required String token,
//     required String role,
//   }) async {
//     switch (loginType) {
//       case 'MERCHANT':
//         return _initializeMerchantSession(response: response, userId: userId);
//
//       case 'OUTLET':
//         return _initializeOutletLoginSession(response: response);
//
//       default:
//         return false;
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Merchant Login
//   // ---------------------------------------------------------------------------
//
//   Future<bool> _initializeMerchantSession({
//     required Map<String, dynamic> response,
//     required int userId,
//   }) async {
//     final merchantId = _parseInt(response['merchantId']) ?? userId;
//
//     if (merchantId <= 0) {
//       debugPrint('[MerchantSession] Invalid merchantId=$merchantId');
//       return false;
//     }
//
//     await Preferences.setString(_keyMerchantId, merchantId.toString());
//
//     await Preferences.setInt(_keyOutletId, 0);
//
//     await Preferences.setInt(_keySelectedOutletId, 0);
//
//     await Preferences.setString(_keyLoginType, 'MERCHANT');
//
//     if (Get.isRegistered<MerchantOutletController>()) {
//       Get.delete<MerchantOutletController>(force: true);
//     }
//
//     final controller = Get.put(MerchantOutletController(), permanent: true);
//
//     await controller.initializeMerchantSession();
//
//     debugPrint(
//       '[MerchantSession] initialized '
//           'merchantId=$merchantId '
//           'outletCount=${controller.outletList.length}',
//     );
//
//     return true;
//   }
//
//   // ---------------------------------------------------------------------------
//   // Outlet Login
//   // ---------------------------------------------------------------------------
//
//   Future<bool> _initializeOutletLoginSession({
//     required Map<String, dynamic> response,
//   }) async {
//     final outletId =
//         _parseInt(response['outletId']) ??
//             _parseInt(response['id']) ??
//             _parseInt(response['userId']) ??
//             0;
//
//     if (outletId <= 0) {
//       debugPrint('[OutletSession] Missing outletId');
//
//       ShowToastDialog.showToast(
//         'Outlet ID missing from login. Please contact support.'.tr,
//       );
//
//       return false;
//     }
//
//     return _initializeOutletSession(outletId);
//   }
//
//   Future<bool> _initializeOutletSession(int outletId) async {
//     debugPrint('[OutletSession] Loading outletId=$outletId');
//
//     final result = await FireStoreUtils.fetchOutletById(outletId);
//
//     if (!result.hasMerchantId) {
//       debugPrint('[OutletSession] Failed: ${result.message}');
//
//       return false;
//     }
//
//     final merchantId = result.merchantId!;
//     final resolvedOutletId = result.outletId ?? outletId;
//
//     await Preferences.setInt(_keyOutletId, resolvedOutletId);
//
//     await Preferences.setInt(_keySelectedOutletId, resolvedOutletId);
//
//     await Preferences.setString(
//       _keySelectedOutletName,
//       result.outlet?.outletName ?? '',
//     );
//
//     await Preferences.setString(_keyLoginType, 'OUTLET');
//
//     await Preferences.setString(_keyMerchantId, merchantId.toString());
//
//     await MerchantOutletController.persistApprovalState(
//       result.outlet?.isApproved,
//     );
//
//     debugPrint(
//       '[OutletSession] '
//           'outletId=$resolvedOutletId '
//           'merchantId=$merchantId',
//     );
//
//     // Merchant profile is required by the existing dashboard flow.
//     try {
//       final profile = await FireStoreUtils.getMerchantProfile(
//         merchantId.toString(),
//       );
//
//       if (profile != null) {
//         Constant.merchantModel = profile;
//       } else {
//         debugPrint('[OutletSession] Merchant profile not found');
//       }
//     } catch (e) {
//       debugPrint('[OutletSession] Profile loading failed: $e');
//
//       // Keep existing behavior: profile failure is non-fatal.
//     }
//
//     return true;
//   }
//
//   // ---------------------------------------------------------------------------
//   // Persist Session
//   // ---------------------------------------------------------------------------
//
//   Future<void> _saveLoginSession({
//     required int userId,
//     required String token,
//     required String role,
//     required String loginType,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.setBool(_keyIsLoggedIn, true);
//
//     await prefs.setBool(Preferences.isFinishOnBoardingKey, true);
//
//     await prefs.setString(_keyFirebaseId, userId.toString());
//
//     await prefs.setString(_keyUserId, userId.toString());
//
//     await prefs.setInt(_keyUserIdInt, userId);
//
//     await prefs.setString(_keyRole, role);
//
//     await prefs.setString(_keyLoginType, loginType);
//
//     await prefs.setString(_keyAuthToken, token);
//   }
//
//   // ---------------------------------------------------------------------------
//   // Restore Session
//   // ---------------------------------------------------------------------------
//
//   Future<void> proceedToMainApp() async {
//     try {
//       final onboardingFinished = Preferences.getBoolean(
//         Preferences.isFinishOnBoardingKey,
//       );
//
//       if (!onboardingFinished) {
//         _goToLanding();
//         return;
//       }
//
//       /*
//        * Keep this check because the existing application still uses
//        * FireStoreUtils.isLogin() as part of its authentication state.
//        */
//       final firebaseLoggedIn = await FireStoreUtils.isLogin();
//
//       if (!firebaseLoggedIn) {
//         await clearSession();
//         _goToLanding();
//         return;
//       }
//
//       final authToken = Preferences.getString(_keyAuthToken);
//
//       final loginType = Preferences.getString(_keyLoginType);
//
//       if (authToken.isEmpty || loginType.isEmpty) {
//         await clearSession();
//         _goToLanding();
//         return;
//       }
//
//       switch (loginType) {
//         case 'MERCHANT':
//           await _restoreMerchantSession();
//           break;
//
//         case 'OUTLET':
//           await _restoreOutletSession();
//           break;
//
//         default:
//           await clearSession();
//           _goToLanding();
//           return;
//       }
//
//       await _goToDashboardOrVerification();
//     } catch (e, stackTrace) {
//       debugPrint('[SessionRestore] error=$e');
//       debugPrint('[SessionRestore] stackTrace=$stackTrace');
//
//       await clearSession();
//       _goToLanding();
//     }
//   }
//
//   Future<void> _restoreMerchantSession() async {
//     if (!Get.isRegistered<MerchantOutletController>()) {
//       Get.put(MerchantOutletController(), permanent: true);
//     }
//
//     await Get.find<MerchantOutletController>().initializeMerchantSession();
//   }
//
//   Future<void> _restoreOutletSession() async {
//     final merchantId = Preferences.getString(_keyMerchantId);
//
//     if (merchantId.isEmpty) {
//       throw Exception('Merchant ID missing for outlet session');
//     }
//
//     final profile = await FireStoreUtils.getMerchantProfile(merchantId);
//
//     if (profile != null) {
//       Constant.merchantModel = profile;
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Dashboard
//   // ---------------------------------------------------------------------------
//
//   Future<void> _navigateToDashboard() async {
//     await _goToDashboardOrVerification();
//   }
//
//   /// True when the current merchant/outlet is approved by the backend.
//   /// Fails open (returns true) so a fetch error never locks a user out.
//   Future<bool> _isSessionApproved() async {
//     final loginType = Preferences.getString(_keyLoginType);
//     try {
//       if (loginType == 'OUTLET') {
//         final outletId = Preferences.getInt(_keyOutletId) > 0
//             ? Preferences.getInt(_keyOutletId)
//             : Preferences.getInt(_keySelectedOutletId);
//         if (outletId <= 0) return true;
//         final result = await FireStoreUtils.fetchOutletById(outletId);
//         return result.outlet?.isApproved ?? true;
//       }
//
//       if (Get.isRegistered<MerchantOutletController>()) {
//         final profile = Get.find<MerchantOutletController>()
//             .merchantProfile
//             .value;
//         if (profile != null) return profile.isApproved ?? true;
//       }
//       return true;
//     } catch (e, stackTrace) {
//       debugPrint('[Session] approval check failed: $e');
//       debugPrint('$stackTrace');
//       return true;
//     }
//   }
//
//   /// Routes an unapproved merchant/outlet to the document-verification
//   /// screen and everyone else to the dashboard.
//   Future<void> _goToDashboardOrVerification() async {
//     final approved = await _isSessionApproved();
//     await MerchantOutletController.persistApprovalState(approved);
//
//     if (!approved) {
//       debugPrint('[Session] Not approved — showing verification screen');
//       Get.offAll(
//         () => const VerificationScreen(),
//         transition: Transition.fadeIn,
//         duration: const Duration(milliseconds: 400),
//       );
//       return;
//     }
//
//     if (Get.isRegistered<DashBoardController>()) {
//       Get.delete<DashBoardController>(force: true);
//     }
//
//     _goToDashboard();
//   }
//
//   void _goToDashboard() {
//     Get.offAll(
//           () => const DashBoardScreen(),
//       transition: Transition.fadeIn,
//       duration: const Duration(milliseconds: 500),
//     );
//   }
//
//   void _goToLanding() {
//     Get.offAll(() => const LandingScreen());
//   }
//
//   // ---------------------------------------------------------------------------
//   // Logout
//   // ---------------------------------------------------------------------------
//
//   Future<void> logoutFunction() async {
//     try {
//       await AudioPlayerService.playSound(false);
//
//       if (Constant.userModel != null) {
//         try {
//           Constant.userModel!.fcmToken = '';
//
//           await FireStoreUtils.updateUser(Constant.userModel!);
//         } catch (e) {
//           debugPrint('[Logout] FCM update failed: $e');
//         }
//       }
//     } finally {
//       Constant.userModel = null;
//
//       _disposeSessionControllers();
//
//       await clearSession();
//
//       _goToLanding();
//     }
//   }
//
//   void _disposeSessionControllers() {
//     if (Get.isRegistered<MerchantOutletController>()) {
//       Get.delete<MerchantOutletController>(force: true);
//     }
//
//     if (Get.isRegistered<DashBoardController>()) {
//       Get.delete<DashBoardController>(force: true);
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // Clear Session
//   // ---------------------------------------------------------------------------
//
//   Future<void> clearSession() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.remove(_keyFirebaseId);
//     await prefs.remove(_keyUserId);
//     await prefs.remove(_keyUserIdInt);
//     await prefs.remove(_keyRole);
//     await prefs.remove(_keyAuthToken);
//     await prefs.remove(_keyMerchantId);
//     await prefs.remove(_keyOutletId);
//     await prefs.remove(_keySelectedOutletId);
//     await prefs.remove(_keySelectedOutletName);
//     await prefs.remove(_keyLoginType);
//
//     await prefs.setBool(_keyIsLoggedIn, false);
//   }
//
//   // ---------------------------------------------------------------------------
//   // Helpers
//   // ---------------------------------------------------------------------------
//
//   int? _parseInt(dynamic value) {
//     if (value == null) {
//       return null;
//     }
//
//     if (value is int) {
//       return value;
//     }
//
//     return int.tryParse(value.toString());
//   }
//
//   String _getLoginErrorMessage(Object error) {
//     if (error is http.ClientException) {
//       return 'Unable to connect to server. Please check your internet connection.';
//     }
//
//     return 'Login failed. Please try again.';
//   }
//
// }



import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jippymart_restaurant/app/dash_board_screens/dash_board_screen.dart';
import 'package:jippymart_restaurant/app/landing_screen.dart';
import 'package:jippymart_restaurant/app/verification_screen/verification_screen.dart';
import 'package:jippymart_restaurant/constant/constant.dart';
import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
import 'package:jippymart_restaurant/service/audio_player_service.dart';
import 'package:jippymart_restaurant/utils/fire_store_utils.dart';

import '../../../utils/common.dart';
import '../../../utils/preferences.dart' show Preferences;
import '../../../controller/dash_board_controller.dart';
import '../../../controller/merchant_outlet_controller.dart';

class LoginController extends GetxController {
  // ---------------------------------------------------------------------------
  // Session Keys
  // ---------------------------------------------------------------------------

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFirebaseId = 'firebase_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUserIdInt = 'userId';
  static const String _keyRole = 'role';
  static const String _keyLoginType = 'loginType';
  static const String _keyAuthToken = 'authToken';
  static const String _keyMerchantId = 'merchantId';
  static const String _keyOutletId = 'outletId';
  static const String _keySelectedOutletId = 'selectedOutletId';
  static const String _keySelectedOutletName = 'selectedOutletName';

  // ---------------------------------------------------------------------------
  // Controllers / State
  // ---------------------------------------------------------------------------

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool passwordVisible = true.obs;
  final RxBool isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Login API
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> loginWithUserNameAndPasswordApi({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${Constant.baseUrl}fm/auth/login'),
      headers: await getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    debugPrint('[LoginApi] status=${response.statusCode}');

    Map<String, dynamic>? responseData;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      }
    } catch (_) {
      // Response was not valid JSON.
    }

    // Successful login.
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        responseData != null) {
      return responseData;
    }

    // Backend returned an error.
    if (responseData != null) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': _getApiErrorMessage(
          response.statusCode,
          responseData,
        ),
      };
    }

    // Invalid/non-JSON server response.
    return {
      'success': false,
      'statusCode': response.statusCode,
      'message': _getStatusMessage(response.statusCode),
    };
  }

  static String _getApiErrorMessage(
      int statusCode,
      Map<String, dynamic> response,
      ) {
    final backendMessage =
        response['message'] ??
            response['error'] ??
            response['detail'];

    if (backendMessage != null &&
        backendMessage.toString().trim().isNotEmpty) {
      return backendMessage.toString();
    }

    return _getStatusMessage(statusCode);
  }

  static String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid login request.';

      case 401:
        return 'Invalid username or password.';

      case 403:
        return 'You do not have permission to access this account.';

      case 404:
        return 'Login service not found.';

      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';

      default:
        return 'Login failed. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Username + Password Login
  // ---------------------------------------------------------------------------

  Future<void> loginWithUserNameAndPassword() async {
    if (isLoading.value) {
      return;
    }

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // ------------------------------------------------------------
    // Validation
    // ------------------------------------------------------------

    if (username.isEmpty) {
      ShowToastDialog.showToast(
        'Please enter valid username'.tr,
      );
      return;
    }

    if (password.isEmpty) {
      ShowToastDialog.showToast(
        'Please enter valid password'.tr,
      );
      return;
    }

    isLoading.value = true;

    ShowToastDialog.showLoader(
      'Please wait.'.tr,
    );

    try {
      // ----------------------------------------------------------
      // STEP 1: Login API
      // ----------------------------------------------------------

      final response =
      await loginWithUserNameAndPasswordApi(
        username: username,
        password: password,
      );

      // ----------------------------------------------------------
      // STEP 2: Reusable Login Success Flow
      //
      // This same method is also used by Mobile OTP Login
      // ----------------------------------------------------------

      await handleLoginSuccess(response);
    } catch (e, stackTrace) {
      debugPrint('[Login] error=$e');
      debugPrint('[Login] stackTrace=$stackTrace');

      ShowToastDialog.showToast(
        _getLoginErrorMessage(e),
      );
    } finally {
      isLoading.value = false;

      ShowToastDialog.closeLoader();
    }
  }

  // ---------------------------------------------------------------------------
  // Reusable Login Success
  //
  // Used by:
  //
  // 1. Username + Password Login
  // 2. Merchant Mobile OTP Login
  //
  // This automatically handles:
  //
  // MERCHANT → Merchant Flow
  // OUTLET   → Outlet Flow
  // ---------------------------------------------------------------------------

  Future<bool> handleLoginSuccess(
      Map<String, dynamic> response,
      ) async {
    try {
      debugPrint('========================================');
      debugPrint('[LoginSuccess] Processing login response');
      debugPrint('[LoginSuccess] Response: $response');
      debugPrint('========================================');

      // ----------------------------------------------------------
      // STEP 1: Check Login Response
      // ----------------------------------------------------------

      if (response['success'] == false) {
        ShowToastDialog.showToast(
          response['message'] ?? 'Login failed'.tr,
        );

        return false;
      }

      // ----------------------------------------------------------
      // STEP 2: Get JWT Token
      // ----------------------------------------------------------

      final token = response['jwt']?.toString().trim();

      if (token == null || token.isEmpty) {
        ShowToastDialog.showToast(
          'Login failed. Authentication token missing.'.tr,
        );

        return false;
      }

      debugPrint('[LoginSuccess] JWT token received');

      // ----------------------------------------------------------
      // STEP 3: Get User ID
      // ----------------------------------------------------------

      final userId =
          _parseInt(response['userId']) ?? 0;

      if (userId <= 0) {
        ShowToastDialog.showToast(
          'Login failed. User ID missing.'.tr,
        );

        return false;
      }

      // ----------------------------------------------------------
      // STEP 4: Get Role
      // ----------------------------------------------------------

      final role = _getRole(response);

      // ----------------------------------------------------------
      // STEP 5: Resolve Login Type
      //
      // MERCHANT
      // OUTLET
      // ----------------------------------------------------------

      final loginType = _resolveLoginType(
        role: role,
        response: response,
      );

      debugPrint(
        '[LoginSuccess] '
            'userId=$userId '
            'role=$role '
            'loginType=$loginType',
      );

      // ----------------------------------------------------------
      // STEP 6: Validate Login Type
      // ----------------------------------------------------------

      if (loginType.isEmpty) {
        await clearSession();

        ShowToastDialog.showToast(
          'Unknown user role'.tr,
        );

        return false;
      }

      // ----------------------------------------------------------
      // STEP 7: Save Login Session
      //
      // IMPORTANT:
      // JWT is saved BEFORE Merchant Profile API
      // ----------------------------------------------------------

      await _saveLoginSession(
        userId: userId,
        token: token,
        role: role,
        loginType: loginType,
      );

      debugPrint(
        '[LoginSuccess] Session/token saved successfully',
      );

      // ----------------------------------------------------------
      // STEP 8: Initialize Merchant / Outlet
      // ----------------------------------------------------------

      final sessionResult =
      await _initializeLoginSession(
        loginType: loginType,
        response: response,
        userId: userId,
        token: token,
        role: role,
      );

      // ----------------------------------------------------------
      // STEP 9: Check Session Initialization
      // ----------------------------------------------------------

      if (!sessionResult) {
        await clearSession();

        ShowToastDialog.showToast(
          'Unable to initialize account. Please try again.'.tr,
        );

        return false;
      }

      debugPrint(
        '[LoginSuccess] Session initialized successfully',
      );

      // ----------------------------------------------------------
      // STEP 10: Navigate
      //
      // PENDING / NOT APPROVED
      //        ↓
      // Verification Screen
      //
      // APPROVED
      //        ↓
      // Dashboard
      // ----------------------------------------------------------

      await _navigateToDashboard();

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[LoginSuccess] error=$e',
      );

      debugPrint(
        '[LoginSuccess] stackTrace=$stackTrace',
      );

      await clearSession();

      ShowToastDialog.showToast(
        _getLoginErrorMessage(e),
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Login Type
  // ---------------------------------------------------------------------------

  String _getRole(
      Map<String, dynamic> response,
      ) {
    final roles = response['roles'];

    if (roles is List && roles.isNotEmpty) {
      return roles.first.toString();
    }

    return '';
  }

  String _resolveLoginType({
    required String role,
    required Map<String, dynamic> response,
  }) {
    if (role == 'ROLE_ADMIN' ||
        role == 'ROLE_MERCHANT') {
      return 'MERCHANT';
    }

    final outletId = response['outletId'];

    final userType =
    response['userType']
        ?.toString()
        .toUpperCase();

    if (role == 'ROLE_OUTLET' ||
        outletId != null ||
        userType == 'OUTLET') {
      return 'OUTLET';
    }

    return '';
  }

  // ---------------------------------------------------------------------------
  // Session Initialization
  // ---------------------------------------------------------------------------

  Future<bool> _initializeLoginSession({
    required String loginType,
    required Map<String, dynamic> response,
    required int userId,
    required String token,
    required String role,
  }) async {
    switch (loginType) {
      case 'MERCHANT':
        return _initializeMerchantSession(
          response: response,
          userId: userId,
        );

      case 'OUTLET':
        return _initializeOutletLoginSession(
          response: response,
        );

      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Merchant Login
  // ---------------------------------------------------------------------------

  Future<bool> _initializeMerchantSession({
    required Map<String, dynamic> response,
    required int userId,
  }) async {
    final merchantId =
        _parseInt(response['merchantId']) ??
            userId;

    if (merchantId <= 0) {
      debugPrint(
        '[MerchantSession] Invalid merchantId=$merchantId',
      );

      return false;
    }

    await Preferences.setString(
      _keyMerchantId,
      merchantId.toString(),
    );

    await Preferences.setInt(
      _keyOutletId,
      0,
    );

    await Preferences.setInt(
      _keySelectedOutletId,
      0,
    );

    await Preferences.setString(
      _keyLoginType,
      'MERCHANT',
    );

    if (Get.isRegistered<MerchantOutletController>()) {
      Get.delete<MerchantOutletController>(
        force: true,
      );
    }

    final controller = Get.put(
      MerchantOutletController(),
      permanent: true,
    );

    await controller.initializeMerchantSession();

    debugPrint(
      '[MerchantSession] initialized '
          'merchantId=$merchantId '
          'outletCount=${controller.outletList.length}',
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // Outlet Login
  // ---------------------------------------------------------------------------

  Future<bool> _initializeOutletLoginSession({
    required Map<String, dynamic> response,
  }) async {
    final outletId =
        _parseInt(response['outletId']) ??
            _parseInt(response['id']) ??
            _parseInt(response['userId']) ??
            0;

    if (outletId <= 0) {
      debugPrint(
        '[OutletSession] Missing outletId',
      );

      ShowToastDialog.showToast(
        'Outlet ID missing from login. Please contact support.'.tr,
      );

      return false;
    }

    return _initializeOutletSession(outletId);
  }

  Future<bool> _initializeOutletSession(
      int outletId,
      ) async {
    debugPrint(
      '[OutletSession] Loading outletId=$outletId',
    );

    final result =
    await FireStoreUtils.fetchOutletById(
      outletId,
    );

    if (!result.hasMerchantId) {
      debugPrint(
        '[OutletSession] Failed: ${result.message}',
      );

      return false;
    }

    final merchantId = result.merchantId!;

    final resolvedOutletId =
        result.outletId ?? outletId;

    await Preferences.setInt(
      _keyOutletId,
      resolvedOutletId,
    );

    await Preferences.setInt(
      _keySelectedOutletId,
      resolvedOutletId,
    );

    await Preferences.setString(
      _keySelectedOutletName,
      result.outlet?.outletName ?? '',
    );

    await Preferences.setString(
      _keyLoginType,
      'OUTLET',
    );

    await Preferences.setString(
      _keyMerchantId,
      merchantId.toString(),
    );

    await MerchantOutletController.persistApprovalState(
      result.outlet?.isApproved,
    );

    debugPrint(
      '[OutletSession] '
          'outletId=$resolvedOutletId '
          'merchantId=$merchantId',
    );

    // Merchant profile is required by existing dashboard flow.

    try {
      final profile =
      await FireStoreUtils.getMerchantProfile(
        merchantId.toString(),
      );

      if (profile != null) {
        Constant.merchantModel = profile;
      } else {
        debugPrint(
          '[OutletSession] Merchant profile not found',
        );
      }
    } catch (e) {
      debugPrint(
        '[OutletSession] Profile loading failed: $e',
      );

      // Existing behavior:
      // Profile failure is non-fatal.
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Persist Session
  // ---------------------------------------------------------------------------

  Future<void> _saveLoginSession({
    required int userId,
    required String token,
    required String role,
    required String loginType,
  }) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _keyIsLoggedIn,
      true,
    );

    await prefs.setBool(
      Preferences.isFinishOnBoardingKey,
      true,
    );

    await prefs.setString(
      _keyFirebaseId,
      userId.toString(),
    );

    await prefs.setString(
      _keyUserId,
      userId.toString(),
    );

    await prefs.setInt(
      _keyUserIdInt,
      userId,
    );

    await prefs.setString(
      _keyRole,
      role,
    );

    await prefs.setString(
      _keyLoginType,
      loginType,
    );

    await prefs.setString(
      _keyAuthToken,
      token,
    );
  }

  // ---------------------------------------------------------------------------
  // Restore Session
  // ---------------------------------------------------------------------------

  Future<void> proceedToMainApp() async {
    try {
      final onboardingFinished =
      Preferences.getBoolean(
        Preferences.isFinishOnBoardingKey,
      );

      if (!onboardingFinished) {
        _goToLanding();
        return;
      }

      final firebaseLoggedIn =
      await FireStoreUtils.isLogin();

      if (!firebaseLoggedIn) {
        await clearSession();
        _goToLanding();
        return;
      }

      final authToken =
      Preferences.getString(
        _keyAuthToken,
      );

      final loginType =
      Preferences.getString(
        _keyLoginType,
      );

      if (authToken.isEmpty ||
          loginType.isEmpty) {
        await clearSession();
        _goToLanding();
        return;
      }

      switch (loginType) {
        case 'MERCHANT':
          await _restoreMerchantSession();
          break;

        case 'OUTLET':
          await _restoreOutletSession();
          break;

        default:
          await clearSession();
          _goToLanding();
          return;
      }

      await _goToDashboardOrVerification();
    } catch (e, stackTrace) {
      debugPrint(
        '[SessionRestore] error=$e',
      );

      debugPrint(
        '[SessionRestore] stackTrace=$stackTrace',
      );

      await clearSession();

      _goToLanding();
    }
  }

  Future<void> _restoreMerchantSession() async {
    if (!Get.isRegistered<MerchantOutletController>()) {
      Get.put(
        MerchantOutletController(),
        permanent: true,
      );
    }

    await Get.find<MerchantOutletController>()
        .initializeMerchantSession();
  }

  Future<void> _restoreOutletSession() async {
    final merchantId =
    Preferences.getString(
      _keyMerchantId,
    );

    if (merchantId.isEmpty) {
      throw Exception(
        'Merchant ID missing for outlet session',
      );
    }

    final profile =
    await FireStoreUtils.getMerchantProfile(
      merchantId,
    );

    if (profile != null) {
      Constant.merchantModel = profile;
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Future<void> _navigateToDashboard() async {
    await _goToDashboardOrVerification();
  }

  /// True when the current merchant/outlet
  /// is approved by the backend.
  ///
  /// Fails open so a fetch error never
  /// locks a user out.
  Future<bool> _isSessionApproved() async {
    final loginType =
    Preferences.getString(
      _keyLoginType,
    );

    try {
      // --------------------------------------------------------
      // OUTLET
      // --------------------------------------------------------

      if (loginType == 'OUTLET') {
        final outletId =
        Preferences.getInt(_keyOutletId) > 0
            ? Preferences.getInt(_keyOutletId)
            : Preferences.getInt(
          _keySelectedOutletId,
        );

        if (outletId <= 0) {
          return true;
        }

        final result =
        await FireStoreUtils.fetchOutletById(
          outletId,
        );

        return result.outlet?.isApproved ?? true;
      }

      // --------------------------------------------------------
      // MERCHANT
      // --------------------------------------------------------

      if (Get.isRegistered<MerchantOutletController>()) {
        final profile =
            Get.find<MerchantOutletController>()
                .merchantProfile
                .value;

        if (profile != null) {
          return profile.isApproved ?? true;
        }
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[Session] approval check failed: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard OR Verification
  // ---------------------------------------------------------------------------

  Future<void> _goToDashboardOrVerification() async {
    final approved =
    await _isSessionApproved();

    await MerchantOutletController.persistApprovalState(
      approved,
    );

    // ----------------------------------------------------------
    // NOT APPROVED
    // ----------------------------------------------------------

    if (!approved) {
      debugPrint(
        '[Session] Not approved — showing verification screen',
      );

      Get.offAll(
            () => const VerificationScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(
          milliseconds: 400,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // APPROVED
    // ----------------------------------------------------------

    if (Get.isRegistered<DashBoardController>()) {
      Get.delete<DashBoardController>(
        force: true,
      );
    }

    _goToDashboard();
  }

  void _goToDashboard() {
    Get.offAll(
          () => const DashBoardScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(
        milliseconds: 500,
      ),
    );
  }

  void _goToLanding() {
    Get.offAll(
          () => const LandingScreen(),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logoutFunction() async {
    try {
      await AudioPlayerService.playSound(false);

      if (Constant.userModel != null) {
        try {
          Constant.userModel!.fcmToken = '';

          await FireStoreUtils.updateUser(
            Constant.userModel!,
          );
        } catch (e) {
          debugPrint(
            '[Logout] FCM update failed: $e',
          );
        }
      }
    } finally {
      Constant.userModel = null;

      _disposeSessionControllers();

      await clearSession();

      _goToLanding();
    }
  }

  void _disposeSessionControllers() {
    if (Get.isRegistered<MerchantOutletController>()) {
      Get.delete<MerchantOutletController>(
        force: true,
      );
    }

    if (Get.isRegistered<DashBoardController>()) {
      Get.delete<DashBoardController>(
        force: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Clear Session
  // ---------------------------------------------------------------------------

  Future<void> clearSession() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(_keyFirebaseId);

    await prefs.remove(_keyUserId);

    await prefs.remove(_keyUserIdInt);

    await prefs.remove(_keyRole);

    await prefs.remove(_keyAuthToken);

    await prefs.remove(_keyMerchantId);

    await prefs.remove(_keyOutletId);

    await prefs.remove(_keySelectedOutletId);

    await prefs.remove(_keySelectedOutletName);

    await prefs.remove(_keyLoginType);

    await prefs.setBool(
      _keyIsLoggedIn,
      false,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String _getLoginErrorMessage(
      Object error,
      ) {
    if (error is http.ClientException) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    return 'Login failed. Please try again.';
  }
}