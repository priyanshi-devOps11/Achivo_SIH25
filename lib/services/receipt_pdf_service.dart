// lib/services/receipt_pdf_service.dart
// Generates, uploads, and shares PDF receipts for Achivo fee system.
// Requirements: pdf ^3.10.8, printing ^5.13.1

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fee_models.dart';

class ReceiptPdfService {
  static final _db = Supabase.instance.client;

  // ─────────────────────────────────────────────────────
  // Generate PDF bytes from a PaymentReceipt object
  // ─────────────────────────────────────────────────────

  static Future<Uint8List> generatePdf(PaymentReceipt r) async {
    final pdf = pw.Document(
      title:  'Fee Receipt ${r.receiptNumber}',
      // FIX: was r.instituteName — now always available via the model field
      author: r.instituteName.isNotEmpty ? r.instituteName : 'Achivo',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin:     const pw.EdgeInsets.all(30),
        build: (pw.Context ctx) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border:       pw.Border.all(color: PdfColors.indigo700, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ── HEADER ──────────────────────────────────────
                pw.Center(
                  child: pw.Column(children: [
                    pw.Text(
                      // FIX: use r.instituteName (model field, never null)
                      r.instituteName.isNotEmpty
                          ? r.instituteName.toUpperCase()
                          : 'ACHIVO',
                      style: pw.TextStyle(
                        fontSize:   16,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColors.indigo700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize:      13,
                        color:         PdfColors.grey600,
                        letterSpacing: 2,
                      ),
                    ),
                  ]),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.indigo300, thickness: 1),
                pw.SizedBox(height: 8),

                // ── RECEIPT NUMBER + DATE ────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Receipt No: ${r.receiptNumber}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.Text(
                      // FIX: was r.paymentDate — now available via model field
                      'Date: ${DateFormat('dd MMM yyyy').format(r.paymentDate)}',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // ── STUDENT DETAILS ──────────────────────────────
                _sectionHeader('Student Details'),
                _row('Student Name', r.studentName),
                _row('Roll Number',  r.rollNumber),
                _row('Department',   r.departmentName),
                _row('Academic Year', r.academicYear),
                pw.SizedBox(height: 10),

                // ── FEE DETAILS ──────────────────────────────────
                _sectionHeader('Fee Details'),
                _row('Fee Head', r.feeStructureName),
                if (r.installmentLabel != null)
                  _row('Installment', r.installmentLabel!),
                pw.SizedBox(height: 10),

                // ── PAYMENT DETAILS ──────────────────────────────
                _sectionHeader('Payment Details'),
                _row('Payment Method', r.paymentMethod.toUpperCase()),
                if (r.transactionId != null)
                  _row('Transaction ID', r.transactionId!),
                // FIX: was r.paymentDate — use model field
                _row('Payment Date',
                    DateFormat('dd MMM yyyy, hh:mm a').format(r.paymentDate)),
                pw.SizedBox(height: 10),

                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 6),

                // ── AMOUNT SUMMARY ───────────────────────────────
                _amountRow('Total Fee',         '₹${_fmt(r.totalFee)}'),
                _amountRow('Previously Paid',   '₹${_fmt(r.amountPaidBefore)}'),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                _amountRow(
                  'Amount Paid (This Payment)',
                  '₹${_fmt(r.amountPaid)}',
                  bold:  true,
                  color: PdfColors.green700,
                ),
                _amountRow(
                  'Balance Remaining',
                  '₹${_fmt(r.remainingAfter)}',
                  bold:  true,
                  color: r.remainingAfter > 0
                      ? PdfColors.orange700
                      : PdfColors.green700,
                ),
                pw.SizedBox(height: 16),

                // ── STATUS BANNER ────────────────────────────────
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: r.remainingAfter == 0
                          ? PdfColors.green50
                          : PdfColors.orange50,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(
                        color: r.remainingAfter == 0
                            ? PdfColors.green700
                            : PdfColors.orange700,
                      ),
                    ),
                    child: pw.Text(
                      r.remainingAfter == 0
                          ? '✓  FULL PAYMENT RECEIVED'
                          : 'PARTIAL PAYMENT — BALANCE DUE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize:   11,
                        color: r.remainingAfter == 0
                            ? PdfColors.green700
                            : PdfColors.orange700,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 6),

                // ── FOOTER ───────────────────────────────────────
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated receipt and does not'
                        ' require a signature.',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────
  // Share / Print the PDF (no storage needed)
  // ─────────────────────────────────────────────────────

  static Future<void> shareReceipt(PaymentReceipt r) async {
    final bytes = await generatePdf(r);
    await Printing.sharePdf(
      bytes:    bytes,
      filename: '${r.receiptNumber}.pdf',
    );
  }

  // ─────────────────────────────────────────────────────
  // Generate PDF, upload to Supabase storage, and update
  // payment_receipts.receipt_pdf_url in the DB.
  // Returns the storage path, or null on failure.
  // ─────────────────────────────────────────────────────

  static Future<String?> generateAndUpload(PaymentReceipt r) async {
    try {
      final bytes = await generatePdf(r);
      final path  = '${r.rollNumber}/receipts/${r.receiptNumber}.pdf';

      await _db.storage.from('fee-documents').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert:      true,
        ),
      );

      await _db
          .from('payment_receipts')
          .update({'receipt_pdf_url': path})
          .eq('id', r.id);

      return path;
    } catch (e) {
      debugPrint('❌ ReceiptPdfService.generateAndUpload: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  // Get a signed URL (valid 1 hour) for a stored PDF
  // ─────────────────────────────────────────────────────

  static Future<String?> getSignedUrl(String storagePath) async {
    try {
      return await _db.storage
          .from('fee-documents')
          .createSignedUrl(storagePath, 3600);
    } catch (e) {
      debugPrint('❌ ReceiptPdfService.getSignedUrl: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────

  static String _fmt(double v) => NumberFormat('#,##,###.##').format(v);

  static pw.Widget _sectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize:   10,
          color:      PdfColors.indigo700,
        ),
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Text(': ',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700)),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(
      String label,
      String value, {
        bool bold       = false,
        PdfColor? color,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize:   10,
              color:      PdfColors.grey700,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize:   11,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}