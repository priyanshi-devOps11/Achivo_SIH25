// lib/services/razorpay_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Razorpay payment integration for Achivo fee system.
// Replaces payu_service.dart — drop-in compatible with the same result model.
//
// pubspec.yaml dependency:
//   razorpay_flutter: ^1.3.7
//
// Android: add internet permission in AndroidManifest.xml (already present in
//   most Flutter apps).
// iOS: no extra setup needed for test mode.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/secrets.dart';
import '../models/fee_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG  —  replace with your live key before production release
// ─────────────────────────────────────────────────────────────────────────────

class RazorpayConfig {
  /// Test key from Razorpay Dashboard → Settings → API Keys
  static const String keyId = Secrets.razorpayKeyId;

  /// Currency (INR for India)
  static const String currency = 'INR';

  /// Your app / institute name shown on the Razorpay checkout sheet
  static const String companyName = 'Achivo';

  /// Optional: logo URL (must be HTTPS, shown on checkout sheet)
  static const String? logoUrl = null;

  /// Theme colour on checkout sheet (hex without #)
  static const String themeColor = '#3F51B5'; // Indigo
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT MODEL  —  identical shape to the old PayUPaymentResult
// ─────────────────────────────────────────────────────────────────────────────

class RazorpayPaymentResult {
  final bool success;
  final String? txnId;       // our internal txn id (order id prefix)
  final String? razorpayId;  // razorpay payment id (pay_XXXXXXXX)
  final String? orderId;     // razorpay order id   (order_XXXXXXXX)
  final String? receiptNo;
  final String? error;

  const RazorpayPaymentResult({
    required this.success,
    this.txnId,
    this.razorpayId,
    this.orderId,
    this.receiptNo,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class RazorpayService {
  static final _db = Supabase.instance.client;
  static SupabaseClient get supabaseClient => _db;

  late Razorpay _razorpay;

  // Pending payment state
  int?    _pendingStudentFeeId;
  int?    _pendingInstallmentId;
  double? _pendingAmount;
  String? _pendingTxnId;
  Function(RazorpayPaymentResult)? _onResult;

  // ── Init / dispose ──────────────────────────────────────────────────────

  void _init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  /// Call when the widget/state that started the payment is disposed.
  void dispose() {
    _razorpay.clear();
  }

  // ── Public: start a payment ─────────────────────────────────────────────

  Future<void> startPayment({
    required BuildContext context,
    required StudentFee studentFee,
    required double amount,
    int? installmentId,
    required String studentName,
    required String studentEmail,
    required String studentPhone,
    required Function(RazorpayPaymentResult) onResult,
  }) async {
    _onResult             = onResult;
    _pendingStudentFeeId  = studentFee.id;
    _pendingInstallmentId = installmentId;
    _pendingAmount        = amount;
    _pendingTxnId         = 'ACH${DateTime.now().millisecondsSinceEpoch}';

    // Amount in paise (Razorpay requires integer paise)
    final amountPaise = (amount * 100).round();

    // Safe name / email / phone
    final name  = studentName.trim().isEmpty ? 'Student' : studentName.trim();
    final email = studentEmail.trim().isEmpty
        ? 'student@achivo.app'
        : studentEmail.trim();
    final phone = studentPhone.trim().isEmpty ? '9999999999' : studentPhone.trim();

    // Fee description shown on checkout sheet
    final description = studentFee.feeStructure?.feeName ?? 'Fee Payment';

    debugPrint('💳 Starting Razorpay payment');
    debugPrint('   TxnId: $_pendingTxnId | Amount: ₹$amount (${amountPaise}p)');

    final options = <String, dynamic>{
      'key':          RazorpayConfig.keyId,
      'amount':       amountPaise,
      'currency':     RazorpayConfig.currency,
      'name':         RazorpayConfig.companyName,
      'description':  description,
      'order_id':     '', // leave empty for test; set a Razorpay Order ID for production
      'prefill': {
        'name':    name,
        'email':   email,
        'contact': phone,
      },
      'theme': {
        'color': RazorpayConfig.themeColor,
      },
      'notes': {
        'student_fee_id':  _pendingStudentFeeId.toString(),
        'installment_id':  (_pendingInstallmentId ?? '').toString(),
        'internal_txn_id': _pendingTxnId!,
      },
      // Show all payment methods by default:
      // UPI, cards, net banking, wallets
      // Remove this block to use Razorpay's smart defaults
      // 'config': {
      //   'display': {
      //     'blocks': {'utib': {'name': 'Pay using UPI', 'instruments': [{'method': 'upi'}]}},
      //     'sequence': ['block.utib'],
      //     'preferences': {'show_default_blocks': true},
      //   },
      // },
    };

    // Add logo if configured
    if (RazorpayConfig.logoUrl != null) {
      options['image'] = RazorpayConfig.logoUrl!;
    }

    try {
      _init();
      _razorpay.open(options);
    } catch (e, st) {
      debugPrint('❌ Razorpay open error: $e\n$st');
      onResult(RazorpayPaymentResult(
        success: false,
        error: 'Could not open payment gateway: $e',
      ));
      _clearPending();
    }
  }

  // ── Razorpay callbacks ──────────────────────────────────────────────────

  void _onSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Razorpay success');
    debugPrint('   paymentId: ${response.paymentId}');
    debugPrint('   orderId:   ${response.orderId}');
    debugPrint('   signature: ${response.signature}');

    final razorpayId = response.paymentId ?? '';
    final orderId    = response.orderId   ?? '';
    final signature  = response.signature ?? '';

    // Record the payment via Supabase (auto-verified for online payments)
    try {
      final res = await _db.rpc('record_fee_payment', params: {
        'p_student_fee_id':  _pendingStudentFeeId,
        'p_installment_id':  _pendingInstallmentId,
        'p_payment_method':  'online',
        'p_amount':          _pendingAmount,
        'p_transaction_id':  razorpayId,
        'p_transaction_ref': orderId,
        'p_bank_name':       null,
        'p_proof_url':       null,
        'p_auto_verify':     true,
      });

      final data = res as Map<String, dynamic>;

      if (data['success'] == true) {
        _onResult?.call(RazorpayPaymentResult(
          success:    true,
          txnId:      _pendingTxnId,
          razorpayId: razorpayId,
          orderId:    orderId,
          receiptNo:  data['receipt_no'] as String?,
        ));
      } else {
        // DB error — but payment succeeded at Razorpay; don't mark as failed
        _onResult?.call(RazorpayPaymentResult(
          success:    true,
          txnId:      _pendingTxnId,
          razorpayId: razorpayId,
          orderId:    orderId,
          error:      'Payment received. Ref: $razorpayId',
        ));
      }
    } catch (e) {
      debugPrint('❌ record_fee_payment error: $e');
      // Payment succeeded at Razorpay — don't mark as failed
      _onResult?.call(RazorpayPaymentResult(
        success:    true,
        txnId:      _pendingTxnId,
        razorpayId: razorpayId,
        orderId:    orderId,
        error:      'Payment captured. Ref: $razorpayId',
      ));
    }

    _clearPending();
  }

  void _onError(PaymentFailureResponse response) {
    debugPrint('❌ Razorpay failure: ${response.code} — ${response.message}');

    // code 0 = user dismissed / cancelled without paying
    final userCancelled = response.code == Razorpay.PAYMENT_CANCELLED;

    _onResult?.call(RazorpayPaymentResult(
      success: false,
      error: userCancelled
          ? 'Payment cancelled.'
          : (response.message ?? 'Payment failed. Please try again.'),
    ));
    _clearPending();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('💰 External wallet: ${response.walletName}');
    // Razorpay redirects to the wallet app — result comes via success/error
    // Nothing to do here
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _clearPending() {
    _pendingStudentFeeId  = null;
    _pendingInstallmentId = null;
    _pendingAmount        = null;
    _pendingTxnId         = null;
    _onResult             = null;
    try { _razorpay.clear(); } catch (_) {}
  }
}