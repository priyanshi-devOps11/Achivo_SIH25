// lib/utils/email_diagnostic.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class EmailDiagnostic {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Comprehensive email delivery test
  static Future<DiagnosticResult> runFullDiagnostic(String email) async {
    final result = DiagnosticResult();

    print('\n╔════════════════════════════════════════════╗');
    print('║   ACHIVO EMAIL DIAGNOSTIC TEST             ║');
    print('╚════════════════════════════════════════════╝\n');

    // Test 1: Email Format
    print('📝 Test 1: Email Format Validation');
    if (RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      print('   ✅ Email format is valid');
      result.emailValid = true;
    } else {
      print('   ❌ Invalid email format');
      result.emailValid = false;
      result.criticalError = 'Invalid email format';
      return result;
    }

    // Test 2: Check existing registration
    print('\n🔍 Test 2: Checking Existing Registration');
    try {
      final existing = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        print('   ⚠️  Email already registered');
        result.alreadyRegistered = true;
      } else {
        print('   ✅ Email available for registration');
        result.alreadyRegistered = false;
      }
    } catch (e) {
      print('   ⚠️  Could not check: $e');
    }

    // Test 3: Attempt OTP send
    print('\n📧 Test 3: Attempting to Send OTP');
    print('   Email: $email');
    print('   Provider: Resend (smtp.resend.com:587)');
    print('   Timestamp: ${DateTime.now()}');

    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
        shouldCreateUser: false,
      );

      print('   ✅ OTP request successful!');
      result.otpSent = true;
      result.successMessage = 'OTP sent successfully';

    } on AuthException catch (e) {
      print('   ❌ OTP send failed');
      print('   Error: ${e.message}');
      print('   Status: ${e.statusCode}');

      result.otpSent = false;
      result.error = e.message;
      result.statusCode = e.statusCode;

      // Diagnose specific errors
      if (e.message.contains('rate limit')) {
        result.diagnosis = 'RATE_LIMIT';
        result.solution = 'Wait 60 minutes before retrying. '
            'Supabase/Resend limit OTP requests to prevent abuse.';
      } else if (e.message.contains('SMTP') || e.message.contains('unexpected_failure')) {
        result.diagnosis = 'SMTP_ERROR';
        result.solution = 'Possible issues:\n'
            '• Resend API key might be invalid\n'
            '• SMTP configuration issue in Supabase\n'
            '• Resend service temporarily down';
      } else {
        result.diagnosis = 'UNKNOWN';
        result.solution = 'Unknown error. Check Resend logs.';
      }
    }

    // Test 4: Email provider analysis
    print('\n📬 Test 4: Email Provider Analysis');
    final domain = email.split('@').last.toLowerCase();
    if (domain == 'gmail.com') {
      print('   📧 Gmail detected');
      print('   💡 Tip: Check "Promotions" and "Spam" tabs');
      result.emailProvider = 'Gmail';
    } else if (domain == 'outlook.com' || domain == 'hotmail.com') {
      print('   📧 Outlook detected');
      print('   💡 Tip: Check "Junk Email" folder');
      result.emailProvider = 'Outlook';
    } else if (domain == 'yahoo.com') {
      print('   📧 Yahoo detected');
      print('   💡 Tip: Check "Spam" folder');
      result.emailProvider = 'Yahoo';
    } else {
      print('   📧 Custom email provider: $domain');
      print('   💡 Tip: Check spam folder');
      result.emailProvider = domain;
    }

    // Summary
    print('\n╔════════════════════════════════════════════╗');
    print('║   DIAGNOSTIC SUMMARY                       ║');
    print('╚════════════════════════════════════════════╝');
    print('');
    print('Email Valid: ${result.emailValid ? "✅" : "❌"}');
    print('Already Registered: ${result.alreadyRegistered ? "⚠️  Yes" : "✅ No"}');
    print('OTP Sent: ${result.otpSent ? "✅ Yes" : "❌ No"}');

    if (result.otpSent) {
      print('\n🎉 SUCCESS! Check your email:');
      print('   1. Check inbox first');
      print('   2. Check spam/junk folder');
      print('   3. Wait 2-3 minutes for delivery');
      print('   4. Search for "Achivo" or "verification"');
    } else {
      print('\n❌ FAILED: ${result.diagnosis}');
      print('\n💡 Solution:');
      print('   ${result.solution}');
    }
    print('\n═══════════════════════════════════════════════\n');

    return result;
  }

  /// Show diagnostic results in a dialog
  static void showResultDialog(BuildContext context, DiagnosticResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.otpSent ? Icons.check_circle : Icons.error,
              color: result.otpSent ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.otpSent ? 'Email Sent!' : 'Diagnostic Results'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Email Valid', result.emailValid),
              _buildResultRow('Available', !result.alreadyRegistered),
              _buildResultRow('OTP Sent', result.otpSent),

              if (result.emailProvider != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Email Provider: ${result.emailProvider}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],

              if (!result.otpSent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Error: ${result.diagnosis}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.solution ?? 'Unknown error',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (result.otpSent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Next Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Check your email inbox\n'
                            '2. Also check spam/junk folder\n'
                            '3. Search for "Achivo" or "verification"\n'
                            '4. Code expires in 60 seconds',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildResultRow(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class DiagnosticResult {
  bool emailValid = false;
  bool alreadyRegistered = false;
  bool otpSent = false;
  String? emailProvider;
  String? error;
  String? statusCode;
  String? diagnosis;
  String? solution;
  String? successMessage;
  String? criticalError;
}

// ═══════════════════════════════════════════════════════════════════
// HOW TO USE IN YOUR FACULTY AUTH PAGE:
// ═══════════════════════════════════════════════════════════════════

// Add this button to your registration page for debugging:

/*
ElevatedButton.icon(
  onPressed: () async {
    final result = await EmailDiagnostic.runFullDiagnostic(
      _emailController.text.trim()
    );

    if (mounted) {
      EmailDiagnostic.showResultDialog(context, result);
    }
  },
  icon: const Icon(Icons.bug_report),
  label: const Text('Run Email Diagnostic'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
  ),
)
*/