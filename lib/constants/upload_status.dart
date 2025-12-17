enum UploadStatus { pending, uploaded, failed }

extension UploadStatusX on UploadStatus {
  String get value {
    switch (this) {
      case UploadStatus.pending:
        return 'pending';
      case UploadStatus.uploaded:
        return 'uploaded';
      case UploadStatus.failed:
        return 'failed';
    }
  }
}

