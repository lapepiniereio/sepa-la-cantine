import 'package:flutter/material.dart';

import '../models/processing_status.dart';

class FileStatusList extends StatelessWidget {
  final List<ProcessingStatus> processingStatus;

  const FileStatusList({
    super.key,
    required this.processingStatus,
  });

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
      case 'processing':
        return const Icon(Icons.refresh, color: Colors.blue);
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      case 'already_inst':
        return const Icon(Icons.info_outline, color: Colors.orange);
      default:
        return const Icon(Icons.help);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: processingStatus.length,
      itemBuilder: (context, index) {
        final status = processingStatus[index];
        return Card(
          child: ListTile(
            leading: _getStatusIcon(status.status),
            title: Text(status.fileName),
            subtitle: status.message != null
                ? Text(
                    status.message!,
                    style: TextStyle(
                      color: status.status == 'error'
                          ? Colors.red
                          : status.status == 'already_inst'
                              ? Colors.orange
                              : null,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
