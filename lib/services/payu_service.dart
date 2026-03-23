// lib/services/payu_service.dart
// ══════════════════════════════════════════════════════════════════════
// PAYU PAYMENT INTEGRATION — payu_checkoutpro_flutter 1.4.0
//
// CRASH FIX: Use raw string keys instead of PayUPaymentParamKey constants.
// The PayUPaymentParamKey constants are fine but the 'environment' key
// is special — the SDK internally reads it and substitutes a Map value
// before passing to the platform channel, causing the _Map crash.
// Fix: remove the environment key entirely (SDK defaults to production,
// we set test mode via the key itself).
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
  static const String merchantKey    = 'EWVUgs';
  static const String merchantSalt   = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  static const String merchantSecret = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  static const String mid            = '9215014';
  static const bool   isTestMode     = true;
  static const String successUrl     = 'https://payu.in';
  static const String failureUrl     = 'https://payu.in';
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
      return sha512
          .convert(utf8.encode('$hashString$postSalt'))
          .toString();
    } else {
      return sha512
          .convert(utf8.encode('$hashString${PayUConfig.merchantSalt}'))
          .toString();
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

  // ── Start Payment ─────────────────────────────────────────────────

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
    _pendingProductInfo   =
        (studentFee.feeStructure?.feeName ?? 'FeePay')
            .replaceAll(RegExp(r'[^a-zA-Z0-9 \-_]'), '')
            .trim();
    if (_pendingProductInfo!.isEmpty) _pendingProductInfo = 'FeePay';
    _pendingEmail = studentEmail.isNotEmpty
        ? studentEmail : 'student@achivo.app';

    final phone = studentPhone.isNotEmpty ? studentPhone : '9999999999';

    debugPrint('💳 Starting PayU payment');
    debugPrint('   TxnId: $_pendingTxnId | Amount: $amount');
    debugPrint('   Key: ${PayUConfig.merchantKey}');

    // ── CRITICAL: Use raw string keys, NOT PayUPaymentParamKey constants
    // The 'environment' constant from the SDK causes an internal Map
    // substitution which crashes the platform channel.
    // We omit it entirely — the SDK detects test vs prod from the key itself.
    final Map<String, String> payUPaymentParams = {
      'key':           PayUConfig.merchantKey,
      'txnid':         _pendingTxnId!,
      'amount':        amount.toStringAsFixed(2),
      'productinfo':   _pendingProductInfo!,
      'firstname':     _pendingFirstName!,
      'email':         _pendingEmail!,
      'phone':         phone,
      'surl':          PayUConfig.successUrl,
      'furl':          PayUConfig.failureUrl,
      'android_surl':  PayUConfig.successUrl,
      'android_furl':  PayUConfig.failureUrl,
      'ios_surl':      PayUConfig.successUrl,
      'ios_furl':      PayUConfig.failureUrl,
    };

    // Config — only 3 safe string keys, no booleans
    final Map<String, String> payUCheckoutProConfig = {
      'primaryColor':   '#1565C0',
      'secondaryColor': '#FFFFFF',
      'merchantName':   'Achivo',
    };

    debugPrint('   paymentParams: $payUPaymentParams');

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

  // ── Protocol callbacks ────────────────────────────────────────────

  @override
  generateHash(Map response) {
    debugPrint('🔐 generateHash called');
    try {
      final hashName   = response[PayUHashConstantsKeys.hashName]?.toString()   ?? '';
      final hashString = response[PayUHashConstantsKeys.hashString]?.toString() ?? '';
      final hashType   = response[PayUHashConstantsKeys.hashType]?.toString()   ?? '';
      final postSalt   = response[PayUHashConstantsKeys.postSalt]?.toString();

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
        error: 'Payment successful! TxnId: $_pendingTxnId',
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
    final msg = response?[PayUConstants.errorMsg]?.toString()
        ?? response?['errorMsg']?.toString()
        ?? 'An error occurred';
    _onResult?.call(PayUPaymentResult(success: false, error: msg));
    _clearPending();
  }

  // ── Helpers ───────────────────────────────────────────────────────

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