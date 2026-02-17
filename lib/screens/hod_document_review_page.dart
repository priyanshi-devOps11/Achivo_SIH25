// lib/screens/hod_document_review_page.dart
// Fixed version: removes flutter_cached_pdfview dependency,
// adds missing intl import, uses url_launcher for PDF preview.
//
// pubspec.yaml additions needed:
//   url_launcher: ^6.2.6
//   intl: ^0.19.0

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hod_models.dart';
import '../services/hod_service.dart';

class HODDocumentReviewPage extends StatefulWidget {
  final DocumentForReview document;
  final VoidCallback onReviewComplete;

  const HODDocumentReviewPage({
    Key? key,
    required this.document,
    required this.onReviewComplete,
  }) : super(key: key);

  @override
  State<HODDocumentReviewPage> createState() => _HODDocumentReviewPageState();
}

class _HODDocumentReviewPageState extends State<HODDocumentReviewPage> {
  final _remarksController = TextEditingController();
  final _pointsController = TextEditingController(text: '0');
  bool _isLoading = false;
  bool _isLoadingUrl = false;
  String? _pdfUrl;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _loadPdfUrl();
    // Pre-fill remarks if already reviewed
    if (widget.document.hodRemarks != null) {
      _remarksController.text = widget.document.hodRemarks!;
    }
    if (widget.document.pointsAwarded > 0) {
      _pointsController.text = widget.document.pointsAwarded.toString();
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfUrl() async {
    setState(() {
      _isLoadingUrl = true;
      _urlError = null;
    });
    try {
      final url = await HODService.getDocumentDownloadUrl(
          widget.document.documentUrl);
      setState(() {
        _pdfUrl = url;
        _isLoadingUrl = false;
      });
    } catch (e) {
      setState(() {
        _urlError = 'Failed to load document URL: $e';
        _isLoadingUrl = false;
      });
    }
  }

  Future<void> _openPdfInBrowser() async {
    if (_pdfUrl == null) {
      _showSnackbar('Document URL not available', Colors.red);
      return;
    }
    final uri = Uri.parse(_pdfUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar('Could not open document. Try copying the link.', Colors.red);
    }
  }

  Future<void> _approveDocument() async {
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;

    if (points <= 0) {
      _showSnackbar('Please enter a valid points value (must be > 0)', Colors.orange);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Approve Document',
      message:
      'Approve "${widget.document.title}" and award $points points to ${widget.document.studentName}?',
      confirmLabel: 'Approve',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await HODService.reviewDocument(
      documentId: widget.document.id,
      action: 'approve',
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      pointsAwarded: points,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar('Document approved — $points pts awarded!', Colors.green);
      widget.onReviewComplete();
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackbar('Failed to approve document. Please try again.', Colors.red);
    }
  }

  Future<void> _rejectDocument() async {
    if (_remarksController.text.trim().isEmpty) {
      _showSnackbar('Please provide a reason for rejection', Colors.orange);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Reject Document',
      message:
      'Reject "${widget.document.title}" submitted by ${widget.document.studentName}?',
      confirmLabel: 'Reject',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await HODService.reviewDocument(
      documentId: widget.document.id,
      action: 'reject',
      remarks: _remarksController.text.trim(),
      pointsAwarded: 0,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar('Document rejected', Colors.orange);
      widget.onReviewComplete();
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackbar('Failed to reject document. Please try again.', Colors.red);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Review Document'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(),
            _buildDocumentPreviewSection(),
            _buildReviewForm(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STUDENT HEADER
  // ─────────────────────────────────────────────

  Widget _buildStudentHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  widget.document.studentName.isNotEmpty
                      ? widget.document.studentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.studentName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll No: ${widget.document.rollNumber}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.document.status),
            ],
          ),
          const SizedBox(height: 16),
          // Document title
          Text(
            widget.document.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(widget.document.displayType, Colors.purple,
                  _getDocumentTypeIcon(widget.document.documentType)),
              _buildChip(
                DateFormat('MMM dd, yyyy').format(widget.document.createdAt),
                Colors.grey,
                Icons.calendar_today,
              ),
              if (widget.document.pointsAwarded > 0)
                _buildChip(
                  '${widget.document.pointsAwarded} pts awarded',
                  Colors.amber,
                  Icons.star,
                ),
            ],
          ),
          if (widget.document.description != null &&
              widget.document.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.document.description!,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PDF PREVIEW SECTION
  // ─────────────────────────────────────────────

  Widget _buildDocumentPreviewSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Document Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.document.fileName != null)
                  Text(
                    widget.document.fileName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Preview area
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildPreviewContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_isLoadingUrl) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading document...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_urlError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _urlError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadPdfUrl,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No document URL available',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // PDF is ready — show open button
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 52,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF Document Ready',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.document.formattedFileSize,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openPdfInBrowser,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REVIEW FORM
  // ─────────────────────────────────────────────

  Widget _buildReviewForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Review Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Points field (only shown if not rejected)
          if (!widget.document.isRejected) ...[
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              enabled: widget.document.isPending,
              decoration: InputDecoration(
                labelText: 'Points to Award *',
                hintText: 'e.g. 10',
                helperText: 'Required for approval',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                prefixIcon: const Icon(Icons.star, color: Colors.amber),
                filled: !widget.document.isPending,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Remarks field
          TextField(
            controller: _remarksController,
            enabled: widget.document.isPending,
            decoration: InputDecoration(
              labelText: widget.document.isPending
                  ? 'Remarks / Feedback'
                  : 'HOD Remarks',
              hintText: widget.document.isPending
                  ? 'Optional feedback for approval, required for rejection...'
                  : '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              prefixIcon: const Icon(Icons.comment),
              filled: !widget.document.isPending,
              fillColor: Colors.grey.shade100,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // Action area
          _buildActionArea(),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    // Already reviewed
    if (!widget.document.isPending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.document.isApproved
              ? Colors.green.withOpacity(0.08)
              : Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.document.isApproved ? Colors.green : Colors.red,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.document.isApproved
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: widget.document.isApproved ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.isApproved
                        ? 'Document Approved'
                        : 'Document Rejected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: widget.document.isApproved
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  if (widget.document.reviewedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reviewed on ${DateFormat('MMM dd, yyyy – hh:mm a').format(widget.document.reviewedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Pending — show approve / reject buttons
    return Column(
      children: [
        // Approve button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _approveDocument,
            icon: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _isLoading ? 'Processing...' : 'Approve & Award Points',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reject button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _rejectDocument,
            icon: const Icon(Icons.cancel_rounded),
            label: const Text(
              'Reject Document',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '* Remarks are required when rejecting',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'technical_skill':
        return Icons.computer;
      case 'internship':
        return Icons.work;
      case 'seminar':
        return Icons.school;
      case 'certification':
        return Icons.verified;
      default:
        return Icons.description;
    }
  }
}