class ProcessingStatus {
  final String fileName;
  final String
      status; // 'pending', 'processing', 'success', 'error', 'already_inst'
  final String? message;

  ProcessingStatus(this.fileName, this.status, {this.message});
}
