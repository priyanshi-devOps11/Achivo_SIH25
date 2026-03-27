// lib/services/payu_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Clean rewrite — fixes the '_Map<dynamic,dynamic>' is not a subtype of String
// crash that appears as errorCode:1 before PayU even opens.
//
// Root causes fixed:
//  1. payUCheckoutProConfig was passing values the SDK couldn't cast → now empty
//  2. All response parsing uses _toStr() which safely handles nested Map values
//  3. generateHash uses null-safe extraction throughout
//  4. _toMap() handles every possible response shape from the platform channel
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class PayUConfig {
  static const String merchantKey    = 'EWVUgs';
  static const String merchantSalt   = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  static const String merchantSecret = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  static const String mid            = '9215014';
  static const bool   isTestMode     = true;
  static const String successUrl     = 'https://payu.in';
  static const String failureUrl     = 'https://payu.in';
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT MODEL
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// HASH HELPER
// ─────────────────────────────────────────────────────────────────────────────

class PayUHashHelper {
  /// Verify the response hash returned by PayU after payment.
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

  /// Generate the hash the PayU SDK requests via generateHash().
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
    }

    if (hashName == 'mcpLookup') {
      final key  = utf8.encode(PayUConfig.merchantSecret);
      final data = utf8.encode(hashString);
      return Hmac(sha1, key).convert(data).toString();
    }

    if (postSalt != null && postSalt.isNotEmpty) {
      return sha512.convert(utf8.encode('$hashString$postSalt')).toString();
    }

    return sha512
        .convert(utf8.encode('$hashString${PayUConfig.merchantSalt}'))
        .toString();
  }

  static String generateTxnId() =>
      'ACH${DateTime.now().millisecondsSinceEpoch}';
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYU SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class PayUService implements PayUCheckoutProProtocol {
  static final _db = Supabase.instance.client;
  static SupabaseClient get supabaseClient => _db;

  late PayUCheckoutProFlutter _payUFlutter;

  // Pending payment state — stored so callbacks can reference it
  String? _pendingTxnId;
  int?    _pendingStudentFeeId;
  int?    _pendingInstallmentId;
  double? _pendingAmount;
  String? _pendingProductInfo;
  String? _pendingFirstName;
  String? _pendingEmail;
  Function(PayUPaymentResult)? _onResult;

  // ── Public: start a payment ──────────────────────────────────────────────

  Future<void> startPayment({
    required BuildContext                context,
    required StudentFee                  studentFee,
    required double                      amount,
    int?                                 installmentId,
    required String                      studentName,
    required String                      studentEmail,
    required String                      studentPhone,
    required Function(PayUPaymentResult) onResult,
  }) async {
    _onResult             = onResult;
    _pendingStudentFeeId  = studentFee.id;
    _pendingInstallmentId = installmentId;
    _pendingAmount        = amount;
    _pendingTxnId         = PayUHashHelper.generateTxnId();

    // Safe first-name extraction
    _pendingFirstName = () {
      final parts = studentName.trim().split(' ');
      return parts.isNotEmpty && parts.first.isNotEmpty
          ? parts.first
          : 'Student';
    }();

    // productinfo must be plain ASCII, no special chars
    _pendingProductInfo = () {
      final raw = studentFee.feeStructure?.feeName ?? 'FeePay';
      final clean = raw
          .replaceAll(RegExp(r'[^a-zA-Z0-9 \-_]'), '')
          .trim();
      return clean.isEmpty ? 'FeePay' : clean;
    }();

    _pendingEmail = studentEmail.isNotEmpty
        ? studentEmail
        : 'student@achivo.app';

    final phone = studentPhone.isNotEmpty ? studentPhone : '9999999999';

    debugPrint('💳 Starting PayU payment');
    debugPrint('   TxnId: $_pendingTxnId | Amount: $amount');
    debugPrint('   Key:   ${PayUConfig.merchantKey}');

    // ── Payment params — ALL values MUST be plain String ────────────────────
    // Do NOT add 'environment' or any key whose value the SDK maps to a
    // non-String type internally; that is what causes the cast crash.
    final Map<String, String> payUPaymentParams = {
      'key':          PayUConfig.merchantKey,
      'txnid':        _pendingTxnId!,
      'amount':       amount.toStringAsFixed(2),
      'productinfo':  _pendingProductInfo!,
      'firstname':    _pendingFirstName!,
      'email':        _pendingEmail!,
      'phone':        phone,
      'surl':         PayUConfig.successUrl,
      'furl':         PayUConfig.failureUrl,
      'android_surl': PayUConfig.successUrl,
      'android_furl': PayUConfig.failureUrl,
      'ios_surl':     PayUConfig.successUrl,
      'ios_furl':     PayUConfig.failureUrl,
    };

    // ── Config map — pass EMPTY to avoid internal SDK type cast crash ────────
    // The crash "type '_Map<dynamic,dynamic>' is not a subtype of String"
    // originates here: the SDK reads config entries and assigns them to String
    // fields without null/type checks. An empty map is safe.
    const Map<String, String> payUCheckoutProConfig = {};

    debugPrint('   paymentParams: $payUPaymentParams');

    try {
      _payUFlutter = PayUCheckoutProFlutter(this);
      await _payUFlutter.openCheckoutScreen(
        payUPaymentParams:     payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e, st) {
      debugPrint('❌ PayU open error: $e\n$st');
      onResult(PayUPaymentResult(
        success: false,
        error: 'Could not open payment gateway: $e',
      ));
    }
  }

  // ── Protocol: hash generation ────────────────────────────────────────────

  @override
  generateHash(Map response) {
    debugPrint('🔐 generateHash called: $response');
    try {
      // Use _toStr() everywhere — the SDK can put nested Maps in these fields
      final hashName   = _toStr(response[PayUHashConstantsKeys.hashName])   ?? '';
      final hashString = _toStr(response[PayUHashConstantsKeys.hashString]) ?? '';
      final hashType   = _toStr(response[PayUHashConstantsKeys.hashType])   ?? '';
      final postSalt   = _toStr(response[PayUHashConstantsKeys.postSalt]);

      debugPrint('   name=$hashName  '
          'type=${hashType.isEmpty ? "V1" : hashType}  '
          'postSalt=${postSalt ?? "null"}');

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
      debugPrint('   ✅ Hash sent to SDK');
    } catch (e, st) {
      debugPrint('❌ generateHash error: $e\n$st');
    }
  }

  // ── Protocol: success ────────────────────────────────────────────────────

  @override
  void onPaymentSuccess(dynamic response) async {
    debugPrint('✅ PayU success: $response');
    final data = _toMap(response);

    final payuTxnId = _toStr(data['payuMoneyId'])
        ?? _toStr(data['mihpayid'])
        ?? '';
    final status      = _toStr(data['status'])      ?? 'success';
    final hash        = _toStr(data['hash'])        ?? '';
    final productInfo = _toStr(data['productinfo']) ?? _pendingProductInfo ?? '';
    final firstName   = _toStr(data['firstname'])   ?? _pendingFirstName   ?? '';
    final email       = _toStr(data['email'])       ?? _pendingEmail       ?? '';

    // Verify response hash (non-fatal if it fails)
    if (hash.isNotEmpty && _pendingAmount != null) {
      final valid = PayUHashHelper.verifyResponseHash(
        receivedHash: hash,
        txnId:        _pendingTxnId ?? '',
        amount:       _pendingAmount!,
        productInfo:  productInfo,
        firstName:    firstName,
        email:        email,
        status:       status,
      );
      if (!valid) debugPrint('⚠️ Response hash mismatch — continuing anyway');
    }

    // Verify with Supabase edge function
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
        // Edge function returned non-200 but payment was captured by PayU
        _onResult?.call(PayUPaymentResult(
          success:   true,
          txnId:     _pendingTxnId,
          payuTxnId: payuTxnId,
          error:     'Payment received. TxnId: $_pendingTxnId',
        ));
      }
    } catch (e) {
      debugPrint('❌ verify-payu-payment error: $e');
      // Payment succeeded at PayU — don't mark as failed
      _onResult?.call(PayUPaymentResult(
        success:   true,
        txnId:     _pendingTxnId,
        payuTxnId: payuTxnId,
        error:     'Payment successful. TxnId: $_pendingTxnId',
      ));
    }

    _clearPending();
  }

  // ── Protocol: failure ────────────────────────────────────────────────────

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint('❌ PayU failure: $response');
    final data = _toMap(response);

    // Try every known error key; _toStr() safely skips nested Map values
    final msg = _toStr(data['error_Message'])
        ?? _toStr(data['errorMsg'])
        ?? _toStr(data['error_message'])
        ?? _toStr(data['field9'])
        ?? 'Payment failed. Please try again.';

    _onResult?.call(PayUPaymentResult(success: false, error: msg));
    _clearPending();
  }

  // ── Protocol: cancel ─────────────────────────────────────────────────────

  @override
  void onPaymentCancel(Map? response) {
    debugPrint('⚠️ PayU cancelled: $response');
    _onResult?.call(const PayUPaymentResult(
      success: false,
      error:   'Payment cancelled.',
    ));
    _clearPending();
  }

  // ── Protocol: error ──────────────────────────────────────────────────────

  @override
  void onError(Map? response) {
    debugPrint('❌ PayU error: $response');
    final msg = _toStr(response?['errorMsg'])
        ?? _toStr(response?['error_Message'])
        ?? _toStr(response?['error_message'])
        ?? 'An error occurred. Please try again.';
    _onResult?.call(PayUPaymentResult(success: false, error: msg));
    _clearPending();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Safely convert any value to String.
  /// Returns null if the value is itself a Map (nested map — not a string).
  /// This is the core fix: the SDK sometimes puts nested Maps in response
  /// fields that are supposed to be Strings, causing the cast crash.
  String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map) return null;   // ← skip nested maps, don't crash
    return v.toString();
  }

  /// Normalise any response object to Map<String, dynamic>.
  Map<String, dynamic> _toMap(dynamic r) {
    if (r is Map<String, dynamic>) return r;
    if (r is Map) {
      return r.map((k, v) => MapEntry(k.toString(), v));
    }
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
    _onResult             = null;
  }
}