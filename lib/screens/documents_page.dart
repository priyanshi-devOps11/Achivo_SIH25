// lib/screens/documents_page.dart
// Web-compatible: uses FilePicker bytes instead of dart:io File

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';

class DocumentsPage extends StatefulWidget {
  final String studentId;

  const DocumentsPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String _selectedCategory = 'all';
  List<StudentDocument> _documents = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _documentTypes = [
    {
      'value': 'technical_skill',
      'label': 'Technical Skills',
      'icon': Icons.computer,
      'color': Colors.blue
    },
    {
      'value': 'internship',
      'label': 'Internship',
      'icon': Icons.work,
      'color': Colors.green
    },
    {
      'value': 'seminar',
      'label': 'Seminar',
      'icon': Icons.school,
      'color': Colors.purple
    },
    {
      'value': 'certification',
      'label': 'Certification',
      'icon': Icons.verified,
      'color': Colors.orange
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.description,
      'color': Colors.grey
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    final documents = await StudentService.getStudentDocuments(
      widget.studentId,
      documentType: _selectedCategory == 'all' ? null : _selectedCategory,
    );

    if (mounted) {
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    }
  }

  void _showUploadDialog(String documentType, String label) {
    showDialog(
      context: context,
      builder: (context) => DocumentUploadDialog(
        studentId: widget.studentId,
        documentType: documentType,
        documentTypeLabel: label,
        onSuccess: () {
          Navigator.pop(context);
          _loadDocuments();
          _showSnackBar('Document uploaded successfully!', Colors.green);
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            _buildDocumentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents Management 📁',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload and manage your academic documents',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Document',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: _documentTypes.map((type) {
              return _buildCategoryCard(
                label: type['label'],
                icon: type['icon'],
                color: type['color'],
                onTap: () =>
                    _showUploadDialog(type['value'], type['label']),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Documents',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All')),
                  ..._documentTypes
                      .map<DropdownMenuItem<String>>((type) =>
                      DropdownMenuItem<String>(
                        value: type['value'] as String,
                        child: Text(type['label'] as String),
                      ))
                      .toList(),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                    _loadDocuments();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_documents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No documents uploaded yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildDocumentCard(_documents[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(StudentDocument document) {
    Color statusColor = _getStatusColor(document.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(document.displayType,
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(document.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          if (document.description != null) ...[
            const SizedBox(height: 8),
            Text(document.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          if (document.status == 'approved' &&
              document.pointsAwarded > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${document.pointsAwarded} points awarded',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 12)),
              ],
            ),
          ],
          if (document.hodRemarks != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HOD Remarks:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(document.hodRemarks!,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

// ================================
// DOCUMENT UPLOAD DIALOG — Web-safe
// ================================

class DocumentUploadDialog extends StatefulWidget {
  final String studentId;
  final String documentType;
  final String documentTypeLabel;
  final VoidCallback onSuccess;

  const DocumentUploadDialog({
    Key? key,
    required this.studentId,
    required this.documentType,
    required this.documentTypeLabel,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _fileBytes;
  String? _fileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // ← loads bytes into memory (required for web)
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', Colors.red);
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fileBytes == null || _fileName == null) {
      _showSnackBar('Please select a PDF file', Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    final success = await StudentService.uploadStudentDocument(
      studentId: widget.studentId,
      documentType: widget.documentType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      fileBytes: _fileBytes!,
      fileName: _fileName!,
    );

    setState(() => _isUploading = false);

    if (success) {
      widget.onSuccess();
    } else {
      _showSnackBar('Failed to upload document. Check console for details.',
          Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload ${widget.documentTypeLabel}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // File picker — web-safe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border:
                  Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileBytes != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color:
                      _fileBytes != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName ?? 'No file selected',
                        style: TextStyle(
                          color: _fileBytes != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Upload'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}