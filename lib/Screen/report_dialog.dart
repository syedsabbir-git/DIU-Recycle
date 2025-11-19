import 'package:flutter/material.dart';
import 'package:diurecycle/services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String itemId;
  final String itemType; // 'product' or 'user'
  final String reportedUserId;
  final String reportedUserName;
  final String? productTitle;

  const ReportDialog({
    Key? key,
    required this.itemId,
    required this.itemType,
    required this.reportedUserId,
    required this.reportedUserName,
    this.productTitle,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _productReportReasons = [
    'Inappropriate content',
    'Spam or misleading',
    'Counterfeit or illegal items',
    'Offensive images',
    'Wrong category',
    'Duplicate listing',
    'Other',
  ];

  final List<String> _userReportReasons = [
    'Harassment or bullying',
    'Spam',
    'Inappropriate behavior',
    'Scam or fraud',
    'Fake profile',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide additional details')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success;
    if (widget.itemType == 'product') {
      success = await _reportService.reportProduct(
        productId: widget.itemId,
        productOwnerId: widget.reportedUserId,
        productOwnerName: widget.reportedUserName,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );
    } else {
      success = await _reportService.reportUser(
        userId: widget.reportedUserId,
        userName: widget.reportedUserName,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully. We will review it soon.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = widget.itemType == 'product' 
        ? _productReportReasons 
        : _userReportReasons;

    return AlertDialog(
      title: Text(
        widget.itemType == 'product' ? 'Report Listing' : 'Report User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.itemType == 'product' && widget.productTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Reporting: ${widget.productTitle}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (widget.itemType == 'user')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Reporting user: ${widget.reportedUserName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            const Text(
              'Select a reason:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            const SizedBox(height: 16),
            const Text(
              'Additional details:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Provide more information about this report...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your report will be reviewed by our moderation team.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

/// Helper function to show report dialog
Future<void> showReportDialog({
  required BuildContext context,
  required String itemId,
  required String itemType,
  required String reportedUserId,
  required String reportedUserName,
  String? productTitle,
}) {
  return showDialog(
    context: context,
    builder: (context) => ReportDialog(
      itemId: itemId,
      itemType: itemType,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      productTitle: productTitle,
    ),
  );
}
