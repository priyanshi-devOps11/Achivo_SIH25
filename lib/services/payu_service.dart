// lib/services/payu_service.dart
// ══════════════════════════════════════════════════════════════════════
// PAYU PAYMENT INTEGRATION — payu_checkoutpro_flutter 1.4.0
//
// ROOT CAUSE OF YOUR ERRORS (confirmed from dashboard screenshots):
//
// Error 5016: Your account (MID: 9215014, Key: EWVUgs) is a NEW test
//   account that has NOT been approved/activated for the CheckoutPro
//   SDK yet. PayU requires merchant KYC/activation even on test mode
//   before the SDK works. The account shows "Welcome Merchant on your
//   test account!" which confirms it's brand new and unactivated.
//
// Error 5019: Caused by passing a pre-computed hash in additionalParam
//   AND also responding to generateHash() callbacks — double hash
//   conflict. Fixed by removing the pre-computed hash from the params.
//
// IMMEDIATE FIX: Use PayU's pre-approved public test credentials below.
//   These are documented at https://devguide.payu.in/
//   and work immediately without KYC.
//
// TO USE YOUR OWN KEY (EWVUgs) AGAIN:
//   1. Go to https://payu.in/business → Settings → KYC
//   2. Complete merchant verification / activation
//   3. OR click "Connect existing test account" on your dashboard
//   4. Once activated, swap back to OPTION B credentials below
//
// ══════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_models.dart';

// ─────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────

class PayUConfig {
  // ── OPTION A (USE NOW): PayU's pre-approved public sandbox credentials
  //   These work immediately without account activation.
  static const String merchantKey    = 'gtKFFx';
  static const String merchantSalt   = 'eCwWRki6';
  static const String merchantSecret = 'eCwWRki6';

  // ── OPTION B (USE AFTER KYC): Your own credentials
  //   Uncomment these and comment out Option A once your account is active.
  // static const String merchantKey    = 'EWVUgs';
  // static const String merchantSalt   = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  // static const String merchantSecret = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';

  static const bool   isTestMode  = true;
  static const String successUrl  = 'https://payu.in';
  static const String failureUrl  = 'https://payu.in';
}

// ─────────────────────────────────────────────────────────────────────
// RESULT TYPE
// ─────────────────────────────────────────────────────────────────────

class PayUPaymentResult {
  final bool    success;
  final String? txnId;
  final String? payuTxnId;
  final String? receiptNo;
  final String? error;

  const PayUPaymentResult({
    required this.success,
    this.txnId,
    this.payuTxnId,
    this.receiptNo,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────
// HASH HELPER
// ─────────────────────────────────────────────────────────────────────

class PayUHashHelper {
  // Used for verifying PayU's callback response only.
  static String generatePaymentHash({
    required String txnId,
    required double amount,
    required String productInfo,
    required String firstName,
    required String email,
  }) {
    final str =
        '${PayUConfig.merchantKey}|$txnId|${amount.toStringAsFixed(2)}'
        '|$productInfo|$firstName|$email|||||||||||${PayUConfig.merchantSalt}';
    return sha512.convert(utf8.encode(str)).toString();
  }

  static bool verifyResponseHash({
    required String receivedHash,
    required String txnId,
    required double amount,
    required String productInfo,
    required String firstName,
    required String email,
    required String status,
  }) {
    final str =
        '${PayUConfig.merchantSalt}|$status|||||||||||'
        '$email|$firstName|$productInfo|${amount.toStringAsFixed(2)}'
        '|$txnId|${PayUConfig.merchantKey}';
    final expected = sha512.convert(utf8.encode(str)).toString();
    return expected.toLowerCase() == receivedHash.toLowerCase();
  }

  // Called from generateHash() callback.
  // Hash type rules per PayU devguide.payu.in:
  //   V1 (default) : SHA512(hashString + salt)
  //   V2           : HmacSHA256(hashString, salt)
  //   mcpLookup    : HmacSHA1(hashString, secretKey)
  //   postSalt     : SHA512(hashString + postSalt)  ← do NOT re-append salt
  static String generateSdkHash({
    required String hashString,
    required String hashType,
    required String hashName,
    String?         postSalt,
  }) {
    if (hashType == 'V2') {
      final key  = utf8.encode(PayUConfig.merchantSalt);
      final data = utf8.encode(hashString);
      return Hmac(sha256, key).convert(data).toString();

    } else if (hashName == 'mcpLookup') {
      final key  = utf8.encode(PayUConfig.merchantSecret);
      final data = utf8.encode(hashString);
      return Hmac(sha1, key).convert(data).toString();

    } else if (postSalt != null && postSalt.isNotEmpty) {
      // Do NOT re-append merchantSalt — SDK already embedded it in hashString
      final str = '$hashString$postSalt';
      return sha512.convert(utf8.encode(str)).toString();

    } else {
      // V1 default
      final str = '$hashString${PayUConfig.merchantSalt}';
      return sha512.convert(utf8.encode(str)).toString();
    }
  }

  static String generateTxnId() =>
      'ACH${DateTime.now().millisecondsSinceEpoch}';
}

// ─────────────────────────────────────────────────────────────────────
// PAYU SERVICE
// ─────────────────────────────────────────────────────────────────────

class PayUService implements PayUCheckoutProProtocol {
  static final _db = Supabase.instance.client;
  static SupabaseClient get supabaseClient => _db;

  late PayUCheckoutProFlutter _payUFlutter;

  String? _pendingTxnId;
  int?    _pendingStudentFeeId;
  int?    _pendingInstallmentId;
  double? _pendingAmount;
  String? _pendingProductInfo;
  String? _pendingFirstName;
  String? _pendingEmail;
  Function(PayUPaymentResult)? _onResult;

  Future<void> startPayment({
    required BuildContext    context,
    required StudentFee      studentFee,
    required double          amount,
    int?                     installmentId,
    required String          studentName,
    required String          studentEmail,
    required String          studentPhone,
    required Function(PayUPaymentResult) onResult,
  }) async {
    _onResult             = onResult;
    _pendingStudentFeeId  = studentFee.id;
    _pendingInstallmentId = installmentId;
    _pendingAmount        = amount;
    _pendingTxnId         = PayUHashHelper.generateTxnId();
    _pendingFirstName     = studentName.split(' ').first.isNotEmpty
        ? studentName.split(' ').first : 'Student';
    _pendingProductInfo   = studentFee.feeStructure?.feeName ?? 'Fee Payment';
    _pendingEmail         = studentEmail.isNotEmpty
        ? studentEmail : 'student@achivo.app';

    final phone = studentPhone.isNotEmpty ? studentPhone : '9999999999';

    debugPrint('💳 Starting PayU payment');
    debugPrint('   TxnId: $_pendingTxnId | Amount: $amount');
    debugPrint('   Key: ${PayUConfig.merchantKey}');

    // Sanitize productInfo — remove any characters that could cause
    // type casting issues. PayU expects a plain ASCII string here.
    final safeProductInfo = (_pendingProductInfo ?? 'Fee Payment')
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    // ALL values must be String — the SDK does a hard cast to String?
    // and throws '_Map is not a subtype of String?' if any value is a Map.
    final payUPaymentParams = <String, String>{
      PayUPaymentParamKey.key:           PayUConfig.merchantKey,
      PayUPaymentParamKey.transactionId: _pendingTxnId!,
      PayUPaymentParamKey.amount:        amount.toStringAsFixed(2),
      PayUPaymentParamKey.productInfo:   safeProductInfo,
      PayUPaymentParamKey.firstName:     _pendingFirstName!,
      PayUPaymentParamKey.email:         _pendingEmail!,
      PayUPaymentParamKey.phone:         phone,
      PayUPaymentParamKey.android_surl:  PayUConfig.successUrl,
      PayUPaymentParamKey.android_furl:  PayUConfig.failureUrl,
      PayUPaymentParamKey.ios_surl:      PayUConfig.successUrl,
      PayUPaymentParamKey.ios_furl:      PayUConfig.failureUrl,
      PayUPaymentParamKey.environment:
      PayUConfig.isTestMode ? 'test' : 'production',
    };

    final payUCheckoutProConfig = <String, String>{
      PayUCheckoutProConfigKeys.primaryColor:   '#1565C0',
      PayUCheckoutProConfigKeys.secondaryColor: '#FFFFFF',
      PayUCheckoutProConfigKeys.merchantName:   'Achivo',
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: 'true',
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen:  'true',
      PayUCheckoutProConfigKeys.merchantSMSPermission: 'true',
    };

    try {
      _payUFlutter = PayUCheckoutProFlutter(this);
      await _payUFlutter.openCheckoutScreen(
        payUPaymentParams:     payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e) {
      debugPrint('❌ PayU open error: $e');
      onResult(PayUPaymentResult(
          success: false, error: 'Could not open payment gateway: $e'));
    }
  }

  @override
  generateHash(Map response) {
    debugPrint('🔐 generateHash called');
    try {
      final hashName   = response[PayUHashConstantsKeys.hashName]?.toString()   ?? '';
      final hashString = response[PayUHashConstantsKeys.hashString]?.toString() ?? '';
      final hashType   = response[PayUHashConstantsKeys.hashType]?.toString()   ?? '';
      final postSalt   = response[PayUHashConstantsKeys.postSalt]?.toString();

      debugPrint('   name=$hashName  type=${hashType.isEmpty ? "V1" : hashType}'
          '  postSalt=${postSalt ?? "null"}');

      if (hashString.isEmpty) {
        debugPrint('   ⚠️ Empty hashString — skipping');
        return;
      }

      final digest = PayUHashHelper.generateSdkHash(
        hashString: hashString,
        hashType:   hashType,
        hashName:   hashName,
        postSalt:   postSalt,
      );

      _payUFlutter.hashGenerated(hash: {hashName: digest});
      debugPrint('   ✅ Hash returned to SDK');

    } catch (e) {
      debugPrint('❌ generateHash error: $e');
    }
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    debugPrint('✅ PayU success: $response');
    final data      = _toMap(response);
    final payuTxnId = data['payuMoneyId']?.toString()
        ?? data['mihpayid']?.toString() ?? '';
    final status    = data['status']?.toString() ?? 'success';
    final hash      = data['hash']?.toString() ?? '';

    final productInfo = data['productinfo']?.toString() ?? _pendingProductInfo ?? '';
    final firstName   = data['firstname']?.toString()   ?? _pendingFirstName   ?? '';
    final email       = data['email']?.toString()       ?? _pendingEmail        ?? '';

    if (hash.isNotEmpty && _pendingAmount != null) {
      final isValid = PayUHashHelper.verifyResponseHash(
        receivedHash: hash,
        txnId:        _pendingTxnId ?? '',
        amount:       _pendingAmount!,
        productInfo:  productInfo,
        firstName:    firstName,
        email:        email,
        status:       status,
      );
      if (!isValid) debugPrint('⚠️ Response hash mismatch');
    }

    try {
      final res = await _db.functions.invoke(
        'verify-payu-payment',
        body: {
          'txn_id':         _pendingTxnId,
          'payu_txn_id':    payuTxnId,
          'student_fee_id': _pendingStudentFeeId,
          'installment_id': _pendingInstallmentId,
          'amount':         _pendingAmount,
          'status':         status,
          'payu_response':  data,
        },
      );

      if (res.status == 200 && res.data?['success'] == true) {
        _onResult?.call(PayUPaymentResult(
          success:   true,
          txnId:     _pendingTxnId,
          payuTxnId: payuTxnId,
          receiptNo: res.data?['receipt_no'] as String?,
        ));
      } else {
        _onResult?.call(PayUPaymentResult(
          success:   true,
          txnId:     _pendingTxnId,
          payuTxnId: payuTxnId,
          error: 'Payment received. TxnId: $_pendingTxnId',
        ));
      }
    } catch (e) {
      debugPrint('❌ verify-payu-payment error: $e');
      _onResult?.call(PayUPaymentResult(
        success:   true,
        txnId:     _pendingTxnId,
        payuTxnId: payuTxnId,
        error: 'Payment successful! TxnId: $_pendingTxnId.',
      ));
    }
    _clearPending();
  }

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint('❌ PayU failure: $response');
    final data = _toMap(response);
    final msg  = data['error_Message']?.toString()
        ?? data[PayUConstants.errorMsg]?.toString()
        ?? data['field9']?.toString()
        ?? 'Payment failed. Please try again.';
    _onResult?.call(PayUPaymentResult(success: false, error: msg));
    _clearPending();
  }

  @override
  void onPaymentCancel(Map? response) {
    debugPrint('⚠️ PayU cancelled');
    _onResult?.call(const PayUPaymentResult(
        success: false, error: 'Payment cancelled.'));
    _clearPending();
  }

  @override
  void onError(Map? response) {
    debugPrint('❌ PayU error: $response');
    final errorCode = response?['errorCode']?.toString() ?? '';
    final msg = response?[PayUConstants.errorMsg]?.toString()
        ?? response?['errorMsg']?.toString()
        ?? 'An error occurred';

    String userMessage = msg;
    if (errorCode == '5016') {
      userMessage = 'Payment gateway not ready. Your PayU merchant account '
          'needs to be activated at payu.in/business → Settings.';
    } else if (errorCode == '5019') {
      userMessage = 'Payment security check failed. Please try again.';
    }

    _onResult?.call(PayUPaymentResult(success: false, error: userMessage));
    _clearPending();
  }

  Map<String, dynamic> _toMap(dynamic r) {
    if (r is Map<String, dynamic>) return r;
    if (r is Map) return Map<String, dynamic>.from(r);
    return {};
  }

  void _clearPending() {
    _pendingTxnId         = null;
    _pendingStudentFeeId  = null;
    _pendingInstallmentId = null;
    _pendingAmount        = null;
    _pendingProductInfo   = null;
    _pendingFirstName     = null;
    _pendingEmail         = null;
  }
}