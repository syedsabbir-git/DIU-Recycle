import 'package:flutter/material.dart';
import 'package:diurecycle/Screen/report_dialog.dart';
import 'package:diurecycle/services/report_service.dart';

class ReportButton extends StatelessWidget {
  final String itemId;
  final String itemType; // 'product' or 'user'
  final String reportedUserId;
  final String reportedUserName;
  final String? productTitle;
  final bool showAsIcon;
  final Color? iconColor;

  const ReportButton({
    Key? key,
    required this.itemId,
    required this.itemType,
    required this.reportedUserId,
    required this.reportedUserName,
    this.productTitle,
    this.showAsIcon = false,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();

    return FutureBuilder<bool>(
      future: reportService.hasUserReported(
        itemId: itemId,
        itemType: itemType,
      ),
      builder: (context, snapshot) {
        final hasReported = snapshot.data ?? false;

        if (showAsIcon) {
          return IconButton(
            icon: Icon(
              hasReported ? Icons.flag : Icons.flag_outlined,
              color: hasReported ? Colors.red : (iconColor ?? Colors.grey),
            ),
            tooltip: hasReported ? 'Already reported' : 'Report this ${itemType}',
            onPressed: hasReported
                ? null
                : () => _showReport(context),
          );
        }

        return TextButton.icon(
          icon: Icon(
            hasReported ? Icons.flag : Icons.flag_outlined,
            size: 18,
            color: hasReported ? Colors.grey : Colors.red,
          ),
          label: Text(
            hasReported ? 'Reported' : 'Report',
            style: TextStyle(
              color: hasReported ? Colors.grey : Colors.red,
            ),
          ),
          onPressed: hasReported
              ? null
              : () => _showReport(context),
        );
      },
    );
  }

  void _showReport(BuildContext context) {
    showReportDialog(
      context: context,
      itemId: itemId,
      itemType: itemType,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      productTitle: productTitle,
    );
  }
}
