import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_restaurant/app/auth_screen/controllers/login_controller.dart';
import 'package:mime/mime.dart';
import 'package:jippymart_restaurant/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_restaurant/constant/constant.dart';
import 'package:jippymart_restaurant/constant/show_toast_dialog.dart';
import 'package:jippymart_restaurant/models/AttributesModel.dart';
import 'package:jippymart_restaurant/models/advertisement_model.dart';
import 'package:jippymart_restaurant/models/conversation_model.dart';
import 'package:jippymart_restaurant/models/document_model.dart';
import 'package:jippymart_restaurant/models/driver_document_model.dart';
import 'package:jippymart_restaurant/models/email_template_model.dart';
import 'package:jippymart_restaurant/models/coupon_model.dart';
import 'package:jippymart_restaurant/models/inbox_model.dart';
import 'package:jippymart_restaurant/models/notification_model.dart';
import 'package:jippymart_restaurant/models/on_boarding_model.dart';
import 'package:jippymart_restaurant/models/order_model.dart';
import 'package:jippymart_restaurant/models/payment_model/cod_setting_model.dart';
import 'package:jippymart_restaurant/models/payment_model/flutter_wave_model.dart';
import 'package:jippymart_restaurant/models/payment_model/mercado_pago_model.dart';
import 'package:jippymart_restaurant/models/payment_model/mid_trans.dart';
import 'package:jippymart_restaurant/models/payment_model/orange_money.dart';
import 'package:jippymart_restaurant/models/payment_model/pay_fast_model.dart';
import 'package:jippymart_restaurant/models/payment_model/pay_stack_model.dart';
import 'package:jippymart_restaurant/models/payment_model/paypal_model.dart';
import 'package:jippymart_restaurant/models/payment_model/paytm_model.dart';
import 'package:jippymart_restaurant/models/payment_model/razorpay_model.dart';
import 'package:jippymart_restaurant/models/payment_model/stripe_model.dart';
import 'package:jippymart_restaurant/models/payment_model/wallet_setting_model.dart';
import 'package:jippymart_restaurant/models/payment_model/xendit.dart';
import 'package:jippymart_restaurant/models/product_model.dart';
import 'package:jippymart_restaurant/models/rating_model.dart';
import 'package:jippymart_restaurant/models/referral_model.dart';
import 'package:jippymart_restaurant/models/review_attribute_model.dart';
import 'package:jippymart_restaurant/models/story_model.dart';

import 'package:jippymart_restaurant/models/user_model.dart';
import 'package:jippymart_restaurant/models/vendor_category_model.dart';
import 'package:jippymart_restaurant/models/vendor_model.dart';
import 'package:jippymart_restaurant/models/wallet_transaction_model.dart';
import 'package:jippymart_restaurant/models/withdraw_method_model.dart';
import 'package:jippymart_restaurant/models/withdrawal_model.dart';
import 'package:jippymart_restaurant/models/zone_model.dart';
import 'package:jippymart_restaurant/utils/preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/create_master_product_model.dart';
import '../models/cuisine_type_model.dart';
import '../models/merchant_response_model.dart';
import '../models/merchant_request_model.dart';
import '../models/outlet_details_model.dart';
import '../models/outlet_fetch_result.dart';
import '../models/outlet_model.dart';
import '../models/outlet_product_model.dart';
import '../models/promotion_models.dart';
import '../models/variant_group_model.dart';
import 'common.dart';

class _ProductCacheEntry {
  final List<ProductModel> list;
  final DateTime cachedAt;
  _ProductCacheEntry(this.list, this.cachedAt);
}

class _OutletProductsCacheEntry {
  final OutletProductsResult result;
  final DateTime cachedAt;
  _OutletProductsCacheEntry(this.result, this.cachedAt);
}

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  // Performance Optimization: Transparent caching layer
  // Cache variables for frequently accessed, rarely-changing data
  static UserModel? _cachedUserProfile;
  static String? _cachedUserProfileUuid;
  static DateTime? _userProfileCacheTime;
  static const Duration _userProfileCacheTTL = Duration(minutes: 5);

  static VendorModel? _cachedVendor;
  static String? _cachedVendorId;
  static DateTime? _vendorCacheTime;
  static const Duration _vendorCacheTTL = Duration(minutes: 5);

  // Product list cache: keyed by vendorID, TTL 3 minutes
  static final Map<String, _ProductCacheEntry> _productCache = {};
  static const Duration _productCacheTTL = Duration(minutes: 3);

  // Outlet inventory cache: keyed by outletId, TTL 3 minutes
  static final Map<int, _OutletProductsCacheEntry> _outletProductCache = {};
  static String? _lastOutletProductsError;
  static String? get lastOutletProductsError => _lastOutletProductsError;

  // Resolved outlet id cache: avoids a getMerchantOutlets API call on every
  // menu access. Cleared when the logged-in merchant/outlet session changes.
  static int? _cachedResolvedOutletId;
  static DateTime? _cachedResolvedOutletTime;
  static const Duration _resolvedOutletCacheTTL = Duration(minutes: 5);

  // In-flight guard: if two callers request the same merchant's outlets while
  // a request is already running, they share one network call instead of two.
  static final Map<int, Future<List<OutletModel>>> _merchantOutletsInFlight = {};

  // Vendor categories cache: one global list per app session, TTL 3 minutes
  static List<VendorCategoryModel>? _cachedVendorCategories;
  static DateTime? _vendorCategoriesCacheTime;
  static const Duration _vendorCategoriesCacheTTL = Duration(minutes: 3);
  static void clearVendorCategoriesCache() {
    _cachedVendorCategories = null;
    _vendorCategoriesCacheTime = null;
  }
  static List<VariantGroupModel>? _cachedVariantGroups;
  static DateTime? _variantGroupsCacheTime;

  static const Duration _variantGroupsCacheTTL =
  Duration(minutes: 30);
  static DateTime? _settingsCacheTime;
  static const Duration _settingsCacheTTL = Duration(minutes: 30);

  static DeliveryCharge? _cachedDeliveryCharge;
  static DateTime? _deliveryChargeCacheTime;
  static const Duration _deliveryChargeCacheTTL = Duration(minutes: 15);

  // Cache invalidation methods (called on updates)
  static void _invalidateUserProfileCache() {
    _cachedUserProfile = null;
    _cachedUserProfileUuid = null;
    _userProfileCacheTime = null;
  }

  static void _invalidateVendorCache() {
    _cachedVendor = null;
    _cachedVendorId = null;
    _vendorCacheTime = null;
  }

  /// Call after create/update vendor so next getVendorById() fetches fresh data from server.
  static void invalidateVendorCache() {
    _invalidateVendorCache();
  }

  // static void _invalidateSettingsCache() {
  //   _settingsCacheTime = null;
  // }
  //
  // static void _invalidateDeliveryChargeCache() {
  //   _cachedDeliveryCharge = null;
  //   _deliveryChargeCacheTime = null;
  // }

  static Future<String> getCurrentUid() async {
    // final firebaseId = await getFirebaseId() ?? '';
    // if (firebaseId.isNotEmpty) return firebaseId;

    final userId = Preferences.getInt('userId');
    if (userId > 0) return userId.toString();

    final userIdStr = Preferences.getString('user_id');
    if (userIdStr.isNotEmpty) return userIdStr;

    return '';
  }

  static Future<bool> isLogin() async {
    final token = Preferences.getString('authToken');
    final loggedIn = Preferences.pref.getBool('is_logged_in') ?? false;

    // Java API session — token + logged-in flag saved on login.
    if (loggedIn && token.isNotEmpty) {
      return true;
    }

    return false;
  }



  static Future<bool> userExistOrNot(String uid) async {
    bool isExist = false;
    debugPrint("userExistOrNot ${'${Constant.baseUrl}restaurant/exists/$uid'} ");
    await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/exists/$uid')
    ).then((response) {
      debugPrint("userExistOrNot ${response.body} ");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        isExist = data['exists'] ?? false;
      } else {
        isExist = false;
        log("Failed to check user exist: ${response.statusCode}");
      }
    }).catchError((error) {
      log("Failed to check user exist: $error");
      isExist = false;
    });

    return isExist;
  }


  static Future<UserModel?> getUserProfile(String uuid, {bool forceRefresh = false}) async {
    try {
      // Performance Optimization: Check cache first (transparent to caller)
      if (!forceRefresh &&
          _cachedUserProfile != null &&
          _cachedUserProfileUuid == uuid &&
          _userProfileCacheTime != null) {
        final cacheAge = DateTime.now().difference(_userProfileCacheTime!);
        if (cacheAge < _userProfileCacheTTL) {
          log("getUserProfile: Returning cached data (age: ${cacheAge.inSeconds}s)");
          Constant.userModel = _cachedUserProfile;
          return _cachedUserProfile;
        }
      }

      String url = '${Constant.baseUrl}restaurant/users/$uuid';
      debugPrint(" getUserProfile $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log(" getUserProfileresponse body ${response.body}");
        if (responseData['success'] ?? true) {
          final userData = responseData['data'] ?? responseData; // Adjust based on your API structure
          final userModel = UserModel.fromJson(userData);
          Constant.userModel = userModel;
          debugPrint(" getUserProfile  ${  Constant.userModel?.toJson()} ");

          // Performance Optimization: Cache the result
          _cachedUserProfile = userModel;
          _cachedUserProfileUuid = uuid;
          _userProfileCacheTime = DateTime.now();

          return userModel;
        } else {
          log("API returned error: ${responseData['message']}");
          return null;
        }
      } else {
        log("Failed to get user profile: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      log("Error getting user profile: $error");
      return null;
    }
  }

  static Future<MerchantModel?> getMerchantProfile(String merchantId) async {
    try {
      if (merchantId.trim().isEmpty) {
        debugPrint("Merchant ID is empty");
        return null;
      }

      final headers = await getHeaders();
      final url =
          '${Constant.baseUrl}fm/merchants/getMerchantProfile?merchantId=$merchantId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        debugPrint("Merchant Profile JSON = $jsonData");

        final profileData = jsonData is Map<String, dynamic> &&
                jsonData['data'] is Map
            ? Map<String, dynamic>.from(jsonData['data'] as Map)
            : Map<String, dynamic>.from(jsonData as Map);

        print(profileData);
        return MerchantModel.fromJson(profileData);
      }

      debugPrint(
        "Failed to fetch profile. Status: ${response.statusCode}",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint("getMerchantProfile Error: $e");
      print(stackTrace);
      return null;
    }
  }


  static Future<bool> updateMerchantProfile(String merchantId, MerchantModel merchant) async {
    try {
      final headers = await getHeaders();
      final parsedMerchantId = int.tryParse(merchantId);
      if (parsedMerchantId == null) {
        log("updateMerchantProfile error: invalid merchantId '$merchantId'");
        return false;
      }

      final Map<String, dynamic> body = {
        'merchantId': parsedMerchantId,
        'merchantName': merchant.merchantName,
        'businessType': merchant.merchantBusinessType,
        //'status': merchant.status,
        'merchantEmail': merchant.merchantEmail,
        'merchantPhone': merchant.merchantPhone,
        'bankId': merchant.bankId,
        'recipientId': merchant.recipientId,
        'accountNumber': merchant.accountNumber,
        'ifscCode': merchant.ifscCode,
        'bankName': merchant.bankName,
        'accountHolderName': merchant.accountHolderName,
        'userType': 'MERCHANT',
        'aadharNumber' : merchant.addharNumber,
        'panNumber' : merchant.panNumber,
      };

      debugPrint("===== UPDATE MERCHANT REQUEST =====");
      debugPrint(json.encode(body));

      final response = await http.put(
        Uri.parse('${Constant.baseUrl}fm/merchants/updateMerchantProfile'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("updateMerchantProfile success: ${response.body}");
        return true;
      } else {
        log("updateMerchantProfile failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      log("updateMerchantProfile error: $e");
      return false;
    }
  }
  //(end)
//  THIS IS JAVA API OF CREATE MERCHANT PROFILE   create merchant profile
  static Future<MerchantModel?> createMerchant(MerchantRequestModel request,) async {
    try {
     // final token = Preferences.getString('authToken');
     final headers = await getHeaders();
//{
     //    'Content-Type': 'application/json',
     //    'Accept': 'application/json',
     //    //'Authorization':'Bearer $token'
     //  } ;
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/merchants/createMerchant',
        ),
        headers: headers,
        body: jsonEncode(
          request.toJson(),
        ),
      );

      debugPrint("Status Code : ${response.statusCode}");
      debugPrint("Response : ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final jsonResponse =
        jsonDecode(response.body);

        return MerchantModel.fromJson(
          jsonResponse['data'],
        );
      }

      return null;
    } catch (e) {
      debugPrint("createMerchant Error : $e");
      return null;
    }
  }
  // end
  // THIS IS THE CODE OF JAVA GETTING THE LIST OF OUTLETS BY USING THE MERCHANT ID
  static Future<List<OutletModel>> getMerchantOutlets(int merchantId) async {
    // Share one network call between concurrent callers for the same merchant.
    final inFlight = _merchantOutletsInFlight[merchantId];
    if (inFlight != null) return inFlight;

    final future = _getMerchantOutlets(merchantId);
    _merchantOutletsInFlight[merchantId] = future;
    try {
      return await future;
    } finally {
      if (identical(_merchantOutletsInFlight[merchantId], future)) {
        _merchantOutletsInFlight.remove(merchantId);
      }
    }
  }

  static Future<List<OutletModel>> _getMerchantOutlets(int merchantId) async {
    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/outlets/merchant/$merchantId';

      debugPrint("===== getMerchantOutlets API =====");
      debugPrint("URL: $url");
      debugPrint("merchantId: $merchantId");

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final dynamic rawData = jsonResponse['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : rawData == null
                ? <dynamic>[]
                : <dynamic>[];

        debugPrint("API DATA COUNT = ${data.length}");

        final outlets = data
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return OutletModel.fromJsonSafe(e);
                }
                if (e is Map) {
                  return OutletModel.fromJsonSafe(
                    Map<String, dynamic>.from(e),
                  );
                }
              } catch (parseError) {
                debugPrint("Outlet list item parse warning: $parseError");
              }
              return null;
            })
            .whereType<OutletModel>()
            .toList();

        debugPrint("PARSED OUTLET COUNT = ${outlets.length}");

        return outlets;
      }

      if (response.statusCode == 404) {
        debugPrint("getMerchantOutlets: no outlets found (404)");
        return [];
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint("getMerchantOutlets Error = $e");
      print(stackTrace);
      return [];
    }
  }

  /// Fetches a single outlet by ID with safe parsing and structured result.
  static Future<OutletFetchResult> fetchOutletById(int outletId) async {
    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/outlets/getOutletById/$outletId';

      debugPrint("===== getOutletById API =====");
      debugPrint("URL: $url");
      debugPrint("outletId: $outletId");

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final parsed = _parseOutletFetchResult(response.body, outletId);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint("[getOutletById] HTTP failure — ${response.statusCode}");
        if (parsed.isSuccess && parsed.outletId != null) {
          return parsed;
        }
        return OutletFetchResult.httpError(
          response.statusCode,
          response.body,
        );
      }

      return parsed;
    } catch (e, stackTrace) {
      debugPrint("getOutletById Error = $e");
      print(stackTrace);
      return OutletFetchResult.parseError(e.toString());
    }
  }

  static OutletFetchResult _parseOutletFetchResult(
    String body,
    int requestedOutletId,
  ) {
    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      } else if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    } catch (decodeError, stackTrace) {
      debugPrint("[getOutletById] JSON decode error — $decodeError");
      print(stackTrace);

      final fallbackMerchantId = OutletModel.extractMerchantIdFromRaw(body);
      if (fallbackMerchantId != null && fallbackMerchantId > 0) {
        debugPrint(
          "[getOutletById] Fallback merchantId=$fallbackMerchantId from raw body",
        );
        final fallbackOutletId = OutletModel.extractOutletIdFromRaw(body);
        if (fallbackOutletId != null && fallbackOutletId > 0) {
          return OutletFetchResult.success(
            outlet: OutletModel(
              outletId: fallbackOutletId,
              merchantId: fallbackMerchantId,
            ),
            merchantId: fallbackMerchantId,
            outletId: fallbackOutletId,
            hadParseWarning: true,
          );
        }
      }
      return OutletFetchResult.parseError(decodeError.toString());
    }

    if (decoded == null) {
      return OutletFetchResult.empty();
    }

    if (decoded['success'] == false) {
      final msg =
          decoded['message']?.toString() ?? 'API returned success=false';
      debugPrint("[getOutletById] API failure — $msg");
      return OutletFetchResult.apiError(msg);
    }

    final dynamic rawData = decoded['data'] ?? decoded;
    if (rawData is! Map) {
      debugPrint("[getOutletById] No outlet data map in response");
      return OutletFetchResult.empty();
    }

    final dataMap = Map<String, dynamic>.from(rawData);

    OutletModel outlet;
    var hadParseWarning = false;
    try {
      outlet = OutletModel.fromJsonSafe(dataMap);
    } catch (parseError, stackTrace) {
      hadParseWarning = true;
      debugPrint("[getOutletById] Model parse warning — $parseError");
      print(stackTrace);
      outlet = OutletModel(
        outletId: OutletModel.parseOutletIdFromMap(dataMap),
        merchantId: OutletModel.extractMerchantId(dataMap),
        outletName: dataMap['outletName']?.toString(),
      );
    }

    final merchantId =
        outlet.merchantId ?? OutletModel.extractMerchantId(dataMap);
    final resolvedOutletId = outlet.outletId ??
        OutletModel.parseOutletIdFromMap(dataMap);

    if (resolvedOutletId == null || resolvedOutletId <= 0) {
      debugPrint('[getOutletById] outletId missing in response body');
      return OutletFetchResult.apiError('outletId missing in outlet response');
    }

    debugPrint(
      "[getOutletById] Parsed merchantId=$merchantId outletId=$resolvedOutletId",
    );

    if (merchantId == null || merchantId <= 0) {
      final fallbackMerchantId = OutletModel.extractMerchantIdFromRaw(body);
      if (fallbackMerchantId != null && fallbackMerchantId > 0) {
        debugPrint("[getOutletById] Using fallback merchantId=$fallbackMerchantId");
        return OutletFetchResult.success(
          outlet: OutletModel(
            outletId: resolvedOutletId,
            merchantId: fallbackMerchantId,
            outletName: outlet.outletName,
          ),
          merchantId: fallbackMerchantId,
          outletId: resolvedOutletId,
          hadParseWarning: true,
        );
      }
      return OutletFetchResult.apiError(
        'merchantId missing in outlet response',
      );
    }

    return OutletFetchResult.success(
      outlet: outlet.outletId != null
          ? outlet
          : OutletModel(
              outletId: resolvedOutletId,
              merchantId: merchantId,
              outletName: outlet.outletName,
             // outletCategoryId: outlet.outletCategoryId,
            ),
      merchantId: merchantId,
      outletId: resolvedOutletId,
      hadParseWarning: hadParseWarning,
    );
  }

  /// Backward-compatible wrapper — returns outlet model or null.
  static Future<OutletModel?> getOutletById(int outletId) async {
    final result = await fetchOutletById(outletId);
    return result.isSuccess ? result.outlet : null;
  }
  //END
  static Future<UserModel?> getUserById(String uuid) async {
    try {
      String url = '${Constant.baseUrl}restaurant/users/$uuid';
      log("getUserById:: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          return UserModel.fromJson(responseData);
        }
        else if (responseData['data'] != null) {
          return UserModel.fromJson(responseData['data']);
        }
        // Option 3: With success flag
        else if (responseData['success'] == true && responseData['user'] != null) {
          return UserModel.fromJson(responseData['user']);
        }
        // Option 4: With success flag and data field
        else if (responseData['success'] == true && responseData['data'] != null) {
          return UserModel.fromJson(responseData['data']);
        }
        else {
          log("Unexpected API response structure: $responseData");
          return null;
        }
      } else if (response.statusCode == 404) {
        log("User not found with UUID: $uuid");
        return null;
      } else {
        log("Failed to get user by ID. Status: ${response.statusCode}, Body: ${response.body}");
        return null;
      }
    } catch (error) {
      log("Error getting user by ID: $error");
      return null;
    }
  }


  static Future<bool?> updateUserWallet({
    required String amount,
    required String userId
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/update-user-wallet'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? true; // Adjust based on your API response
      } else {
        debugPrint('Failed to update wallet: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle network or other errors
      debugPrint('Error updating wallet: $e');
      return false;
    }
  }
  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    try {
      // String? userId = await getFirebaseId();
      // userModel.id = userId;
      debugPrint("updateUser  ${ userModel.toJson()}");
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/updateUser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userModel.toJson()),
      );

      if (response.statusCode == 200) {
        Constant.userModel = userModel;
        // Performance Optimization: Invalidate user profile cache after update
        _invalidateUserProfileCache();
        // Update cache with new data
        _cachedUserProfile = userModel;
        _cachedUserProfileUuid = userModel.id;
        _userProfileCacheTime = DateTime.now();
        isUpdate = true;
      } else {
        log("Failed to update user: ${response.statusCode} - ${response.body}");
        isUpdate = false;
      }
    } catch (error) {
      log("Failed to update users: $error");
      isUpdate = false;
    }
    return isUpdate;
  }
  // Rate limiting: Track last request time and minimum delay between requests
  static DateTime? _lastUpdateDriverUserRequest;
  static const Duration _minDelayBetweenRequests = Duration(milliseconds: 200); // 200ms delay between requests

  static Future<bool> updateDriverUser(UserModel userModel, {int maxRetries = 3}) async {
    // Rate limiting: Ensure minimum delay between requests
    if (_lastUpdateDriverUserRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastUpdateDriverUserRequest!);
      if (timeSinceLastRequest < _minDelayBetweenRequests) {
        final delayNeeded = _minDelayBetweenRequests - timeSinceLastRequest;
        await Future.delayed(delayNeeded);
      }
    }

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        userModel.id = userModel.firebaseId;
        log("updateDriverUser ${'${Constant.baseUrl}restaurant/updateUser'} ");
        log("updateDriverUser ${userModel.firebaseId} ${userModel.id} ");
        Map<String, dynamic> userJson = _convertTimestampsToJson(userModel.toJson());
        log("updateDriverUser ${userJson}");
        _lastUpdateDriverUserRequest = DateTime.now();
        final response = await http.post(
          Uri.parse('${Constant.baseUrl}restaurant/updateUser'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(userJson),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          // Performance Optimization: Invalidate user profile cache after update
          _invalidateUserProfileCache();
          return responseData['success'] ?? true; // Adjust based on your API response structure
        } else if (response.statusCode == 429) {
          // Rate limited - retry with exponential backoff
          attempt++;
          if (attempt < maxRetries) {
            final backoffDelay = Duration(milliseconds: 500 * (1 << (attempt - 1))); // Exponential backoff: 500ms, 1s, 2s
            log("Rate limited (429). Retrying in ${backoffDelay.inMilliseconds}ms (attempt $attempt/$maxRetries)");
            await Future.delayed(backoffDelay);
            continue;
          } else {
            log("Failed to update user after $maxRetries attempts: ${response.statusCode} - ${response.body}");
            return false;
          }
        } else {
          log("Failed to update user: ${response.statusCode} - ${response.body}");
          return false;
        }
      } catch (error) {
        attempt++;
        if (attempt < maxRetries) {
          final backoffDelay = Duration(milliseconds: 500 * (1 << (attempt - 1)));
          log("Error updating user. Retrying in ${backoffDelay.inMilliseconds}ms (attempt $attempt/$maxRetries): $error");
          await Future.delayed(backoffDelay);
          continue;
        } else {
          log("Failed to update userds after $maxRetries attempts: $error");
          return false;
        }
      }
    }
    return false;
  }
  static Future<bool> withdrawWalletAmount(WithdrawalModel userModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/withdraw'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: userModel.toJson(),
      );
      if (response.statusCode == 200) {
        // Optionally parse the response if needed
        // final responseData = json.decode(response.body);
        return true;
      } else {
        log("Failed to withdraw: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Error during withdrawal: $error");
      return false;
    }
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}onboarding/restaurantApp'),
        headers: await getHeaders()
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<OnBoardingModel> onBoardingModel = [];
          for (var element in responseData['data']) {
            OnBoardingModel documentModel = OnBoardingModel.fromJson(element);
            onBoardingModel.add(documentModel);
          }
          return onBoardingModel;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load onboarding data: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      rethrow; // or return an empty list: return [];
    }
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    try {
      // Convert Timestamps to JSON-serializable format before encoding
      Map<String, dynamic> transactionJson = _convertTimestampsToJson(walletTransactionModel.toJson());

      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/transaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(transactionJson),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? '';
        if (success) {
          log("Wallet transaction saved successfully: $message");
          return true;
        } else {
          log("Failed to save wallet transaction: $message");
          return false;
        }
      } else {
        log("HTTP Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Error adding wallet transaction: $error");
      return false;
    }
  }

  // static Future<void> getSettings({bool forceRefresh = false}) async {
  //   try {
  //     // Performance Optimization: Check cache first (transparent to caller)
  //     if (!forceRefresh && _settingsCacheTime != null) {
  //       final cacheAge = DateTime.now().difference(_settingsCacheTime!);
  //       if (cacheAge < _settingsCacheTTL) {
  //         log("getSettings: Returning cached data (age: ${cacheAge.inSeconds}s)");
  //         return; // Use cached settings (Constants already set)
  //       }
  //     }
  //
  //     final response = await http.get(Uri.parse('${Constant.baseUrl}settings/mobile'));
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body)['data'];
  //       final Map<String, dynamic> documents = data['documents'];
  //       final Map<String, dynamic> derived = data['derived'];
  //       // Global Settings
  //       final globalSettings = documents['globalSettings'] ?? {};
  //       Constant.orderRingtoneUrl = globalSettings['order_ringtone_url'] ?? '';
  //       Preferences.setString(Preferences.orderRingtone, Constant.orderRingtoneUrl);
  //       if (globalSettings['app_restaurant_color'] != null) {
  //         AppThemeData.secondary300 = Color(int.parse(
  //             globalSettings['app_restaurant_color'].replaceFirst("#", "0xff")));
  //       }
  //       Constant.isEnableAdsFeature = globalSettings['isEnableAdsFeature'] ?? false;
  //       Constant.isSelfDeliveryFeature = globalSettings['isSelfDelivery'] ?? false;
  //
  //       if (Constant.orderRingtoneUrl.isNotEmpty) {
  //         await AudioPlayerService.initAudio();
  //       }
  //
  //       // Schedule Order Notification
  //       final scheduleOrder = documents['scheduleOrderNotification'] ?? {};
  //       if (scheduleOrder.isNotEmpty) {
  //         Constant.scheduleOrderTime = scheduleOrder["notifyTime"];
  //         Constant.scheduleOrderTimeType = scheduleOrder["timeUnit"];
  //       }
  //
  //       // Dine-in Settings
  //       final dineInSettings = documents['DineinForRestaurant'] ?? {};
  //       if (dineInSettings.isNotEmpty) {
  //         Constant.isDineInEnable = dineInSettings["isEnabled"];
  //       }
  //
  //       // Restaurant Settings
  //       final restaurantSettings = documents['restaurant'] ?? {};
  //       Constant.autoApproveRestaurant = restaurantSettings['auto_approve_restaurant'] ?? false;
  //       // App Store compliance: Subscription model disabled - app is 100% free
  //       Constant.isSubscriptionModelApplied = false; // Override server: restaurantSettings['subscription_model'] ?? false;
  //
  //       // Admin Commission
  //       final adminCommission = documents['AdminCommission'] ?? {};
  //       if (adminCommission.isNotEmpty) {
  //         Constant.adminCommission = AdminCommission.fromJson(adminCommission);
  //       }
  //
  //       // Google Map Key
  //       final googleMapSettings = documents['googleMapKey'] ?? {};
  //       Constant.mapAPIKey = googleMapSettings["key"] ?? '';
  //       Constant.placeHolderImage = googleMapSettings["placeHolderImage"] ?? '';
  //
  //       // Story Settings
  //       final storySettings = documents['story'] ?? {};
  //       Constant.storyEnable = storySettings['isEnabled'] ?? false;
  //
  //       // Placeholder Image
  //       final placeholderSettings = documents['placeHolderImage'] ?? {};
  //       Constant.placeholderImage = placeholderSettings['image'] ?? '';
  //
  //       // Version Settings
  //       final versionSettings = documents['Version'] ?? {};
  //       Constant.googlePlayLink = versionSettings["googlePlayLink"] ?? '';
  //       Constant.appStoreLink = versionSettings["appStoreLink"] ?? '';
  //       Constant.appVersion = versionSettings["app_version"] ?? '';
  //       Constant.storeUrl = versionSettings["storeUrl"] ?? '';
  //
  //       // Restaurant Nearby
  //       final restaurantNearby = documents['RestaurantNearBy'] ?? {};
  //       if (restaurantNearby.isNotEmpty) {
  //         Constant.distanceType = restaurantNearby["distanceType"];
  //       }
  //
  //       // Special Discount Offer
  //       final specialDiscount = documents['specialDiscountOffer'] ?? {};
  //       if (specialDiscount.isNotEmpty) {
  //         Constant.specialDiscountOfferEnable = specialDiscount["isEnable"];
  //       }
  //
  //       // Email Settings
  //       final emailSettings = documents['emailSetting'] ?? {};
  //       if (emailSettings.isNotEmpty) {
  //         Constant.mailSettings = MailSettings.fromJson(emailSettings);
  //       }
  //
  //       // Contact Us
  //       final contactSettings = documents['ContactUs'] ?? {};
  //       if (contactSettings.isNotEmpty) {
  //         Constant.adminEmail = contactSettings["Email"];
  //       }
  //
  //       // Driver Nearby
  //       final driverNearby = documents['DriverNearBy'] ?? {};
  //       if (driverNearby.isNotEmpty) {
  //         Constant.selectedMapType = driverNearby["selectedMapType"];
  //         Constant.singleOrderReceive = driverNearby['singleOrderReceive'];
  //       }
  //
  //       // Notification Settings
  //       final notificationSettings = documents['notification_setting'] ?? {};
  //       Constant.senderId = notificationSettings["projectId"];
  //       Constant.jsonNotificationFileURL = notificationSettings["serviceJson"];
  //
  //       // Document Verification
  //       final docVerification = documents['document_verification_settings'] ?? {};
  //       Constant.isRestaurantVerification = docVerification['isRestaurantVerification'] ?? false;
  //
  //       // Privacy Policy
  //       final privacyPolicy = documents['privacyPolicy'] ?? {};
  //       if (privacyPolicy.isNotEmpty) {
  //         Constant.privacyPolicy = privacyPolicy["privacy_policy"];
  //       }
  //
  //       // Terms and Conditions
  //       final termsConditions = documents['termsAndConditions'] ?? {};
  //       if (termsConditions.isNotEmpty) {
  //         Constant.termsAndConditions = termsConditions["termsAndConditions"];
  //       }
  //
  //       // Also set derived values for consistency
  //       // App Store compliance: Subscription model disabled - app is 100% free
  //       Constant.isSubscriptionModelApplied = false; // Override: derived['isSubscriptionModelApplied'] ?? false;
  //       Constant.autoApproveRestaurant = derived['autoApproveRestaurant'] ?? false;
  //       Constant.isEnableAdsFeature = derived['isEnableAdsFeature'] ?? false;
  //       Constant.isSelfDeliveryFeature = derived['isSelfDeliveryFeature'] ?? false;
  //       Constant.mapAPIKey = derived['mapAPIKey'] ?? Constant.mapAPIKey;
  //       Constant.placeHolderImage = derived['placeHolderImage'] ?? Constant.placeHolderImage;
  //       Constant.senderId = derived['senderId'] ?? Constant.senderId;
  //       Constant.jsonNotificationFileURL = derived['jsonNotificationFileURL'] ?? Constant.jsonNotificationFileURL;
  //       Constant.privacyPolicy = derived['privacyPolicy'] ?? Constant.privacyPolicy;
  //       Constant.termsAndConditions = derived['termsAndConditions'] ?? Constant.termsAndConditions;
  //       Constant.googlePlayLink = derived['googlePlayLink'] ?? Constant.googlePlayLink;
  //       Constant.appStoreLink = derived['appStoreLink'] ?? Constant.appStoreLink;
  //       Constant.appVersion = derived['appVersion'] ?? Constant.appVersion;
  //       Constant.storyEnable = derived['storyEnable'] ?? Constant.storyEnable;
  //       Constant.placeholderImage = derived['placeholderImage'] ?? Constant.placeholderImage;
  //       Constant.specialDiscountOfferEnable = derived['specialDiscountOffer'] ?? Constant.specialDiscountOfferEnable;
  //
  //       // Performance Optimization: Cache the settings load time
  //       _settingsCacheTime = DateTime.now();
  //
  //     } else {
  //       throw Exception('Failed to load settings: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // }
  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExist;
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/referral/check-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'referralCode': referralCode,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          isExist = responseData['data'] ?? false;
        } else {
          isExist = false;
        }
      } else {
        // Handle non-200 status codes
        debugPrint('API Error: ${response.statusCode}');
        isExist = false;
      }
    } catch (e, s) {
      debugPrint('checkReferralCodeValidOrNot $e $s');
      return false;
    }
    return isExist;
  }
  static Future<ReferralModel?> getReferralUserByCode(String referralCode) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/referral/get-by-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'referralCode': referralCode,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return ReferralModel.fromJson(responseData['data']);
        } else {
          log('API returned unsuccessful response: ${response.body}');
          return null;
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, s) {
      log('getReferralUserByCode error: $e $s');
      return null;
    }
  }

  static Future<OrderModel?> getOrderByOrderId(String orderId) async {
    OrderModel? orderModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          orderModel = OrderModel.fromJson(jsonResponse['data']);
        }
      } else {
        log('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, s) {
      log('getOrderByOrderId API call failed: $e $s');
      return null;
    }
    return orderModel;
  }

  static Future<String?> referralAdd(ReferralModel referralModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/referral/add'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(referralModel.toJson()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          log('Referral added successfully: ${responseData['message']}');
          return null; // Success
        } else {
          log('Failed to add referral: ${responseData['message']}');
          return responseData['message'] ?? 'Failed to add referral';
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        return 'HTTP Error: ${response.statusCode}';
      }
    } catch (e, s) {
      log('referralAdd error: $e $s');
      return e.toString();
    }
  }

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> zoneList = [];
    try {


      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/zones'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> zonesData = responseData['data'];
          for (var element in zonesData) {
            // Filter zones where publish == 1 (equivalent to true)
            if (element['publish'] == 1) {
              ZoneModel zoneModel = ZoneModel.fromJson(element);
              zoneList.add(zoneModel);
            }
          }
        }
      } else {
        throw Exception('Failed to load zones: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString(),name: " getZone ");
      return null;
    }
    return zoneList;
  }

  static Future<List<OrderModel>?> getAllOrder() async {
    List<OrderModel> orderList = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/orders?vendorID=${Constant.userModel!.vendorID}'),
        headers: {
          'Content-Type': 'application/json',
          // Add any required authentication headers here
          // 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          for (var element in data) {
            OrderModel orderModel = OrderModel.fromJson(element);
            orderList.add(orderModel);
          }
          orderList.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1; // Put a after b
            if (b.createdAt == null) return -1; // Put a before b
            return b.createdAt!.compareTo(a.createdAt!);
          });
        } else {
          log('API returned success: false');
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log(e.toString());
    }
    return orderList;
  }
  static Future<bool> updateOrder(OrderModel orderModel) async {
    bool isUpdate = false;
    try {
      log(" updateOrder ${orderModel.toJson()} ");
      // Convert the entire model to JSON and handle any remaining Timestamps
      Map<String, dynamic> orderJson = _convertTimestampsToJson(orderModel.toJson());

      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/orders/${orderModel.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(orderJson),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isUpdate = true;
      } else {
        debugPrint("Failed to update order: ${response.statusCode} - ${response.body}");
        isUpdate = false;
      }
    } catch (error) {
      debugPrint("Failed to update order: $error");
      isUpdate = false;
    }
    return isUpdate;
  }

// Recursive method to convert any Timestamp objects to strings
  static dynamic _convertTimestampsToJson(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map<String, dynamic>) {
      return value.map((key, value) => MapEntry(key, _convertTimestampsToJson(value)));
    } else if (value is List) {
      return value.map((e) => _convertTimestampsToJson(e)).toList();
    }
    return value;
  }
  // static Future<bool> updateOrder(OrderModel orderModel) async {
  //   bool isUpdate = false;
  //   // try {
  //     log(" updateOrder ${orderModel.toJson()} ");
  //     final response = await http.post(
  //       Uri.parse('${Constant.baseUrl}restaurant/orders/${orderModel.id}'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode(orderModel.toJson()),
  //     );
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       isUpdate = true;
  //     } else {
  //       debugPrint("Failed to update order: ${response.statusCode} - ${response.body}");
  //       isUpdate = false;
  //     }
  //   // } catch (error) {
  //   //   debugPrint("Failed to update order: $error");
  //     isUpdate = false;
  //   // }
  //   return isUpdate;
  // }

  static Future restaurantVendorWalletSet(OrderModel orderModel) async {
    // Performance Optimization: Add null safety checks
    if (orderModel.products == null || orderModel.products!.isEmpty) {
      log("Warning: Order has no products, skipping wallet transaction. Order ID: ${orderModel.id}");
      return;
    }

    double subTotal = 0.0;
    double specialDiscount = 0.0;
    double taxAmount = 0.0;
    // double adminCommission = 0.0;

    for (var element in orderModel.products!) {
      final discountPrice = double.tryParse(element.discountPrice?.toString() ?? '0') ?? 0.0;

      if (discountPrice <= 0) {
        subTotal = subTotal +
            (double.tryParse(element.price?.toString() ?? '0') ?? 0) *
                (double.tryParse(element.quantity?.toString() ?? '0') ?? 0) +
            ((double.tryParse(element.extrasPrice?.toString() ?? '0') ?? 0) *
                (double.tryParse(element.quantity?.toString() ?? '0') ?? 0));
      } else {
        subTotal = subTotal +
            discountPrice *
                (double.tryParse(element.quantity?.toString() ?? '0') ?? 0) +
            ((double.tryParse(element.extrasPrice?.toString() ?? '0') ?? 0) *
                (double.tryParse(element.quantity?.toString() ?? '0') ?? 0));
      }
    }

    if (orderModel.specialDiscount != null &&
        orderModel.specialDiscount!['special_discount'] != null) {
      specialDiscount = double.tryParse(
          orderModel.specialDiscount!['special_discount'].toString()) ?? 0.0;
    }

    if (orderModel.taxSetting != null) {
      final discount = double.tryParse(orderModel.discount?.toString() ?? '0') ?? 0.0;
      for (var element in orderModel.taxSetting!) {
        taxAmount = taxAmount +
            Constant.calculateTax(
                amount: (subTotal - discount - specialDiscount).toString(),
                taxModel: element);
      }
    }

    double basePrice = 0;
    final discount = double.tryParse(orderModel.discount?.toString() ?? '0') ?? 0.0;

    // var totalamount = (subTotal + taxAmount) - discount - specialDiscount;
    if (Constant.adminCommission != null && Constant.adminCommission!.isEnabled == true) {
      final adminCommissionPercent = double.tryParse(orderModel.adminCommission?.toString() ?? '0') ?? 0.0;
      if (adminCommissionPercent > 0) {
        basePrice =
            (subTotal / (1 + (adminCommissionPercent / 100))) -
                discount -
                specialDiscount;
      } else {
        basePrice = subTotal - discount - specialDiscount;
      }
    } else {
      basePrice = subTotal - discount - specialDiscount;
    }
    // if (Constant.isAdminCommissionModelApplied == true) {
    //   if (orderModel.adminCommissionType == 'Percent') {
    //     adminCommission = (subTotal - double.parse(orderModel.discount.toString()) - specialDiscount) * double.parse(orderModel.adminCommission!) / 100;
    //   } else {
    //     adminCommission = double.parse(orderModel.adminCommission!);
    //   }
    // }
    // Performance Optimization: Handle null vendor case (can happen when running in parallel)
    String? vendorAuthorId;

    // if (orderModel.vendor != null && orderModel.vendor!.author != null) {
    //   vendorAuthorId = orderModel.vendor!.author.toString();
    // } else if (orderModel.vendorID != null) {
    //   // Try to get vendor author from cached vendor data or fetch it
    //   try {
    //     // Check if cached vendor matches
    //     if (_cachedVendor != null && _cachedVendorId == orderModel.vendorID && _cachedVendor!.author != null) {
    //       vendorAuthorId = _cachedVendor!.author;
    //       log("Using cached vendor data for wallet transaction. Order ID: ${orderModel.id}");
    //     } else {
    //       // Fetch vendor data (using cache if available)
    //       VendorModel? vendor = await getVendorById(orderModel.vendorID!);
    //       if (vendor != null && vendor.author != null) {
    //         vendorAuthorId = vendor.author;
    //         log("Fetched vendor data for wallet transaction. Order ID: ${orderModel.id}");
    //       }
    //     }
    //   } catch (e) {
    //     log("Error fetching vendor for wallet transaction: $e");
    //   }
    // }

    if (vendorAuthorId == null || vendorAuthorId.isEmpty) {
      log("Warning: Cannot determine vendor author ID, skipping wallet transaction. Order ID: ${orderModel.id}");
      // Don't throw error - order update should still succeed
      return;
    }

    WalletTransactionModel historyModel = WalletTransactionModel(
        amount: basePrice,
        id: const Uuid().v4(),
        orderId: orderModel.id,
        userId: vendorAuthorId,
        date: Timestamp.now(),
        isTopup: true,
        note: "Order Amount credited",
        paymentMethod: "Wallet",
        paymentStatus: "success",
        transactionUser: "vendor");
    addWalletTransaction(historyModel);

    WalletTransactionModel taxModel = WalletTransactionModel(
        amount: taxAmount,
        id: const Uuid().v4(),
        orderId: orderModel.id,
        userId: vendorAuthorId,
        date: Timestamp.now(),
        isTopup: true,
        note: "Order Tax credited",
        paymentMethod: "tax",
        paymentStatus: "success",
        transactionUser: "vendor");
    // addWalletTransaction(historyModel);

    addWalletTransaction(taxModel);

    await updateUserWallet(
        amount: (basePrice + taxAmount).toString(),
        userId: vendorAuthorId);
  }

  static Future<bool> addWalletTransaction(WalletTransactionModel historyModel) async {
    try {
      // Convert Timestamps to JSON-serializable format before encoding
      Map<String, dynamic> transactionJson = _convertTimestampsToJson(historyModel.toJson());

      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/transaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(transactionJson),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Wallet transaction added successfully");
        return true;
      } else {
        log("Failed to add wallet transaction: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Error adding wallet transaction: $error");
      return false;
    }
  }
  static Future<RatingModel?> getOrderReviewsByID(
      String orderId, String productID) async {
    RatingModel? ratingModel;

    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/reviews/order?orderId=$orderId&productID=$productID'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          ratingModel = RatingModel.fromJson(jsonResponse['data']);
          debugPrint("======> Review found");
        } else {
          debugPrint("======> No review found");
          ratingModel = null;
        }
      } else {
        debugPrint("Failed to fetch review: ${response.statusCode} - ${response.body}");
        ratingModel = null;
      }
    } catch (error) {
      debugPrint("Error fetching review: $error");
      ratingModel = null;
    }

    return ratingModel;
  }
  static Future<List<ProductModel>?> getProduct() async {
    final String? vendorID = Constant.userModel?.vendorID;
    if (vendorID != null) {
      final entry = _productCache[vendorID];
      if (entry != null &&
          DateTime.now().difference(entry.cachedAt) < _productCacheTTL) {
        return entry.list;
      }
    }

    List<ProductModel> productList = [];
    try {
      String url = '${Constant.baseUrl}restaurant/products?vendorID=${Constant.userModel!.vendorID}';
      debugPrint("getProduct $url ");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> productsData = jsonResponse['data'];
          debugPrint("======>");
          print(productsData.length);

          for (int i = 0; i < productsData.length; i++) {
            try {
              final productData = productsData[i];
              debugPrint("Processing product $i: ${productData['name']}");
              ProductModel productModel = ProductModel.fromJson(productData);
              productList.add(productModel);
            } catch (e, stackTrace) {
              debugPrint("Error processing product $i: $e");
              debugPrint("Stack trace: $stackTrace");
              debugPrint("Problematic product data: ${productsData[i]}");
              // Continue with next product instead of failing completely
              continue;
            }
          }
          if (vendorID != null) {
            _productCache[vendorID] = _ProductCacheEntry(productList, DateTime.now());
          }
        } else {
          debugPrint("No products found or API returned error");
        }
      } else {
        debugPrint("Failed to fetch products: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      debugPrint("Error fetching products: $error");
      return null;
    }
    return productList;
  }

  /// Active outlet for merchant/outlet sessions (outlet login or merchant picked outlet).
  static int resolveActiveOutletId() {
    final outletId = Preferences.getInt('outletId');
    if (outletId > 0) return outletId;
    return Preferences.getInt('selectedOutletId');
  }

  /// Resolves the outlet id to use for getOutletDetails (merchant list is source of truth).
  static Future<int?> resolveOutletIdForMenu({int? preferredId}) async {
    final loginType = Preferences.getString('loginType').trim().toUpperCase();

    // Fast path: reuse the previously resolved outlet id. This avoids
    // hitting getMerchantOutlets/fetchOutletById APIs on every menu access.
    if (preferredId == null ||
        preferredId == _cachedResolvedOutletId) {
      final cached = _cachedResolvedOutletId;
      if (cached != null &&
          cached > 0 &&
          _cachedResolvedOutletTime != null &&
          DateTime.now().difference(_cachedResolvedOutletTime!) <
              _resolvedOutletCacheTTL) {
        return cached;
      }
    }

    if (loginType == 'MERCHANT') {
      final merchantId = int.tryParse(Preferences.getString('merchantId')) ?? 0;
      if (merchantId <= 0) {
        _lastOutletProductsError =
            'Merchant session not found. Please log in again.';
        return null;
      }

      final outlets = await getMerchantOutlets(merchantId);
      if (outlets.isEmpty) {
        _lastOutletProductsError = 'No outlets found for this merchant.';
        return null;
      }

      final storedId = preferredId ?? resolveActiveOutletId();
      final storedName = Preferences.getString('selectedOutletName').trim();

      if (storedId > 0) {
        for (final outlet in outlets) {
          final id = outlet.outletId;
          if (id != null && id > 0 && id == storedId) {
            await _syncOutletPreferences(id, outletName: outlet.outletName);
            debugPrint('[resolveOutletIdForMenu] using list outletId=$id');
            _cachedResolvedOutletId = id;
            _cachedResolvedOutletTime = DateTime.now();
            return id;
          }
        }
      }

      if (storedName.isNotEmpty) {
        for (final outlet in outlets) {
          final name = (outlet.outletName ?? '').trim();
          final id = outlet.outletId;
          if (id != null &&
              id > 0 &&
              name.isNotEmpty &&
              name.toLowerCase() == storedName.toLowerCase()) {
            debugPrint(
              '[resolveOutletIdForMenu] corrected $storedId -> $id '
              'for outlet "$storedName"',
            );
            await _syncOutletPreferences(id, outletName: outlet.outletName);
            _cachedResolvedOutletId = id;
            _cachedResolvedOutletTime = DateTime.now();
            return id;
          }
        }
      }

      _lastOutletProductsError =
          'Selected outlet not found. Go back and select your outlet again.';
      return null;
    }

    final candidate = preferredId ?? resolveActiveOutletId();
    if (candidate <= 0) return null;

    final result = await fetchOutletById(candidate);
    if (!result.isSuccess ||
        result.outletId == null ||
        result.outletId! <= 0) {
      _lastOutletProductsError =
          result.message ?? 'Outlet session is invalid. Please log in again.';
      return null;
    }

    await _syncOutletPreferences(
      result.outletId!,
      outletName: result.outlet?.outletName,
    );
    _cachedResolvedOutletId = result.outletId;
    _cachedResolvedOutletTime = DateTime.now();
    return result.outletId;
  }

  static Future<void> _syncOutletPreferences(
    int outletId, {
    String? outletName,
  }) async {
    await Preferences.setInt('outletId', outletId);
    await Preferences.setInt('selectedOutletId', outletId);
    if (outletName != null && outletName.trim().isNotEmpty) {
      await Preferences.setString('selectedOutletName', outletName.trim());
    }
  }

  /// GET /api/fm/outlets/getOutletDetails — outlet-scoped inventory (Java API).
  /// Does not replace [getProduct]; use when an outlet is selected.
  static Future<OutletProductsResult?> getOutletDetailsWithProducts({
    int? outletId,
    bool forceRefresh = false,
  }) async {
    _lastOutletProductsError = null;

    final verifiedOutletId =
        await resolveOutletIdForMenu(preferredId: outletId);
    if (verifiedOutletId == null || verifiedOutletId <= 0) {
      _lastOutletProductsError =
          'Invalid outlet session. Please go back and select your outlet again.';
      return null;
    }

    final resolvedOutletId = verifiedOutletId;

    if (!forceRefresh) {
      final entry = _outletProductCache[resolvedOutletId];
      if (entry != null &&
          DateTime.now().difference(entry.cachedAt) < _productCacheTTL) {
        return entry.result;
      }
    }

    try {
      //final loginType = Preferences.getString('loginType').trim().toUpperCase();
      //final userType = loginType == 'OUTLET' ? 'OUTLET' : 'MERCHANT';
      final userType = 'MERCHANT';
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final url =
          '${Constant.baseUrl}fm/outlets/getOutletDetails'
          '?outletId=$resolvedOutletId&userType=$userType';

      debugPrint('getOutletProducts => $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('getOutletProducts status => ${response.statusCode}');
      debugPrint('getOutletProducts body => ${response.body}');

      if (response.statusCode != 200) {
        debugPrint(
          'getOutletProducts failed: ${response.statusCode} — ${response.body}',
        );
        try {
          final errBody = json.decode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            _lastOutletProductsError = errBody['message'].toString();
          } else {
            _lastOutletProductsError =
                'Failed to load outlet menu (HTTP ${response.statusCode})';
          }
        } catch (_) {
          _lastOutletProductsError =
              'Failed to load outlet menu (HTTP ${response.statusCode})';
        }
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        debugPrint('getOutletProducts: response is not a JSON object');
        _lastOutletProductsError = 'Invalid menu response from server';
        return const OutletProductsResult(products: [], categories: []);
      }

      final map = Map<String, dynamic>.from(decoded);
      if (map['success'] == false) {
        final msg = map['message']?.toString() ??
            'Could not load outlet menu';
        debugPrint('getOutletProducts API error: $msg');
        _lastOutletProductsError = msg;
        return null;
      }

      final dynamic rawData = map['data'] ?? map;
      Map<String, dynamic> detailsMap;
      if (rawData is Map) {
        detailsMap = Map<String, dynamic>.from(rawData);
      } else {
        debugPrint('getOutletProducts: no outlet details object in response');
        return const OutletProductsResult(products: [], categories: []);
      }

      final details = OutletDetailsModel.fromJson(detailsMap);
      final result = details.toProductsResult();
      debugPrint("========== PARSED PRODUCTS ==========");

      for (final p in result.products) {
        debugPrint(
          "Name=${p.name}, "
              "Id=${p.id}, "
              "Category=${p.categoryID}",
        );
      }

      debugPrint("Total Parsed Products = ${result.products.length}");
      _outletProductCache[resolvedOutletId] =
          _OutletProductsCacheEntry(result, DateTime.now());

      debugPrint(
        'getOutletProducts loaded ${result.products.length} products, '
        '${result.categories.length} categories',
      );

      return result;
    } catch (error, stackTrace) {
      debugPrint('getOutletProducts error: $error');
      print(stackTrace);
      _lastOutletProductsError = 'Failed to load outlet menu';
      return null;
    }
  }

  /// Call after outlet product writes to force next [getOutletProducts] to hit the API.
  static void invalidateOutletProductCache([int? outletId]) {
    if (outletId != null) {
      _outletProductCache.remove(outletId);
    } else {
      _outletProductCache.clear();
      // Outlet session may have changed; force re-resolving the outlet id.
      _cachedResolvedOutletId = null;
      _cachedResolvedOutletTime = null;
    }
  }

  /// Loads outlet menu as nested API model (used for edit/update outlet products).
  // static Future<OutletDetailsModel?> fetchOutletDetailsModel({
  //   int? outletId,
  // }) async {
  //   final verifiedOutletId =
  //       await resolveOutletIdForMenu(preferredId: outletId);
  //   if (verifiedOutletId == null || verifiedOutletId <= 0) {
  //     return null;
  //   }
  //
  //   try {
  //     final loginType = Preferences.getString('loginType').trim().toUpperCase();
  //     final userType = loginType == 'OUTLET' ? 'OUTLET' : 'MERCHANT';
  //     final token = Preferences.getString('authToken');
  //     final url =
  //         'http://187.127.156.147:8084/api/fm/outlets/getOutletDetails'
  //         '?outletId=$verifiedOutletId&userType=$userType';
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //
  //     if (response.statusCode != 200) return null;
  //
  //     final decoded = json.decode(response.body);
  //     if (decoded is! Map) return null;
  //
  //     final map = Map<String, dynamic>.from(decoded);
  //     if (map['success'] == false) return null;
  //
  //     final dynamic rawData = map['data'] ?? map;
  //     if (rawData is! Map) return null;
  //
  //     return OutletDetailsModel.fromJson(
  //       Map<String, dynamic>.from(rawData),
  //     );
  //   } catch (e, st) {
  //     debugPrint('fetchOutletDetailsModel error: $e $st');
  //     return null;
  //   }
  // }

  /// PUT /api/fm/outlets/editAndUpdateOutletProducts
  // static Future<bool> editAndUpdateOutletProducts({
  //   required OutletDetailsModel outletDetails,
  // }) async {
  //   final outletId = outletDetails.outletId ?? resolveActiveOutletId();
  //   if (outletId <= 0) return false;
  //
  //   try {
  //     final loginType = Preferences.getString('loginType').trim().toUpperCase();
  //     final userType = loginType == 'OUTLET' ? 'OUTLET' : 'MERCHANT';
  //     final token = Preferences.getString('authToken');
  //     final url =
  //         'http://187.127.156.147:8084/api/fm/outlets/editAndUpdateOutletProducts'
  //         '?outletId=$outletId&userType=$userType';
  //
  //     final response = await http.put(
  //       Uri.parse(url),
  //       headers: {
  //
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: json.encode(outletDetails.toJson()),
  //     );
  //
  //     debugPrint(
  //       'editAndUpdateOutletProducts status=${response.statusCode} '
  //       'body=${response.body}',
  //     );
  //
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       invalidateOutletProductCache(outletId);
  //       return true;
  //     }
  //     return false;
  //   } catch (e, st) {
  //     debugPrint('editAndUpdateOutletProducts error: $e $st');
  //     return false;
  //   }
  // }

  static Future<List<PromotionOutletProductModel>?> getOutletProductsDetailsOnlyForPromotions({required int outletId}) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/products/outlet/$outletId';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => PromotionOutletProductModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
      log('getOutletProductsFlat failed: ${response.statusCode} — ${response.body}');
      return null;
    } catch (e) {
      log('getOutletProductsFlat error: $e');
      return null;
    }
  }
  static Future<OutletSingleProductModel?> getOutletSingleProductDetails(int productId) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/products/getCompleteProductDetails/$productId';

      debugPrint('getOutletSingleProductDetails => $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('getOutletSingleProductDetails status => ${response.statusCode}');
      debugPrint('getOutletSingleProductDetails body => ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return OutletSingleProductModel.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      log('getOutletSingleProductDetails error: $e');
      return null;
    }
  }
  static Future<bool> updateSingleOutletProductDetails({
    required int productId,
    required OutletSingleProductModel originalProduct,
    required int categoryId,
    required String productName,
    required String description,
    required bool isVeg,
    required bool hasProductVariants,
    required num merchantPrice,
    required String imageLink,
    int? outletId,
    List<ProductVariantGroupModel>? variantGroupsOverride,
  }) async {
    try {
      final headers = await getHeaders();
      final url =
          '${Constant.baseUrl}fm/products/updateCategoryAndProductDetails/$productId';

      final body = json.encode(
        originalProduct.toUpdateJson(
          productName: productName,
          outletCategoryId: categoryId,
          description: description,
          isVeg: isVeg,
          hasProductVariants: hasProductVariants,
          merchantPrice: merchantPrice,
          imageLink: imageLink,
          variantGroupsOverride: variantGroupsOverride,
        ),
      );

      debugPrint('updateSingleOutletProductDetails => $url');
      debugPrint('updateSingleOutletProductDetails body => $body');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      debugPrint(
        'updateSingleOutletProductDetails status => ${response.statusCode}',
      );
      debugPrint(
        'updateSingleOutletProductDetails resp => ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        invalidateOutletProductCache(outletId);
        return true;
      }

      return false;
    } catch (e) {
      log('updateSingleOutletProductDetails error: $e');
      return false;
    }
  }

  /// Updates one outlet product inside the nested outlet menu payload.
  // static Future<bool> updateOutletProductItem({
  //   required int productId,
  //   required OutletProductModel updatedProduct,
  //   int? outletId,
  // }) async {
  //   final details = await fetchOutletDetailsModel(outletId: outletId);
  //   if (details == null) return false;
  //   if (details.findProductById(productId) == null) return false;
  //
  //   final payload = details.copyWithUpdatedProduct(
  //     productId: productId,
  //     updatedProduct: updatedProduct,
  //   );
  //
  //   return editAndUpdateOutletProducts(outletDetails: payload);
  // }

  /// Call after any product write (set/update/delete) to force next getProduct() to hit the API.
  static void invalidateProductCache([String? vendorID]) {
    if (vendorID != null) {
      _productCache.remove(vendorID);
    } else {
      _productCache.clear();
    }
  }

  /// Call after category or product bulk updates so next getVendorCategoryById() hits the API.
  static void invalidateVendorCategoryCache() {
    _cachedVendorCategories = null;
    _vendorCategoriesCacheTime = null;
  }

  static Future<List<AdvertisementModel>?> getAdvertisement() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}advertisements?vendorId=${Constant.userModel!.vendorID}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<AdvertisementModel> advertisementList = [];

          for (var element in responseData['data']) {
            AdvertisementModel advertisementModel = AdvertisementModel.fromJson(element);
            advertisementList.add(advertisementModel);
          }
          advertisementList.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return advertisementList;
        } else {
          log('API returned success: false');
          return null;
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
  }

  static Future<AdvertisementModel> getAdvertisementById({
    required String advertisementId,
  }) async {
    AdvertisementModel advertisementdata = AdvertisementModel();

    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}advertisements/$advertisementId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          AdvertisementModel advertisementModel =
          AdvertisementModel.fromJson(responseData['data']);
          advertisementdata = advertisementModel;
        } else {
          log('API returned success: false for advertisement ID: $advertisementId');
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      log(error.toString());
    }

    return advertisementdata;
  }
  /// GET /api/fm/product-variant-groups — cached, same TTL pattern as categories.
  static Future<List<VariantGroupModel>?> getProductVariantGroups() async {
    if (_cachedVariantGroups != null &&
        _variantGroupsCacheTime != null &&
        DateTime.now().difference(_variantGroupsCacheTime!) < _variantGroupsCacheTTL) {
      return _cachedVariantGroups!;
    }

    try {
      final url = '${Constant.baseUrl}fm/product-variant-groups';
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint("getProductVariantGroups => $url");
      debugPrint("Status Code => ${response.statusCode}");
      debugPrint("Response => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Failed to load variant groups: ${response.statusCode}");
      }

      final List<dynamic> data = jsonDecode(response.body);
      final groups = data
          .map((e) => VariantGroupModel.fromJson(Map<String, dynamic>.from(e)))
          .where((g) => g.isActive)
          .toList();

      _cachedVariantGroups = groups;
      _variantGroupsCacheTime = DateTime.now();
      return groups;
    } catch (e) {
      debugPrint("Error fetching variant groups: $e");
      return null;
    }
  }

  /// GET /api/fm/product-variant-groups/{groupId}/values — not cached long-term
  /// since values can be added mid-session; caller (controller) should cache
  /// per groupId for the lifetime of the sheet only.
  static Future<List<VariantGroupValueModel>?> getVariantGroupValues(int groupId) async {
    try {
      final url = '${Constant.baseUrl}fm/product-variant-groups/$groupId/values';
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint("getVariantGroupValues => $url");
      debugPrint("Status Code => ${response.statusCode}");
      debugPrint("Response => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Failed to load values: ${response.statusCode}");
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => VariantGroupValueModel.fromJson(Map<String, dynamic>.from(e)))
          .where((v) => v.isActive)
          .toList();
    } catch (e) {
      debugPrint("Error fetching group values: $e");
      return null;
    }
  }

  /// POST /api/fm/product-variant-groups/{groupId}/values — called when the
  /// merchant types a value name that isn't in the dropdown yet.
  static Future<VariantGroupValueModel?> createVariantGroupValue({
    required int groupId,
    required String variantName,
  }) async {
    try {
      final url = '${Constant.baseUrl}fm/product-variant-groups/$groupId/values';
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'variantName': variantName}),
      );

      debugPrint("createVariantGroupValue => $url : $variantName");
      debugPrint("Status Code => ${response.statusCode}");
      debugPrint("Response => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Failed to create value: ${response.statusCode}");
      }

      return VariantGroupValueModel.fromJson(jsonDecode(response.body));
    } catch (e) {
      debugPrint("Error creating group value: $e");
      return null;
    }
  }
  /// GET /api/fm/products/{productId}/variant-options
  /// Loads whatever variants already exist on this outlet product.
  /// The endpoint only returns groupName (a string), never the group's id,
  /// so we resolve the real groupId by matching against the master group list.
  static Future<List<StagedVariantGroup>?> getProductVariantOptions(
      int productId, {
        List<VariantGroupModel>? knownGroups,
      }) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/products/$productId/variant-options';
      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint('getProductVariantOptions => $url');
      debugPrint('Status Code => ${response.statusCode}');
      debugPrint('Response => ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load variant options: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return [];

      final groups = knownGroups ?? await getProductVariantGroups() ?? [];
      final groupsByName = {for (final g in groups) g.groupName: g};

      final Map<String, List<StagedVariantOption>> grouped = {};
      for (final raw in data) {
        final json = Map<String, dynamic>.from(raw);
        final groupName = json['groupName'] as String? ?? 'Unknown';
        grouped.putIfAbsent(groupName, () => []).add(
          StagedVariantOption(
            productVariantOptionsId: json['productVariantOptionsId'] ?? 0,
            productVariantGroupValuesId: json['productVariantGroupValuesId'] ?? 0,
            variantName: json['variantName'] ?? '',
            priceType: json['priceType'] ?? 'MAIN',
            variantPrice: (json['variantPrice'] as num?)?.toDouble() ?? 0,
          ),
        );
      }

      return grouped.entries.map((e) {
        final matched = groupsByName[e.key];
        // groupId falls back to 0 only if the group was renamed/deleted
        // server-side since this option was saved — an edge case worth
        // logging if it ever actually happens.
        return StagedVariantGroup(
          groupId: matched?.id ?? 0,
          groupName: e.key,
          options: e.value,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching product variant options: $e');
      return null;
    }
  }

  /// POST /api/fm/products/{productId}/variant-options — adds ONE new option row.
  static Future<bool> addProductVariantOption({
    required int productId,
    required int productVariantGroupValuesId,
    required String priceType,
    required double variantPrice,
  }) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/products/$productId/variant-options';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'productVariantGroupValuesId': productVariantGroupValuesId,
          'priceType': priceType,
          'variantPrice': variantPrice,
        }),
      );
      debugPrint('addProductVariantOption => $url');
      debugPrint('Status Code => ${response.statusCode}');
      debugPrint('Response => ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding variant option: $e');
      return false;
    }
  }

  /// DELETE /api/fm/products/{productId}/variant-options/{optionId}
  static Future<bool> deleteProductVariantOption({
    required int productId,
    required int optionId,
  }) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/products/$productId/variant-options/$optionId';
      final response = await http.delete(Uri.parse(url), headers: headers);
      debugPrint('deleteProductVariantOption => $url');
      debugPrint('Status Code => ${response.statusCode}');
      debugPrint('Response => ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting variant option: $e');
      return false;
    }
  }

  static Future<CreateMasterProductResponse?> createMasterProduct(CreateMasterProductRequest request,) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/master-products/create',
        ),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      debugPrint(response.body);

      return CreateMasterProductResponse.fromJson(
        jsonDecode(response.body),
      );
    } catch (e) {
      debugPrint(
        "createMasterProduct Error => $e",
      );
      return null;
    }
  }
  // static Future<bool> updateProduct(ProductModel productModel) async {
  //   bool isUpdate = false;
  //   try {
  //     log("updateProduct ${productModel.toJson()} ");
  //     debugPrint("updateProduct url  ${productModel.id} ");
  //     final response = await http.post(
  //       Uri.parse('${Constant.baseUrl}restaurant/products'
  //           // '/${productModel.id}'
  //       ),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode(productModel.toJson()),
  //     );
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       isUpdate = true;
  //       invalidateProductCache(Constant.userModel?.vendorID);
  //     } else {
  //       debugPrint("Failed to update product: ${response.statusCode} - ${response.body}");
  //       isUpdate = false;
  //     }
  //   } catch (error) {
  //     debugPrint("Failed to update productss: $error");
  //     isUpdate = false;
  //   }
  //   return isUpdate;
  // }

  /// Updates a master product via the Java API PUT endpoint.
  static Future<bool> updateMasterProduct(int masterProductId, Map<String, dynamic> payload) async {
    try {
      // final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/master-products/$masterProductId';
      log('updateMasterProduct PUT $url');
      log('updateMasterProduct payload: ${json.encode(payload)}');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,

        body: json.encode(payload),
      );
      log('updateMasterProduct response: ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateProductCache(Constant.userModel?.vendorID);
        return true;
      } else {
        debugPrint('updateMasterProduct failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('updateMasterProduct error: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(ProductModel productModel) async {
    bool isDeleted = false;

    try {
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}restaurant/products/${productModel.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateProductCache(Constant.userModel?.vendorID);
        invalidateVendorCategoryCache();
        isDeleted = true;
      } else {
        debugPrint("Failed to delete product: ${response.statusCode} - ${response.body}");
        isDeleted = false;
      }
    } catch (error) {
      debugPrint("Failed to delete product: $error");
      isDeleted = false;
    }

    return isDeleted;
  }
  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionList = [];

    try {
      final String userId = await FireStoreUtils.getCurrentUid(); // Get current user ID

      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/transactions?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          // Parse the list of transactions from the response
          List<dynamic> transactions = responseData['data'];

          for (var transactionData in transactions) {
            try {
              WalletTransactionModel walletTransactionModel =
              WalletTransactionModel.fromJson(transactionData);
              walletTransactionList.add(walletTransactionModel);
            } catch (e) {
              log('Error parsing transaction: $e');
            }
          }

          // Sort by date in descending order (most recent first)
          walletTransactionList.sort((a, b) {
            // Handle different date types - API returns String, Firebase uses Timestamp
            DateTime? dateA = _parseDate(a.date);
            DateTime? dateB = _parseDate(b.date);

            // Handle null cases
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1; // Put null dates at the end
            if (dateB == null) return -1; // Put null dates at the end

            return dateB.compareTo(dateA); // Descending order
          });
        }
      } else {
        throw Exception('Failed to load wallet transactions: ${response.statusCode}');
      }
    } catch (error) {
      log('getWalletTransaction error: $error');
        return null;
    }

    return walletTransactionList;
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;

    if (date is String) {
      // Remove extra quotes if they exist
      String dateString = date.replaceAll('"', '');
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        log('Error parsing date string: $dateString');
        return null;
      }
    } else if (date is Timestamp) {
      return date.toDate();
    } else if (date is DateTime) {
      return date;
    }

    return null;
  }

  static Future<List<WalletTransactionModel>?> getFilterWalletTransaction(
      Timestamp startTime, Timestamp endTime) async {
    try {
      String startTimeIso = startTime.toDate().toUtc().toIso8601String();
      String endTimeIso = endTime.toDate().toUtc().toIso8601String();
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/transactions/filtered'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': FireStoreUtils.getCurrentUid(),
          'startTime': startTimeIso,
          'endTime': endTimeIso,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<WalletTransactionModel> walletTransactionList = [];

          // Parse the data array from response
          final List<dynamic> transactions = responseData['data'];

          for (var transactionData in transactions) {
            try {
              WalletTransactionModel walletTransactionModel =
              WalletTransactionModel.fromJson(transactionData);
              walletTransactionList.add(walletTransactionModel);
            } catch (e) {
              log("Error parsing transaction: $e");
            }
          }

          walletTransactionList.sort((a, b) {
            final aDate = a.date;
            final bDate = b.date;

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1; // Put null dates at the end
            if (bDate == null) return -1; // Put null dates at the end

            return bDate.compareTo(aDate); // Descending order
          });

          return walletTransactionList;
        } else {
          log("API returned error: ${responseData['message']}");
          return null;
        }
      } else {
        log("Failed to get wallet transactions: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      log("Error getting wallet transactions: $error");
      return null;
    }
  }
  static Future<List<WithdrawalModel>?> getWithdrawHistory() async {
    List<WithdrawalModel> walletTransactionList = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/withdraw-history?vendorID=${Constant.userModel!.vendorID.toString()}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          for (var element in data) {
            WithdrawalModel walletTransactionModel = WithdrawalModel.fromJson(element);
            walletTransactionList.add(walletTransactionModel);
          }
          walletTransactionList.sort((a, b) {
            if (a.paidDate == null && b.paidDate == null) return 0;
            if (a.paidDate == null) return 1; // put a after b
            if (b.paidDate == null) return -1; // put a before b
            return b.paidDate!.compareTo(a.paidDate!);
          });
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load withdrawal history: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      return null;
    }

    return walletTransactionList;
  }

  static Future getPaymentSettingsData() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}settings/payment'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> paymentData = responseData['data'];
          if (paymentData['payFastSettings'] != null) {
            PayFastModel payFastModel = PayFastModel.fromJson(paymentData['payFastSettings']);
            await Preferences.setString(
                Preferences.payFastSettings,
                jsonEncode(payFastModel.toJson())
            );
          }

          if (paymentData['MercadoPago'] != null) {
            MercadoPagoModel mercadoPagoModel = MercadoPagoModel.fromJson(paymentData['MercadoPago']);
            await Preferences.setString(
                Preferences.mercadoPago,
                jsonEncode(mercadoPagoModel.toJson())
            );
          }

          if (paymentData['paypalSettings'] != null) {
            PayPalModel payPalModel = PayPalModel.fromJson(paymentData['paypalSettings']);
            await Preferences.setString(
                Preferences.paypalSettings,
                jsonEncode(payPalModel.toJson())
            );
          }

          if (paymentData['stripeSettings'] != null) {
            StripeModel stripeModel = StripeModel.fromJson(paymentData['stripeSettings']);
            await Preferences.setString(
                Preferences.stripeSettings,
                jsonEncode(stripeModel.toJson())
            );
          }

          if (paymentData['flutterWave'] != null) {
            FlutterWaveModel flutterWaveModel = FlutterWaveModel.fromJson(paymentData['flutterWave']);
            await Preferences.setString(
                Preferences.flutterWave,
                jsonEncode(flutterWaveModel.toJson())
            );
          }

          if (paymentData['payStack'] != null) {
            PayStackModel payStackModel = PayStackModel.fromJson(paymentData['payStack']);
            await Preferences.setString(
                Preferences.payStack,
                jsonEncode(payStackModel.toJson())
            );
          }

          if (paymentData['PaytmSettings'] != null) {
            PaytmModel paytmModel = PaytmModel.fromJson(paymentData['PaytmSettings']);
            await Preferences.setString(
                Preferences.paytmSettings,
                jsonEncode(paytmModel.toJson())
            );
          }

          if (paymentData['walletSettings'] != null) {
            WalletSettingModel walletSettingModel = WalletSettingModel.fromJson(paymentData['walletSettings']);
            await Preferences.setString(
                Preferences.walletSettings,
                jsonEncode(walletSettingModel.toJson())
            );
          }

          if (paymentData['razorpaySettings'] != null) {
            RazorPayModel razorPayModel = RazorPayModel.fromJson(paymentData['razorpaySettings']);
            await Preferences.setString(
                Preferences.razorpaySettings,
                jsonEncode(razorPayModel.toJson())
            );
          }

          if (paymentData['CODSettings'] != null) {
            CodSettingModel codSettingModel = CodSettingModel.fromJson(paymentData['CODSettings']);
            await Preferences.setString(
                Preferences.codSettings,
                jsonEncode(codSettingModel.toJson())
            );
          }

          if (paymentData['midtrans_settings'] != null) {
            MidTrans midTrans = MidTrans.fromJson(paymentData['midtrans_settings']);
            await Preferences.setString(
                Preferences.midTransSettings,
                jsonEncode(midTrans.toJson())
            );
          }

          if (paymentData['orange_money_settings'] != null) {
            OrangeMoney orangeMoney = OrangeMoney.fromJson(paymentData['orange_money_settings']);
            await Preferences.setString(
                Preferences.orangeMoneySettings,
                jsonEncode(orangeMoney.toJson())
            );
          }

          if (paymentData['xendit_settings'] != null) {
            Xendit xendit = Xendit.fromJson(paymentData['xendit_settings']);
            await Preferences.setString(
                Preferences.xenditSettings,
                jsonEncode(xendit.toJson())
            );
          }
        } else {
          throw Exception('API returned unsuccessful response');
        }
      } else {
        throw Exception('Failed to load payment settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching payment settings: $e');
      rethrow;
    }
  }
  static Future<VendorModel?> getVendorById(String vendorId, {bool forceRefresh = false}) async {
    VendorModel? vendorModel;
    try {
      // Performance Optimization: Check cache first (transparent to caller)
      if (!forceRefresh &&
          _cachedVendor != null &&
          _cachedVendorId == vendorId &&
          _vendorCacheTime != null) {
        final cacheAge = DateTime.now().difference(_vendorCacheTime!);
        if (cacheAge < _vendorCacheTTL) {
          log("getVendorById: Returning cached data (age: ${cacheAge.inSeconds}s)");
          return _cachedVendor;
        }
      }

      debugPrint("getVendorById  ");
      if (vendorId.isNotEmpty) {
        final response = await http.get(
          Uri.parse('${Constant.baseUrl}restaurant/vendors/$vendorId'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          debugPrint("getVendorById  ${response.body}");
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            vendorModel = VendorModel.fromJson(responseData['data']);
            debugPrint("getVendorById  ${response.body}");

            // Performance Optimization: Cache the result
            _cachedVendor = vendorModel;
            _cachedVendorId = vendorId;
            _vendorCacheTime = DateTime.now();
          }
        } else if (response.statusCode == 404) {
          return null;
        } else {
          throw Exception('Failed to load vendor: ${response.statusCode}');
        }
      }
    } catch (e, s) {
      log('getVendorById error: $e $s');
      return null;
    }
    return vendorModel;
  }



  static Future<List<VendorCategoryModel>?> getAllMasterCategories() async {
    if (_cachedVendorCategories != null &&
        _vendorCategoriesCacheTime != null &&
        DateTime.now().difference(_vendorCategoriesCacheTime!) <
            _vendorCategoriesCacheTTL) {
      return _cachedVendorCategories!;
    }

    try {
      String url = '${Constant.baseUrl}fm/getHomeOrAllCategories?filter=ALL';

      debugPrint("getVendorCategoryById => $url");
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint("Status Code => ${response.statusCode}");
      debugPrint("Response => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to load categories: ${response.statusCode}");
      }

      final Map<String, dynamic> jsonResponse =
      jsonDecode(response.body);

      if (jsonResponse["success"] != true) {
        throw Exception(
            jsonResponse["message"] ?? "Failed to load categories");
      }

      final List<dynamic> data =
          jsonResponse["data"] ?? [];

      final List<VendorCategoryModel> categories =
      data.map((item) {
        return VendorCategoryModel.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      _cachedVendorCategories = categories;
      _vendorCategoriesCacheTime = DateTime.now();

      debugPrint(
          "Loaded Categories => ${categories.length}");

      return categories;
    } catch (e) {
      debugPrint(
          "Error fetching categories: $e");
      return null;
    }
  }

  static Future<bool> createCategory({
    required String categoryName,
    required String categoryType,
    required String categoryImageUrl,
    required int createdBy,
  }) async {
    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/createCategory',
        ),
        headers: headers,
        body: jsonEncode({
          "categoryName": categoryName,
          "categoryType": categoryType,
          "categoryImageUrl": categoryImageUrl,
          "createdBy": createdBy,
        }),
      );

      debugPrint(response.body);

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }
  static Future<ProductModel?> getProductById(String productId) async {
    ProductModel? productModel;

    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          productModel = ProductModel.fromJson(jsonResponse['data']);
        } else {
          debugPrint("Product not found or API returned error");
        }
      } else {
        debugPrint("Failed to fetch product: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e, s) {
      debugPrint('getProductById error: $e $s');
      return null;
    }

    return productModel;
  }
  static Future<VendorCategoryModel?> getVendorCategoryByCategoryId(String categoryId) async {
    VendorCategoryModel? vendorCategoryModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/vendor-categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          vendorCategoryModel = VendorCategoryModel.fromJson(responseData['data']);
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load vendor category: ${response.statusCode}');
      }
    } catch (e, s) {
      log('getVendorCategoryByCategoryId error: $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<ReviewAttributeModel?> getVendorReviewAttribute(String attributeId) async {
    ReviewAttributeModel? vendorCategoryModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/review-attributes/$attributeId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          vendorCategoryModel = ReviewAttributeModel.fromJson(responseData['data']);
        }
      } else {
        throw Exception('Failed to load review attribute: ${response.statusCode}');
      }
    } catch (e, s) {
      log('getVendorReviewAttribute error: $e $s');
      return null;
    }
    return vendorCategoryModel;
  }
  static Future<List<AttributesModel>?> getAttributes() async {
    List<AttributesModel> attributeList = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/attributes'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> attributesData = responseData['data'];

          for (var element in attributesData) {
            AttributesModel attributeModel = AttributesModel.fromJson(element);
            attributeList.add(attributeModel);
          }
        }
      } else {
        throw Exception('Failed to load attributes: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
    return attributeList;
  }

  static Future<DeliveryCharge?> getDeliveryCharge({bool forceRefresh = false}) async {
    DeliveryCharge? deliveryCharge;
    try {
      // Performance Optimization: Check cache first (transparent to caller)
      if (!forceRefresh &&
          _cachedDeliveryCharge != null &&
          _deliveryChargeCacheTime != null) {
        final cacheAge = DateTime.now().difference(_deliveryChargeCacheTime!);
        if (cacheAge < _deliveryChargeCacheTTL) {
          log("getDeliveryCharge: Returning cached data (age: ${cacheAge.inSeconds}s)");
          return _cachedDeliveryCharge;
        }
      }

      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/delivery-charge'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          deliveryCharge = DeliveryCharge.fromJson(responseData['data']);

          // Performance Optimization: Cache the result
          _cachedDeliveryCharge = deliveryCharge;
          _deliveryChargeCacheTime = DateTime.now();
        }
      } else {
        throw Exception('Failed to load delivery charge: ${response.statusCode}');
      }
    } catch (e, s) {
      log('getDeliveryCharge error: $e $s');
      return null;
    }
    return deliveryCharge;
  }



  static Future<List<CouponModel>> getAllVendorCoupons(String vendorId) async {
    List<CouponModel> coupon = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}coupons/vendor/$vendorId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> couponsData = responseData['data'];
          for (var element in couponsData) {
            if (_isCouponValid(element)) {
              CouponModel couponModel = CouponModel.fromJson(element);
              coupon.add(couponModel);
            }
          }
        }
      } else {
        throw Exception('Failed to load vendor coupons: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
    }
    return coupon;
  }

// Helper method to check if coupon meets all criteria
  static bool _isCouponValid(Map<String, dynamic> couponData) {
    // Check if coupon is enabled
    if (couponData['isEnabled'] != true && couponData['isEnabled'] != 1) {
      return false;
    }

    // Check if coupon is public
    if (couponData['isPublic'] != true && couponData['isPublic'] != 1) {
      return false;
    }

    // Check expiration date
    if (couponData['expiresAt'] != null) {
      DateTime expiresAt;

      // Handle different timestamp formats
      if (couponData['expiresAt'] is String) {
        expiresAt = DateTime.parse(couponData['expiresAt']);
      } else if (couponData['expiresAt'] is Map) {
        // Handle Firebase timestamp format if needed
        final timestamp = couponData['expiresAt'];
        if (timestamp['_seconds'] != null) {
          expiresAt = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
        } else {
          return false;
        }
      } else {
        return false;
      }

      // Check if coupon hasn't expired
      if (expiresAt.isBefore(DateTime.now())) {
        return false;
      }
    } else {
      return false; // No expiration date provided
    }
    return true;
  }
  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/orders'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(orderModel.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isAdded = true;
      } else {
        debugPrint("Failed to create order: ${response.statusCode} - ${response.body}");
        isAdded = false;
      }
    } catch (error) {
      debugPrint("Failed to create order: $error");
      isAdded = false;
    }

    return isAdded;
  }


  static Future<bool?> setCoupon(CouponModel orderModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}coupons'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: orderModel.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        log("Failed to add coupon: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Failed to add coupon: $error");
      return false;
    }
  }
  static Future<bool?> deleteCoupon(CouponModel couponModel) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}coupons/${couponModel.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        } else {
          debugPrint('API returned unsuccessful response: ${jsonResponse['message']}');
          return false;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Coupon not found (404)');
        return false;
      } else {
        debugPrint('Failed to delete coupon: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting coupon: $e');
      return false;
    }
  }

  static Future<List<CouponModel>> getOffer(String vendorId) async {
    List<CouponModel> list = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}offers/vendor/$vendorId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> offersData = responseData['data'];
          for (var element in offersData) {
            CouponModel couponModel = CouponModel.fromJson(element);
            list.add(couponModel);
          }
        }
      } else {
        throw Exception('Failed to load vendor offers: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
    }
    return list;
  }


  static Future<bool> createProductPromotion(
      Map<String, dynamic> promotionData) async {
    try {
      log('createProductPromotion payload: ${jsonEncode(promotionData)}');
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}vendor/promotions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(promotionData),
      );
      log('createProductPromotion response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e, s) {
      log('createProductPromotion error: $e $s');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getProductPromotions(
      String vendorId) async {
    final List<Map<String, dynamic>> list = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}promotions/vendor/$vendorId'),
        headers: {'Content-Type': 'application/json'},
      );
      log('getProductPromotions response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true &&
            responseData['data'] is List<dynamic>) {
          for (final item in (responseData['data'] as List<dynamic>)) {
            if (item is Map<String, dynamic>) {
              list.add(item);
            }
          }
        }
      }
    } catch (e, s) {
      log('getProductPromotions error: $e $s');
    }
    return list;
  }

  static Future<bool> updateProductPromotion(
      String promotionId, Map<String, dynamic> promotionData) async {
    try {
      log('updateProductPromotion[$promotionId] payload: ${jsonEncode(promotionData)}');
      final response = await http.put(
        Uri.parse('${Constant.baseUrl}vendor/promotions/$promotionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(promotionData),
      );
      log('updateProductPromotion response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e, s) {
      log('updateProductPromotion error: $e $s');
      return false;
    }
  }

  static Future<bool> deleteProductPromotion(String promotionId) async {
    try {
      log('deleteProductPromotion[$promotionId]');

      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}vendor/promotions/$promotionId'),
        headers: {'Content-Type': 'application/json'},
      );

      log('deleteProductPromotion response: ${response.statusCode} ${response.body}');

      return response.statusCode == 200;
    } catch (e, s) {
      log('deleteProductPromotion error: $e $s');
      return false;
    }
  }

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    try {
      String url = '${Constant.baseUrl}documents';
      debugPrint(" getDocumentList  $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint(" getDocumentList  ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> documentsData = responseData['data'];
          for (var element in documentsData) {
            if (element['type'] == "restaurant" && element['enable'] == 1) {
              DocumentModel documentModel = DocumentModel.fromJson(element);
              documentList.add(documentModel);
            }
          }
        }
      } else {
        throw Exception('Failed to load documents: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
    }
    return documentList;
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    try {
      // String? userId = await getFirebaseId();
   String url =    '${Constant.baseUrl}documents/driver';
      // debugPrint("getDocumentOfDriver userId: $userId  $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // "userId": userId,
        }),
      );
      debugPrint("API Status Code: ${response.statusCode}");
      debugPrint("API Response: ${response.body}");
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return DriverDocumentModel.fromJson(jsonResponse['data']);
        } else if (jsonResponse['success'] == true && jsonResponse['data'] == null) {
          debugPrint('No document found for driver');
          return null;
        } else {
          throw Exception('API unsuccessful: ${jsonResponse['message']}');
        }
      } else if (response.statusCode == 404) {
        debugPrint('Driver document not found (404)');
        return null;
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching driver document: $e');
      return null;
    }
  }


  static Future<InboxModel> addRestaurantInbox(InboxModel inboxModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-restaurant/inbox'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(inboxModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return inboxModel;
      } else {
        throw Exception('Failed to add restaurant inbox: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add restaurant inbox: $e');
    }
  }


  static Future<InboxModel> addAdminInbox(InboxModel inboxModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-admin/inbox'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(inboxModel.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return inboxModel;
      } else {
        throw Exception('Failed to add admin inbox: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add admin inbox: $e');
    }
  }


  static Future<ConversationModel> addRestaurantChat(ConversationModel conversationModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-restaurant/thread'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: conversationModel.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return conversationModel;
      } else {
        throw Exception('Failed to add chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add chat: $e');
    }
  }

  static Future<ConversationModel> addAdminChat(ConversationModel conversationModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-admin/thread'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(conversationModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return conversationModel;
      } else {
        throw Exception('Failed to add admin chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add admin chat: $e');
    }
  }
  static Future<bool> uploadDriverDocument(Documents documents) async {
    String userId = await FireStoreUtils.getCurrentUid();
    bool isAdded = false;

    debugPrint("------------ Document Upload Debug Log ------------");
    debugPrint("User ID      : $userId");
    debugPrint("documentId   : ${documents.documentId}");
    debugPrint("status       : ${documents.status}");
    debugPrint("type         : restaurant");
    debugPrint("frontImage   : ${documents.frontImage}");
    debugPrint("backImage    : ${documents.backImage}");
    debugPrint("--------------------------------------------------");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constant.baseUrl}documents/driver/upload'),
      );
      // === IMPORTANT: Use backend-expected field names ===
      request.fields['user_id'] = userId;
      request.fields['documentId'] = documents.documentId ?? '';
      request.fields['status'] = documents.status ?? '';
      request.fields['type'] = 'restaurant';
      // === FRONT IMAGE FILE ===
      if (documents.frontImage != null &&
          documents.frontImage!.isNotEmpty &&
          !documents.frontImage!.startsWith('http')) {
        final file = File(documents.frontImage!);
        debugPrint("Front exists: ${file.existsSync()} / Size: ${file.lengthSync()}");
        if (file.existsSync() && file.lengthSync() > 0) {
          request.files.add(await http.MultipartFile.fromPath(
            'front_image',   // <-- CHANGE TO MATCH LARAVEL
            documents.frontImage!,
          ));
        }
      }

      // === BACK IMAGE FILE ===
      if (documents.backImage != null &&
          documents.backImage!.isNotEmpty &&
          !documents.backImage!.startsWith('http')) {
        final file = File(documents.backImage!);
        debugPrint("Back exists: ${file.existsSync()} / Size: ${file.lengthSync()}");
        if (file.existsSync() && file.lengthSync() > 0) {
          request.files.add(await http.MultipartFile.fromPath(
            'back_image',    // <-- CHANGE TO MATCH LARAVEL
            documents.backImage!,
          ));
        }
      }
      // SEND REQUEST
      var response = await request.send();
      debugPrint("📤 uploadDriverDocument Status: ${response.statusCode}");

      // READ RESPONSE BODY
      final respStr = await response.stream.bytesToString();
      debugPrint("📥 Response Body: $respStr");

      isAdded = response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error uploading document: $e");
    }

    return isAdded;
  }

  static Future<DeliveryCharge?> getDelivery() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/delivery-charge'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DeliveryCharge.fromJson(jsonData);
      } else {
        debugPrint('Failed to load delivery charge: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching delivery charge: $e');
      return null;
    }
  }

  static Future<VendorModel> firebaseCreateNewVendor(VendorModel vendor) async {
    try {
      String vendorId = const Uuid().v4();
      vendor.id = vendorId;
      Map<String, dynamic> requestBody = _convertVendorToJson(vendor);
      log("firebaseCreateNewVendor  ${requestBody}");
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/vendors'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      log(" firebaseCreateNewVendor response ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            VendorModel createdVendor = VendorModel.fromJson(jsonResponse['data']);
            // Constant.userModel!.id = userId;
            Constant.userModel!.vendorID = createdVendor.id ?? vendorId;
            vendor.fcmToken = Constant.userModel!.fcmToken;
            Constant.vendorAdminCommission = createdVendor.adminCommission ?? vendor.adminCommission;
            await updateUser(Constant.userModel!);
            return createdVendor;
          } else {
            // Constant.userModel!.id = userId;
            Constant.userModel!.vendorID = vendorId;
            vendor.fcmToken = Constant.userModel!.fcmToken;
            Constant.vendorAdminCommission = vendor.adminCommission;
            await updateUser(Constant.userModel!);
            return vendor;
          }
        } else {
          throw Exception('API returned unsuccessful response: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to create vendor: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating vendor: $e');
      rethrow;
    }
  }
  // THIS IS JAVA API OF CREATING NEW OUTLET API POST METHOD
  static Future<OutletModel?> createOutlet(Map<String, dynamic> body) async {

    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/outlets/createOutlet',
        ),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint("STATUS CODE = ${response.statusCode}");
      debugPrint("RESPONSE = ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];
        if (data is Map<String, dynamic>) {
          return OutletModel.fromJsonSafe(data);
        }
        if (data is Map) {
          return OutletModel.fromJsonSafe(Map<String, dynamic>.from(data));
        }
      }

      return null;

    } catch (e) {
      debugPrint("CREATE OUTLET ERROR = $e");
      return null;
    }
  }
// END OF THIS APIJ
// GET OUTLET PROFILE STARTED
  static Future<OutletModel?> getOutletProfile(int outletId) async {
    try {
      if (outletId <= 0) {
        debugPrint("Outlet ID is invalid");
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      //final token = prefs.getString('authToken') ?? '';
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/outlets/getOutletById/$outletId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint("getOutletProfile Status: ${response.statusCode}");
      debugPrint("getOutletProfile Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData is Map<String, dynamic> && jsonData['data'] is Map
            ? Map<String, dynamic>.from(jsonData['data'] as Map)
            : Map<String, dynamic>.from(jsonData as Map);
        return OutletModel.fromJson(data);
      }
      return null;
    } catch (e, st) {
      debugPrint("getOutletProfile Error: $e");
      print(st);
      return null;
    }
  }
//END
 // UPDATE OUTLET PROFILE  STARTED
  static Future<bool> updateOutletProfile(int outletId, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //final token = prefs.getString('authToken') ?? '';
     final headers = await getHeaders();
      final url =
          '${Constant.baseUrl}fm/outlets/updateOutletDetailsByMerchant/$outletId';

      debugPrint("===== UPDATE OUTLET REQUEST =====");
      debugPrint(json.encode(body));

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint("updateOutletProfile Status: ${response.statusCode}");
      debugPrint("updateOutletProfile Body: ${response.body}");

      if (response.statusCode == 200) {
        log("updateOutletProfile success: ${response.body}");
        return true;
      } else {
        log("updateOutletProfile failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      log("updateOutletProfile error: $e");
      return false;
    }
  }
//ENDED
// UPLOAD OUTLET IMAGE STARTED
  /// POST /api/fm/outlets/{outletId}/image — uploads the outlet image to the
  /// Java backend via multipart/form-data. Returns the uploaded image URL on
  /// success, otherwise null.
  static Future<String?> uploadOutletImage({
    required int outletId,
    required File image,
  }) async {
    try {
      if (outletId <= 0 || !image.existsSync()) {
        debugPrint("uploadOutletImage: invalid outletId or image file");
        return null;
      }

      final token = await getAuthToken();
      final url = '${Constant.baseUrl}fm/outlets/$outletId/image';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = token;
      }

      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: image.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      );

      debugPrint("uploadOutletImage URL: $url");

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint("uploadOutletImage Status: ${response.statusCode}");
      debugPrint("uploadOutletImage Body: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic> &&
            jsonData['success'] == true &&
            jsonData['data'] != null) {
          final url = jsonData['data'].toString();
          if (url.isNotEmpty) return url;
        }
      }
      return null;
    } catch (e, st) {
      debugPrint("uploadOutletImage Error: $e");
      print(st);
      return null;
    }
  }
//ENDED
  /// POST /api/fm/outlets/saveOrUpdateDocuments — uploads verification
  /// documents (Aadhaar/PAN for a merchant, FSSAI/GST for an outlet) via
  /// multipart/form-data. Only the provided files are attached.
  static Future<bool> saveOrUpdateDocuments({
    required int entityId,
    required String entityType,
    File? aadharFile,
    File? panFile,
    File? fssaiFile,
    File? gstFile,
    File? rcCopyFile,
    File? drivingLicenseFile,
  }) async {
    try {
      if (entityId <= 0) {
        debugPrint("saveOrUpdateDocuments: invalid entityId");
        return false;
      }

      final token = await getAuthToken();
      final url = '${Constant.baseUrl}fm/outlets/saveOrUpdateDocuments';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = token;
      }

      request.fields['entityId'] = entityId.toString();
      request.fields['entityType'] = entityType;

      Future<void> attach(String field, File? file) async {
        if (file == null || !file.existsSync()) return;
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            field,
            file.path,
            filename: file.path.split('/').last,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      await attach('aadharFile', aadharFile)
          .then((_) => attach('panFile', panFile))
          .then((_) => attach('fssaiFile', fssaiFile))
          .then((_) => attach('gstFile', gstFile))
          .then((_) => attach('rcCopyFile', rcCopyFile))
          .then((_) => attach('drivingLicenseFile', drivingLicenseFile));

      debugPrint("saveOrUpdateDocuments URL: $url");
      debugPrint(
          "saveOrUpdateDocuments entityId=$entityId entityType=$entityType files=${request.files.length}");

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      debugPrint("saveOrUpdateDocuments Status: ${response.statusCode}");
      debugPrint("saveOrUpdateDocuments Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body =
            response.body.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
        if (body.isNotEmpty) {
          try {
            final json = jsonDecode(body);
            if (json is Map && json['success'] == true) return true;
          } catch (_) {}
        }
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint("saveOrUpdateDocuments Error: $e");
      print(st);
      return false;
    }
  }
//ENDED
  // GET CUISINE TYPES STARTED
  static Future<List<CuisineTypeModel>> getCuisineTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //final token = prefs.getString('authToken') ?? '';
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/cuisine-types';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint("getCuisineTypes Status: ${response.statusCode}");
      debugPrint("getCuisineTypes Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'];

        if (data is List) {
          return data
              .map((e) => CuisineTypeModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint("getCuisineTypes Error: $e");
      return [];
    }
  }
// END OF THIS API

// Helper method to convert VendorModel to JSON with proper GeoPoint handling
// Helper method to convert VendorModel to JSON with proper GeoPoint handling
  static Map<String, dynamic> _convertVendorToJson(VendorModel vendor) {
    // Always create a fresh workingHours array to avoid any reference issues
    List<Map<String, dynamic>> workingHoursArray = _createDefaultWorkingHours();

    // Create a new map instead of using vendor.toJson() directly
    Map<String, dynamic> json = {
      // 'author': vendor.author,
      // 'dine_in_active': vendor.dineInActive,
      // 'openDineTime': vendor.openDineTime,
      'categoryID': vendor.categoryID,
      'id': vendor.id,
      'categoryPhoto': vendor.categoryPhoto,
      'restaurantMenuPhotos': vendor.restaurantMenuPhotos ?? [],
      'subscriptionPlanId': vendor.subscriptionPlanId,
      'subscriptionExpiryDate': vendor.subscriptionExpiryDate,
      // 'subscription_plan': vendor.subscriptionPlan?.toJson(),
      'subscriptionTotalOrders': vendor.subscriptionTotalOrders,
      'location': vendor.location,
      'fcmToken': vendor.fcmToken,
      'hidephotos': vendor.hidephotos,
      'reststatus': vendor.reststatus,
      'filters': vendor.filters?.toJson(),
      'workingHours': workingHoursArray, // Use the fresh array
    };

    // Handle the 'g' field separately with proper GeoPoint serialization
    if (vendor.g != null) {
      json['g'] = {
        'geohash': vendor.g!.geohash,
        'geopoint': {
          'latitude': vendor.g!.geopoint?.latitude,
          'longitude': vendor.g!.geopoint?.longitude,
          '_latitude': vendor.g!.geopoint?.latitude,
          '_longitude': vendor.g!.geopoint?.longitude,
        }
      };
    }

    // Add any other vendor fields you need
    if (vendor.title != null) json['title'] = vendor.title;
    if (vendor.description != null) json['description'] = vendor.description;
    if (vendor.phonenumber != null) json['phonenumber'] = vendor.phonenumber;
    if (vendor.latitude != null) json['latitude'] = vendor.latitude;
    if (vendor.longitude != null) json['longitude'] = vendor.longitude;

    // Limit photos array to prevent database overflow
    json['photos'] = _limitArrayLength(vendor.photos, 5) ?? [];

    if (vendor.photo != null) json['photo'] = vendor.photo;
    if (vendor.zoneId != null) json['zoneId'] = vendor.zoneId;
    if (vendor.isSelfDelivery != null) json['isSelfDelivery'] = vendor.isSelfDelivery;
    if (vendor.adminCommission != null) json['adminCommission'] = vendor.adminCommission?.toJson();
    if (vendor.deliveryCharge != null) json['deliveryCharge'] = vendor.deliveryCharge?.toJson();

    // Final validation
    _validateJsonBeforeSending(json);

    return json;
  }

// Validate the JSON structure before sending
  static void _validateJsonBeforeSending(Map<String, dynamic> json) {
    debugPrint("=== VALIDATION: workingHours type: ${json['workingHours']?.runtimeType}");
    debugPrint("=== VALIDATION: workingHours is List: ${json['workingHours'] is List}");

    // Convert to JSON string and back to verify it survives encoding
    String testJson = jsonEncode(json);
    Map<String, dynamic> decoded = jsonDecode(testJson);
    debugPrint("=== VALIDATION: After encode/decode, workingHours type: ${decoded['workingHours']?.runtimeType}");
    debugPrint("=== VALIDATION: After encode/decode, workingHours is List: ${decoded['workingHours'] is List}");

    if (decoded['workingHours'] is! List) {
      debugPrint("=== WARNING: workingHours did not survive JSON encoding as List!");
    }
  }

// Helper method to create default working hours
  static List<Map<String, dynamic>> _createDefaultWorkingHours() {
    return [
      {'day': 'Monday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Tuesday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Wednesday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Thursday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Friday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Saturday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
      {'day': 'Sunday', 'timeslot': [{'to': '23:59', 'from': '00:00'}]},
    ];
  }

// Helper method to limit array length
  static List<dynamic>? _limitArrayLength(List<dynamic>? array, int maxLength) {
    if (array == null) return null;
    if (array.length <= maxLength) return array;
    return array.sublist(0, maxLength);
  }

  static Future<VendorModel?> updateVendor(VendorModel vendor) async {
    try {
      //final response = await http.post(
       final response = await http.put(
         Uri.parse('${Constant.baseUrl}restaurant/vendors/${vendor.id}'),

        headers: {
          'Content-Type': 'application/json',

        },
        body: json.encode(vendor.toJson()),

      );
      log("updateVendor ${response.body} ");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Constant.vendorAdminCommission = vendor.adminCommission;
          VendorModel? updatedVendor;
          if (responseData['data'] != null) {
            updatedVendor = VendorModel.fromJson(responseData['data']);
          } else {
            updatedVendor = vendor;
          }

          // Performance Optimization: Invalidate vendor cache and update with new data
          _cachedVendor = updatedVendor;
          _cachedVendorId = updatedVendor.id;
          _vendorCacheTime = DateTime.now();

          return updatedVendor;
        } else {
          throw Exception('API returned success: false: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to update vendor: ${response.statusCode}');
      }
    } catch (error) {
      log("Failed to update vendor: $error");
      return null;
    }
  }
  final loginController = Get.find<LoginController>(); // Finds existing instance

   Future<bool?> deleteUser() async {
    try {
      String userId = await getCurrentUid();
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}restaurant/user_delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
        }),
      );
      if (response.statusCode == 200) {
        loginController.logoutFunction();
        return true;
      } else {
        log('Delete user API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, s) {
      log('FireStoreUtils.deleteUser $e $s');
      return false;
    }
  }

  static Future<Url> uploadChatImageToFireStorage(
      File image, BuildContext context) async {
    ShowToastDialog.showLoader("Please wait");
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
        mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(
      BuildContext context, File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef =
          FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      File thumbnail = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 75, // 0 - 100
        position: -1, // Get the first frame
      );
      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef =
          FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnail.readAsBytesSync(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(
          videoUrl: Url(
              url: videoUrl.toString(),
              mime: metaData.contentType ?? 'video',
              videoThumbnail: thumbnailUrl),
          thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<String> uploadImageOfStory(
      File image, BuildContext context, String extansion) async {
    final data = await image.readAsBytes();
    final mime = lookupMimeType('', headerBytes: data);

    Reference upload = FirebaseStorage.instance.ref().child(
          'Story/images/${image.path.split('/').last}',
        );
    UploadTask uploadTask =
        upload.putFile(image, SettableMetadata(contentType: mime));
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    ShowToastDialog.closeLoader();
    return downloadUrl.toString();
  }

  static Future<File> _compressVideo(File file) async {
    MediaInfo? info = await VideoCompress.compressVideo(file.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 24);
    if (info != null) {
      File compressedVideo = File(info.path!);
      return compressedVideo;
    } else {
      return file;
    }
  }
  static Future<String?> uploadVideoStory(
      File video, BuildContext context) async {
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('Story/$uniqueID.mp4');
    File compressedVideo = await _compressVideo(video);
    SettableMetadata metadata = SettableMetadata(contentType: 'video');
    UploadTask uploadTask = upload.putFile(compressedVideo, metadata);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    ShowToastDialog.closeLoader();
    return downloadUrl.toString();
  }
  static Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }
  static Future<StoryModel?> getStory(String vendorId) async {
    try {
      // Make API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/stories/$vendorId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // If API returns the story data
          if (responseData['data'] != null) {
            return StoryModel.fromJson(responseData['data']);
          } else {
            return null; // No story found
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 404) {
        // Story not found
        return null;
      } else {
        throw Exception('Failed to load story: ${response.statusCode}');
      }
    } catch (error) {
      log("Error fetching story: $error");
      return null;
    }
  }
  static Future<void> addOrUpdateStory(StoryModel storyModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/stories'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(storyModel.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Successfully added/updated
          return;
        } else {
          throw Exception('API returned success: false: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to add/update story: ${response.statusCode}');
      }
    } catch (error) {
      log("Failed to add/update story: $error");
      throw error; // Re-throw to maintain similar behavior to Firebase version
    }
  }
  static Future<void> removeStory(String vendorId) async {
    try {
      // Make API call
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}restaurant/stories/$vendorId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return;
        } else {
          throw Exception('API returned success: false: ${responseData['message']}');
        }
      } else if (response.statusCode == 404) {
        // Story not found - this might be acceptable depending on requirements
        log("Story not found for vendor: $vendorId");
        return;
      } else {
        throw Exception('Failed to delete story: ${response.statusCode}');
      }
    } catch (error) {
      log("Failed to delete story: $error");
      throw error; // Re-throw to maintain similar behavior to Firebase version
    }
  }
  static Future<WithdrawMethodModel?> getWithdrawMethod() async {
    try {
      // Make API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/withdraw-method?userId=${getCurrentUid()}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];

          if (data.isNotEmpty) {
            WithdrawMethodModel withdrawMethodModel = WithdrawMethodModel.fromJson(data.first);
            return withdrawMethodModel;
          } else {
            return null; // No withdraw method found
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load withdraw method: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
  }
  static Future<WithdrawMethodModel?> setWithdrawMethod(
      WithdrawMethodModel withdrawMethodModel) async {
    try {
      String userId = await FireStoreUtils.getCurrentUid();
      // Prepare the data
      if (withdrawMethodModel.id == null) {
        withdrawMethodModel.id = const Uuid().v4();
        withdrawMethodModel.userId = userId;
      }
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/wallet/withdraw-method'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(withdrawMethodModel.toJson()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          if (responseData['data'] != null) {
            WithdrawMethodModel updatedModel = WithdrawMethodModel.fromJson(responseData['data']);
            return updatedModel;
          } else {
            return withdrawMethodModel;
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to set withdraw method: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
  }
  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/email-templates/$type'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          if (responseData['data'] != null) {
            EmailTemplateModel emailTemplateModel = EmailTemplateModel.fromJson(responseData['data']);
            return emailTemplateModel;
          } else {
            return null; // No email template found
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load email template: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
  }
  static sendPayoutMail(
      {required String amount, required String payoutrequestid}) async {
    EmailTemplateModel? emailTemplateModel =
        await FireStoreUtils.getEmailTemplates(Constant.payoutRequest);
    String body = emailTemplateModel!.subject.toString();
    body = body.replaceAll("{userid}", Constant.userModel!.id.toString());
    String newString = emailTemplateModel.message.toString();
    newString =
        newString.replaceAll("{username}", Constant.userModel!.fullName());
    newString =
        newString.replaceAll("{userid}", Constant.userModel!.id.toString());
    newString =
        newString.replaceAll("{amount}", Constant.amountShow(amount: amount));
    newString =
        newString.replaceAll("{payoutrequestid}", payoutrequestid.toString());
    newString = newString.replaceAll("{usercontactinfo}",
        "${Constant.userModel!.email}\n${Constant.userModel!.phoneNumber}");
    await Constant.sendMail(
        subject: body,
        isAdmin: emailTemplateModel.isSendToAdmin,
        body: newString,
        recipients: [Constant.userModel!.email]);
  }
  static Future<NotificationModel?> getNotificationContent(String type) async {
    try {
      // Make API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/notifications/$type'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // If API returns the notification data
          if (responseData['data'] != null) {
            debugPrint("------>");
            debugPrint(responseData['data']);

            NotificationModel notificationModel =
            NotificationModel.fromJson(responseData['data']);
            return notificationModel;
          } else {
            // No notification found - return default
            return NotificationModel(
              id: "",
              message: "Notification setup is pending",
              subject: "setup notification",
              type: type,
            );
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 404) {
        // Notification not found - return default
        return NotificationModel(
          id: "",
          message: "Notification setup is pending",
          subject: "setup notification",
          type: type,
        );
      } else {
        throw Exception('Failed to load notification: ${response.statusCode}');
      }
    } catch (error) {
      log("Error fetching notification: $error");
      // Return default notification on error
      return NotificationModel(
        id: "",
        message: "Notification setup is pending",
        subject: "setup notification",
        type: type,
      );
    }
  }



  static Future<bool?> setProduct(ProductModel productModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/products'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(productModel.toJson()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          invalidateProductCache(Constant.userModel?.vendorID);
          invalidateVendorCategoryCache();
          return true;
        } else {
          log("Failed to add product: API returned success false - ${responseData['message']}");
          return false;
        }
      } else {
        log("Failed to add product: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      log("Failed to add product: $error");
      return false;
    }
  }

  static Future<String> uploadUserImageToFireStorage(
      File image, String userID) async {
    Reference upload =
        FirebaseStorage.instance.ref().child('images/$userID.png');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<AdvertisementModel> firebaseCreateAdvertisement(
      AdvertisementModel model) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}advertisements'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(model.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          if (responseData['data'] != null) {
            return AdvertisementModel.fromJson(responseData['data']);
          } else {
            return model;
          }
        } else {
          log('API returned success: false for create advertisement');
          throw Exception('Failed to create advertisement: ${responseData['message']}');
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create advertisement: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      throw Exception('Failed to create advertisement: $error');
    }
  }

  static Future<AdvertisementModel> removeAdvertisement(
      AdvertisementModel model) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}advertisements/${model.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return model;
        } else {
          log('API returned success: false for delete advertisement');
          throw Exception('Failed to delete advertisement: ${responseData['message']}');
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete advertisement: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      throw Exception('Failed to delete advertisement: $error');
    }
  }
  static Future<AdvertisementModel> pauseAndResumeAdvertisement(
      AdvertisementModel model) async {
    try {
      final response = await http.put(
        Uri.parse('${Constant.baseUrl}advertisements/${model.id}/pause-resume'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(model.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // If the API returns the updated advertisement data, use it
          if (responseData['data'] != null) {
            return AdvertisementModel.fromJson(responseData['data']);
          } else {
            return model;
          }
        } else {
          log('API returned success: false for pause/resume advertisement ');
          throw Exception('Failed to pause/resume advertisement: ${responseData['message']}');
        }
      } else {
        log('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to pause/resume advertisement: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      throw Exception('Failed to pause/resume advertisement: $error');
    }
  }

  static Future<List<RatingModel>> getOrderReviewsByVenderId({
    required String venderId
  }) async {
    List<RatingModel> ratingModelList = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/reviews/vendor/$venderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> reviewsData = jsonResponse['data'];
          debugPrint("======>");
          print(reviewsData.length);
          for (final reviewData in reviewsData) {
            ratingModelList.add(RatingModel.fromJson(reviewData));
          }
        } else {
          debugPrint("No reviews found or API returned error");
        }
      } else {
        debugPrint("Failed to fetch reviews: ${response.statusCode} - ${response.body}");
      }
    } catch (error) {
      debugPrint("Error fetching reviews: $error");
    }

    return ratingModelList;
  }

  static Future<List<UserModel>> getAvalibleDrivers({String? zoneId}) async {
    List<UserModel> driverList = [];
    try {
      // String? userId = await getFirebaseId();
      // log("getAvalibleDrivers :: 22  $userId");
      // Make API call
      String url = "";
      if(zoneId==null){
        url = '${Constant.baseUrl}drivers/available';
      }else{
        url = '${Constant.baseUrl}drivers/available?zoneId=$zoneId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      log("getAvalibleDrivers ${response.body} ");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          if (data.isNotEmpty) {
            for (var element in data) {
              driverList.add(UserModel.fromJson(element));
            }
            // Sort by createdAt descending (to match Firebase orderBy behavior)
            driverList.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load available drivers: ${response.statusCode}');
      }
    } catch (e) {
      log("Error fetching drivers: ${e.toString()}");
    }
    return driverList;
  }
  static Future<List<UserModel>> getAllDrivers() async {
    List<UserModel> driverList = [];
    try {
      // Make API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}drivers/all?vendorID=${Constant.userModel?.vendorID}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          if (data.isNotEmpty) {
            for (var element in data) {
              driverList.add(UserModel.fromJson(element));
            }
            // Sort by createdAt descending (to match Firebase orderBy behavior)
            driverList.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      log("Error fetching drivers: ${e.toString()}");
    }
    return driverList;
  }

  static Future<void> updateProductIsAvailable(String productId, bool isAvailable) async {
    try {
      final response = await http.put(
        Uri.parse('${Constant.baseUrl}restaurant/products/$productId/availability'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'isAvailable': isAvailable,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateProductCache(Constant.userModel?.vendorID);
        debugPrint('Product availability updated successfully');
      } else {
        debugPrint("Failed to update product availability: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to update product availability');
      }
    } catch (error) {
      debugPrint("Failed to update product availability: $error");
      throw error;
    }
  }


  static Future<void> updateCategoryIsActive(String categoryId, bool isActive) async {
    try {
      debugPrint("updateCategoryIsActive ${isActive}");
      String url  = '${Constant.baseUrl}restaurant/vendor-categories/$categoryId/active';
          // 'restaurant/categories/$categoryId/products-availability'
      // ;
      debugPrint("updateCategoryIsActive $url vendorID ${Constant.userModel!.vendorID}  isAvailable ${isActive ? 1 : 0}");
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          // 'vendorID': Constant.userModel!.vendorID, // Assuming you have vendorID in user model
          'isActive': isActive , // Convert bool to int (1 for true, 0 for false)
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateProductCache(Constant.userModel?.vendorID);
        invalidateVendorCategoryCache();
        debugPrint('Category availability updated successfully');
      } else {
        debugPrint("Failed to update category availability: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to update category availability');
      }
    } catch (error) {
      debugPrint("Failed to update category availability: $error");
      throw error;
    }
  }


  static Future<void> setAllProductsAvailabilityForCategory(
      String categoryId,
      bool isAvailable
      ) async {
    try {
      final url = Uri.parse('${Constant.baseUrl}restaurant/categories/$categoryId/products-availability');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "vendorID": Constant.userModel!.vendorID,
          "isAvailable": isAvailable ? 1 : 0, // Convert bool to int
        }),
      );

      if (response.statusCode == 200) {
        invalidateProductCache(Constant.userModel?.vendorID);
        debugPrint('Products availability updated successfully');
      } else {
        debugPrint('Failed to update products availability: ${response.statusCode}');
        throw Exception('Failed to update products availability');
      }
    } catch (e) {
      debugPrint('Error updating products availability: $e');
      throw e;
    }
  }

  /// POST /api/fm/outlet-unavailability — mark product/category/outlet unavailable.
  // static Future<bool> postOutletItemUnavailability({
  //   required String type,
  //   required int unavailabilityId,
  //   String reason = 'Temporarily unavailable',
  //   DateTime? fromDate,
  //   DateTime? toDate,
  // }) async {
  //   try {
  //     final now = DateTime.now();
  //     final from = fromDate ?? now;
  //     final to = toDate ?? DateTime(2099, 12, 31, 23, 59, 59);
  //     final token = Preferences.getString('authToken');
  //
  //     final body = {
  //       'type': type.toUpperCase(),
  //       'unavailabilityId': unavailabilityId,
  //       'unavailabilityFromDate': from.toIso8601String().split('.').first,
  //       'unavailabilityToDate': to.toIso8601String().split('.').first,
  //       'reason': reason,
  //     };
  //
  //     final response = await http.post(
  //       Uri.parse(
  //         'http://187.127.156.147:8084/api/fm/outlet-unavailability',
  //       ),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode(body),
  //     );
  //
  //     debugPrint('postOutletItemUnavailability => ${jsonEncode(body)}');
  //     debugPrint('postOutletItemUnavailability status => ${response.statusCode}');
  //     debugPrint('postOutletItemUnavailability body => ${response.body}');
  //
  //     if (response.statusCode != 200 && response.statusCode != 201) {
  //       return false;
  //     }
  //
  //     final decoded = jsonDecode(response.body);
  //     if (decoded is Map && decoded['success'] == false) {
  //       return false;
  //     }
  //
  //     return true;
  //   } catch (e, stackTrace) {
  //     debugPrint('postOutletItemUnavailability error: $e');
  //     debugPrint(stackTrace);
  //     return false;
  //   }
  // }

  static Future<bool> postOutletItemUnavailability({
    required String type,
    required int unavailabilityId,
    String reason = 'Temporarily unavailable',
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final now = DateTime.now();

      // Keep at least 1 minute buffer before API call.
      final minimumAllowedTime = now.add(
        const Duration(minutes: 1),
      );

      // If selected start time is current/past,
      // automatically move it into the future.
      final selectedFrom = fromDate ?? minimumAllowedTime;

      final from = selectedFrom.isBefore(minimumAllowedTime)
          ? minimumAllowedTime
          : selectedFrom;

      // Default end date.
      var to = toDate ??
          DateTime(
            2099,
            12,
            31,
            23,
            59,
            59,
          );

      // End date must always be after start date.
      if (!to.isAfter(from)) {
        to = from.add(
          const Duration(hours: 1),
        );
      }

      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final body = {
        'type': type.toUpperCase(),
        'unavailabilityId': unavailabilityId,

        // Removes milliseconds because backend expects:
        // yyyy-MM-ddTHH:mm:ss
        'unavailabilityFromDate':
        from.toIso8601String().split('.').first,

        'unavailabilityToDate':
        to.toIso8601String().split('.').first,

        'reason': reason,
      };

      debugPrint('==========================================');
      debugPrint('POST OUTLET ITEM UNAVAILABILITY');
      debugPrint('Current time     : $now');
      debugPrint('Original from    : $fromDate');
      debugPrint('Final from       : $from');
      debugPrint('Original to      : $toDate');
      debugPrint('Final to         : $to');
      debugPrint('Request body     : ${jsonEncode(body)}');
      debugPrint('==========================================');

      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/outlet-unavailability',
        ),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint(
        'postOutletItemUnavailability status => ${response.statusCode}',
      );

      debugPrint(
        'postOutletItemUnavailability body => ${response.body}',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['success'] == false) {
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('postOutletItemUnavailability error: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// PATCH /api/fm/outlet-unavailability/restore — restore availability.
  static Future<bool> restoreOutletItemAvailability({
    required String type,
    required int unavailabilityId,
    String reason = 'Restored availability',
  }) async {
    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final body = {
        'type': type.toUpperCase(),
        'unavailabilityId': unavailabilityId,
        'reason': reason,
      };

      final response = await http.patch(
        Uri.parse(
          '${Constant.baseUrl}fm/outlet-unavailability/restore',
        ),
         headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('restoreOutletItemAvailability => ${jsonEncode(body)}');
      debugPrint('restoreOutletItemAvailability status => ${response.statusCode}');
      debugPrint('restoreOutletItemAvailability body => ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['success'] == false) {
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('restoreOutletItemAvailability error: $e');
      print(stackTrace);
      return false;
    }
  }
// ── Promotion APIs ──────────────────────────────────────────────────────────

  static Future<bool> restoreOnlyOutletItemAvailability({
    required String type,
    required int unavailabilityId,
    String reason = 'Restored availability',
  }) async {
    try {
      //final token = Preferences.getString('authToken');
      final headers = await getHeaders();
      final body = {
        'outletId': unavailabilityId,
        'isToggle' : true,
      };

      final response = await http.put(
        Uri.parse(
          '${Constant.baseUrl}fm/outlets/toggleForOutlet',
        ),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('restoreOutletItemAvailability => ${jsonEncode(body)}');
      debugPrint('restoreOutletItemAvailability status => ${response.statusCode}');
      debugPrint('restoreOutletItemAvailability body => ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['success'] == false) {
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('restoreOutletItemAvailability error: $e');
      print(stackTrace);
      return false;
    }
  }



  // GET /api/fm/promotion-plans/outlets/{outletId}/counts
  static Future<PromotionCountsModel> getPromotionCounts(int outletId) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/promotion-plans/outlets/$outletId/counts';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null) {
          return PromotionCountsModel.fromJson(decoded['data']);
        }
      }
      return PromotionCountsModel();
    } catch (e) {
      log('getPromotionCounts error: $e');
      return PromotionCountsModel();
    }
  }

  // GET /api/fm/promotion-plans/outlets/{outletId}?status={status}&page={page}&size={size}
  static Future<List<PromotionPlanModel>> getPromotionPlansByOutlet({
    required int outletId,
    required String status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final headers = await getHeaders();
      final url =
          '${Constant.baseUrl}fm/promotion-plans/outlets/$outletId?status=$status&page=$page&size=$size&sortBy=promotionPlanId&direction=DESC';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null && decoded['data']['content'] != null) {
          final List<dynamic> list = decoded['data']['content'];
          return list.map((e) => PromotionPlanModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      log('getPromotionPlansByOutlet error: $e');
      return [];
    }
  }

  // GET /api/fm/promotion-plan-types
  // GET /api/fm/promotion-plan-types
  static Future<List<PromotionPlanTypeModel>> getPromotionPlanTypes() async {
    try {
      final headers = await getHeaders();
      final baseUrl = Constant.baseUrl.endsWith('/')
          ? Constant.baseUrl
          : '${Constant.baseUrl}/';
      final url = '${baseUrl}fm/promotion-plan-types';

      debugPrint('===== GET PROMOTION PLAN TYPES =====');
      debugPrint('Request URL: $url');
      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'];
        }

        final list = rawList.map((e) {
          if (e is Map<String, dynamic>) {
            return PromotionPlanTypeModel.fromJson(e);
          }
          return PromotionPlanTypeModel.fromJson(Map<String, dynamic>.from(e as Map));
        }).toList();

        debugPrint('Parsed Plan Types: ${list.length}');
        return list;
      } else {
        log('getPromotionPlanTypes failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      log('getPromotionPlanTypes error: $e');
      log(stackTrace.toString());
      return [];
    }
  }
  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  // POST /api/fm/promotion-plans

  // POST /api/fm/promotion-plans
  static Future<PromotionApiResult> createPromotionPlan(PromotionPlanModel model) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/promotion-plans';
      final body = json.encode(model.toCreateUpdateJson());

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      final decoded = _tryDecode(response.body);
      final apiMessage = decoded != null ? decoded['message']?.toString() : null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PromotionApiResult(success: true, message: apiMessage ?? 'Plan created successfully');
      }
      return PromotionApiResult(success: false, message: apiMessage ?? 'Failed to create promotion plan');
    } catch (e) {
      log('createPromotionPlan error: $e');
      return PromotionApiResult(success: false, message: 'Something went wrong. Please try again.');
    }
  }
  // DELETE /api/fm/promotion-plans/{promotionPlanId}
  static Future<bool> deletePromotionPlan(int promotionPlanId) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/promotion-plans/$promotionPlanId';
      final response = await http.delete(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      log('deletePromotionPlan error: $e');
      return false;
    }
  }

  static Future<PromotionPlanModel?> getPromotionPlanDetails(int promotionPlanId) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/promotion-plans/$promotionPlanId';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Note: this endpoint returns the plan object directly,
        // NOT wrapped in a "data" key like the list/counts endpoints.
        return PromotionPlanModel.fromJson(decoded);
      }
      log('getPromotionPlanDetails failed: ${response.statusCode} — ${response.body}');
      return null;
    } catch (e) {
      log('getPromotionPlanDetails error: $e');
      return null;
    }
  }
  static Future<PromotionApiResult> updatePromotionPlan(int promotionPlanId, PromotionPlanModel model) async {
    try {
      final headers = await getHeaders();
      final url = '${Constant.baseUrl}fm/promotion-plans/$promotionPlanId';
      final body = json.encode(model.toCreateUpdateJson());

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      final decoded = _tryDecode(response.body);
      final apiMessage = decoded != null ? decoded['message']?.toString() : null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PromotionApiResult(success: true, message: apiMessage ?? 'Plan updated successfully');
      }
      return PromotionApiResult(success: false, message: apiMessage ?? 'Failed to update promotion plan');
    } catch (e) {
      log('updatePromotionPlan error: $e');
      return PromotionApiResult(success: false, message: 'Something went wrong. Please try again.');
    }
  }

  static Future<Map<String, dynamic>?> sendLoginOtpForNumber({
    required String userType,
    required String mobileNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/auth/send-login-otp',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          "userType": userType,
          "mobileNumber": mobileNumber,
        }),
      );

      debugPrint(
        "Send OTP Status: ${response.statusCode}",
      );

      debugPrint(
        "Send OTP Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "error": true,
        "message":
        "Failed to send OTP (${response.statusCode})",
      };
    } catch (e) {
      debugPrint(
        "Send OTP Error: $e",
      );

      return {
        "error": true,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> verifyLoginOtpForNumber({
    required String userType,
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/auth/verify-login-otp',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          "userType": userType,
          "mobileNumber": mobileNumber,
          "otp": otp,
        }),
      );

      debugPrint(
        "Verify OTP Status: ${response.statusCode}",
      );

      debugPrint(
        "Verify OTP Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "error": true,
        "message":
        "Invalid OTP (${response.statusCode})",
      };
    } catch (e) {
      debugPrint(
        "Verify OTP Error: $e",
      );

      return {
        "error": true,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> resendLoginOtpForNumber({
    required String userType,
    required String mobileNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Constant.baseUrl}fm/auth/resend-login-otp',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          "userType": userType,
          "mobileNumber": mobileNumber,
        }),
      );

      debugPrint(
        "Resend OTP Status: ${response.statusCode}",
      );

      debugPrint(
        "Resend OTP Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "error": true,
        "message":
        "Failed to resend OTP (${response.statusCode})",
      };
    } catch (e) {
      debugPrint(
        "Resend OTP Error: $e",
      );

      return {
        "error": true,
        "message": e.toString(),
      };
    }
  }


}
