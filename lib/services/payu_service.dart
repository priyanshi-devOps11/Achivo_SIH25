// lib/services/payu_service.dart
// ══════════════════════════════════════════════════════════════════════
// PAYU PAYMENT INTEGRATION — payu_checkoutpro_flutter 1.4.0
//
// EXACT API from source:
//   Class:    PayUCheckoutProFlutter (NOT PayUCheckoutPro)
//   Protocol: PayUCheckoutProProtocol
//   Open:     instance.openCheckoutScreen(payUPaymentParams, payUCheckoutProConfig)
//   Hash:     instance.hashGenerated(hash: {...})
//   Param keys: transactionId, productInfo, firstName (camelCase)
//   URL keys:   android_surl, android_furl, ios_surl, ios_furl
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
  static const String merchantKey  = 'EWVUgs';
  static const String merchantSalt = 'uM9Awu56sQDRMBTs5kvzxY28FXEkB3Ig';
  static const String mid          = '9215014';
  static const bool   isTestMode   = true;
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
// Request:  SHA512(key|txnid|amount|productinfo|firstname|email|||||||||||salt)
// Response: SHA512(salt|status|||||||||||email|firstname|productinfo|amount|txnid|key)
// ─────────────────────────────────────────────────────────────────────

class PayUHashHelper {
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
        '${PayUConfig.merchantSalt}|$status||||||||||'
        '||$email|$firstName|$productInfo|${amount.toStringAsFixed(2)}'
        '|$txnId|${PayUConfig.merchantKey}';
    final expected = sha512.convert(utf8.encode(str)).toString();
    return expected.toLowerCase() == receivedHash.toLowerCase();
  }

  /// Generate hash for SDK hash challenges (V1 and V2)
  static String generateSdkHash(String hashString) {
    return sha512.convert(utf8.encode(hashString)).toString();
  }

  static String generateTxnId() =>
      'ACH${DateTime.now().millisecondsSinceEpoch}';
}

// ─────────────────────────────────────────────────────────────────────
// PAYU SERVICE  — implements PayUCheckoutProProtocol exactly
// ─────────────────────────────────────────────────────────────────────

class PayUService implements PayUCheckoutProProtocol {
  static final _db = Supabase.instance.client;
  static SupabaseClient get supabaseClient => _db;

  // SDK instance — holds the MethodChannel listener
  late PayUCheckoutProFlutter _payUFlutter;

  String? _pendingTxnId;
  int?    _pendingStudentFeeId;
  int?    _pendingInstallmentId;
  double? _pendingAmount;
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

    final firstName   = studentName.split(' ').first.isNotEmpty
        ? studentName.split(' ').first : 'Student';
    final productInfo = studentFee.feeStructure?.feeName ?? 'Fee Payment';
    final phone       = studentPhone.isNotEmpty ? studentPhone : '9999999999';
    final email       = studentEmail.isNotEmpty
        ? studentEmail : 'student@achivo.app';

    final hash = PayUHashHelper.generatePaymentHash(
      txnId: _pendingTxnId!, amount: amount,
      productInfo: productInfo, firstName: firstName, email: email,
    );

    // ── Payment params — use EXACT keys from PayUPaymentParamKey ──
    final payUPaymentParams = {
      PayUPaymentParamKey.key:          PayUConfig.merchantKey,
      PayUPaymentParamKey.transactionId: _pendingTxnId,
      PayUPaymentParamKey.amount:        amount.toStringAsFixed(2),
      PayUPaymentParamKey.productInfo:   productInfo,
      PayUPaymentParamKey.firstName:     firstName,
      PayUPaymentParamKey.email:         email,
      PayUPaymentParamKey.phone:         phone,
      PayUPaymentParamKey.android_surl:  'https://achivo.app/payu/success',
      PayUPaymentParamKey.android_furl:  'https://achivo.app/payu/failure',
      PayUPaymentParamKey.ios_surl:      'https://achivo.app/payu/success',
      PayUPaymentParamKey.ios_furl:      'https://achivo.app/payu/failure',
      PayUPaymentParamKey.environment:
      PayUConfig.isTestMode ? 'test' : 'production',
      // Hash must be passed in additionalParam for v1.4
      PayUPaymentParamKey.additionalParam: {
        'hash': hash,
      },
    };

    // ── Checkout config — use EXACT keys from PayUCheckoutProConfigKeys ──
    final payUCheckoutProConfig = {
      PayUCheckoutProConfigKeys.primaryColor:   '#1565C0',
      PayUCheckoutProConfigKeys.secondaryColor: '#FFFFFF',
      PayUCheckoutProConfigKeys.merchantName:   'Achivo',
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: true,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen:  true,
      PayUCheckoutProConfigKeys.merchantSMSPermission: true,
    };

    try {
      // Instantiate with THIS as the protocol delegate
      _payUFlutter = PayUCheckoutProFlutter(this);

      // Open the checkout screen
      await _payUFlutter.openCheckoutScreen(
        payUPaymentParams:    payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e) {
      debugPrint('❌ PayU open error: $e');
      onResult(PayUPaymentResult(
          success: false, error: 'Could not open payment gateway: $e'));
    }
  }

  // ── PayUCheckoutProProtocol — EXACT signatures from source ────────

  // generateHash(Map response)  — no return type, no callback param
  // SDK sends hash request; we compute and call hashGenerated()
  @override
  generateHash(Map response) {
    debugPrint('🔐 generateHash called: $response');
    try {
      final hashName   = response[PayUHashConstantsKeys.hashName]?.toString() ?? '';
      final hashString = response[PayUHashConstantsKeys.hashString]?.toString() ?? '';

      if (hashString.isEmpty) return;

      final digest = PayUHashHelper.generateSdkHash(hashString);

      // Send computed hash back to SDK
      _payUFlutter.hashGenerated(hash: {hashName: digest});
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

    // Verify response hash
    final isValid = PayUHashHelper.verifyResponseHash(
      receivedHash: hash,
      txnId:        _pendingTxnId ?? '',
      amount:       _pendingAmount ?? 0,
      productInfo:  data['productinfo']?.toString() ?? '',
      firstName:    data['firstname']?.toString() ?? '',
      email:        data['email']?.toString() ?? '',
      status:       status,
    );

    if (!isValid) {
      _onResult?.call(const PayUPaymentResult(
          success: false,
          error: 'Payment hash verification failed. Contact support.'));
      _clearPending();
      return;
    }

    // Record payment in DB
    try {
      final res = await _db.functions.invoke('verify-payu-payment', body: {
        'txn_id':         _pendingTxnId,
        'payu_txn_id':    payuTxnId,
        'student_fee_id': _pendingStudentFeeId,
        'installment_id': _pendingInstallmentId,
        'amount':         _pendingAmount,
        'status':         status,
        'payu_response':  data,
      });

      if (res.status == 200 && res.data?['success'] == true) {
        _onResult?.call(PayUPaymentResult(
          success: true, txnId: _pendingTxnId,
          payuTxnId: payuTxnId,
          receiptNo: res.data?['receipt_no'] as String?,
        ));
      } else {
        _onResult?.call(PayUPaymentResult(
          success: false,
          error: res.data?['error']?.toString() ?? 'Verification failed',
        ));
      }
    } catch (e) {
      debugPrint('❌ verify error: $e | txnId: $_pendingTxnId');
      _onResult?.call(PayUPaymentResult(
        success: false, txnId: _pendingTxnId, payuTxnId: payuTxnId,
        error: 'Payment captured but verification failed. '
            'Contact support with txnId: $_pendingTxnId',
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

  // onPaymentCancel(Map? response)  — takes Map? not dynamic
  @override
  void onPaymentCancel(Map? response) {
    debugPrint('⚠️ PayU cancelled: $response');
    _onResult?.call(const PayUPaymentResult(
        success: false, error: 'Payment cancelled.'));
    _clearPending();
  }

  // onError(Map? response)  — takes Map? not dynamic
  @override
  void onError(Map? response) {
    debugPrint('❌ PayU error: $response');
    final msg = response?[PayUConstants.errorMsg]?.toString()
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
  }
}