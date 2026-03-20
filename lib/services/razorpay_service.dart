// lib/services/razorpay_service.dart
//
// ══════════════════════════════════════════════════════════════════════
// RAZORPAY PAYMENT INTEGRATION FOR ACHIVO
//
// This service handles:
//   1. Creating Razorpay orders via your backend/Supabase Edge Function
//   2. Launching the Razorpay checkout UI
//   3. Verifying payment signature (server-side via Edge Function)
//   4. Recording verified payments in your DB
//
// SETUP STEPS:
//   1. Add to pubspec.yaml:
//        razorpay_flutter: ^1.3.6
//   2. Android: minSdkVersion 19 in android/app/build.gradle
//   3. iOS: Add to Info.plist (see bottom of this file)
//   4. Deploy the Supabase Edge Functions (see /supabase/functions/)
//   5. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in Supabase secrets
// ══════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_models.dart';
import 'fee_service.dart';

// ─────────────────────────────────────────────────────────────────────
// RESULT TYPES
// ─────────────────────────────────────────────────────────────────────

class RazorpayOrderResult {
  final bool success;
  final String? orderId;      // rzp_order id from Razorpay
  final String? error;

  const RazorpayOrderResult({
    required this.success,
    this.orderId,
    this.error,
  });
}

class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;     // rzp_payment id
  final String? orderId;
  final String? receiptNo;     // internal receipt number
  final String? error;

  const RazorpayPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.receiptNo,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────
// RAZORPAY SERVICE
// ─────────────────────────────────────────────────────────────────────

class RazorpayService {
  static final _db = Supabase.instance.client;

  // Your Razorpay KEY ID (test or live)
  // Store this in your app config / env — never hardcode live keys in source
  static const String _keyId = 'rzp_test_YOUR_KEY_ID_HERE'; // ← replace

  Razorpay? _razorpay;
  String? _pendingStudentFeeId;
  String? _pendingInstallmentId;
  double? _pendingAmount;
  String? _pendingOrderId;

  // Callbacks
  Function(RazorpayPaymentResult)? _onResult;

  // ── Lifecycle ─────────────────────────────────────────────────────

  void initialize() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  // ── PUBLIC: start a payment ────────────────────────────────────────

  /// Call this to initiate a Razorpay payment.
  ///
  /// [studentFee]    – the student_fees row
  /// [amount]        – exact amount to charge (in ₹, not paise)
  /// [installmentId] – optional installment id
  /// [studentName]   – shown in checkout UI
  /// [studentEmail]  – prefilled in checkout UI
  /// [studentPhone]  – prefilled in checkout UI
  /// [onResult]      – callback with success/failure
  Future<void> startPayment({
    required StudentFee studentFee,
    required double amount,
    int? installmentId,
    required String studentName,
    required String studentEmail,
    required String studentPhone,
    required Function(RazorpayPaymentResult) onResult,
  }) async {
    _onResult = onResult;
    _pendingStudentFeeId = studentFee.id.toString();
    _pendingInstallmentId = installmentId?.toString();
    _pendingAmount = amount;

    // Step 1: Create a Razorpay order on the server
    final orderResult = await _createOrder(
      studentFeeId: studentFee.id,
      amount: amount,
      receipt: 'sfee_${studentFee.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!orderResult.success) {
      onResult(RazorpayPaymentResult(
        success: false,
        error: orderResult.error ?? 'Failed to create payment order',
      ));
      return;
    }

    _pendingOrderId = orderResult.orderId;

    // Step 2: Open Razorpay checkout
    final options = {
      'key':         _keyId,
      'order_id':    orderResult.orderId!,
      'amount':      (amount * 100).toInt(), // Razorpay expects paise
      'name':        'Achivo',
      'description': studentFee.feeStructure?.feeName ?? 'Fee Payment',
      'prefill': {
        'name':    studentName,
        'email':   studentEmail,
        'contact': studentPhone,
      },
      'theme': {
        'color': '#1565C0',  // Indigo to match app
      },
      'notes': {
        'student_fee_id':  _pendingStudentFeeId,
        'installment_id':  _pendingInstallmentId ?? '',
      },
      // Enable all Indian payment methods
      'config': {
        'display': {
          'blocks': {
            'banks': {
              'name': 'Pay via Net Banking',
              'instruments': [
                {'method': 'netbanking'}
              ],
            },
            'upi': {
              'name': 'Pay via UPI',
              'instruments': [
                {'method': 'upi'}
              ],
            },
          },
          'sequence': ['block.banks', 'block.upi'],
          'preferences': {'show_default_blocks': true},
        },
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      onResult(RazorpayPaymentResult(
        success: false,
        error: 'Could not open payment gateway: $e',
      ));
    }
  }

  // ── PRIVATE: Create order via Supabase Edge Function ──────────────

  Future<RazorpayOrderResult> _createOrder({
    required int studentFeeId,
    required double amount,
    required String receipt,
  }) async {
    try {
      final session = _db.auth.currentSession;
      if (session == null) {
        return const RazorpayOrderResult(
            success: false, error: 'Not authenticated');
      }

      // Call your Supabase Edge Function
      final response = await _db.functions.invoke(
        'create-razorpay-order',
        body: {
          'student_fee_id': studentFeeId,
          'amount':         amount,
          'receipt':        receipt,
        },
      );

      if (response.status != 200) {
        final msg = response.data?['error'] ?? 'Server error ${response.status}';
        return RazorpayOrderResult(success: false, error: msg.toString());
      }

      final orderId = response.data?['order_id'] as String?;
      if (orderId == null) {
        return const RazorpayOrderResult(
            success: false, error: 'No order_id returned');
      }

      return RazorpayOrderResult(success: true, orderId: orderId);
    } catch (e) {
      return RazorpayOrderResult(success: false, error: e.toString());
    }
  }

  // ── PRIVATE: Razorpay event handlers ──────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Razorpay success: ${response.paymentId}');

    // Verify signature + record payment via Edge Function
    try {
      final verifyResponse = await _db.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'razorpay_order_id':    response.orderId,
          'razorpay_payment_id':  response.paymentId,
          'razorpay_signature':   response.signature,
          'student_fee_id':       int.parse(_pendingStudentFeeId!),
          'installment_id':       _pendingInstallmentId != null
              ? int.tryParse(_pendingInstallmentId!)
              : null,
          'amount':               _pendingAmount,
        },
      );

      if (verifyResponse.status == 200 &&
          verifyResponse.data?['success'] == true) {
        _onResult?.call(RazorpayPaymentResult(
          success:   true,
          paymentId: response.paymentId,
          orderId:   response.orderId,
          receiptNo: verifyResponse.data?['receipt_no'] as String?,
        ));
      } else {
        final msg = verifyResponse.data?['error'] ?? 'Verification failed';
        _onResult?.call(RazorpayPaymentResult(
          success: false,
          error:   msg.toString(),
        ));
      }
    } catch (e) {
      // Payment succeeded but verification call failed.
      // In production, log this for manual reconciliation.
      debugPrint('❌ Verification error: $e');
      _onResult?.call(RazorpayPaymentResult(
        success:   false,
        paymentId: response.paymentId,
        error:
        'Payment captured but verification failed. '
            'Contact support with ID: ${response.paymentId}',
      ));
    }

    _clearPending();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Razorpay error: ${response.code} — ${response.message}');

    String message;
    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        message = 'Payment cancelled by user.';
        break;
      case Razorpay.NETWORK_ERROR:
        message = 'Network error. Please check your connection and try again.';
        break;
      case Razorpay.INVALID_OPTIONS:
        message = 'Invalid payment configuration. Please contact support.';
        break;
      default:
        message = response.message ??
            'Payment failed (code ${response.code}). Please try again.';
    }

    _onResult?.call(RazorpayPaymentResult(success: false, error: message));
    _clearPending();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔗 External wallet: ${response.walletName}');
    // External wallet flows (PhonePe, Paytm etc.) complete asynchronously.
    // Razorpay will still call _onPaymentSuccess / _onPaymentError
    // once the wallet transaction completes.
  }

  void _clearPending() {
    _pendingStudentFeeId  = null;
    _pendingInstallmentId = null;
    _pendingAmount        = null;
    _pendingOrderId       = null;
  }
}
