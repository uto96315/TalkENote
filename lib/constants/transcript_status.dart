enum TranscriptStatus {
  idle,
  transcribing,
  done,
  failed,
}

extension TranscriptStatusX on TranscriptStatus {
  String get value {
    switch (this) {
      case TranscriptStatus.idle:
        return 'idle';
      case TranscriptStatus.transcribing:
        return 'transcribing';
      case TranscriptStatus.done:
        return 'done';
      case TranscriptStatus.failed:
        return 'failed';
    }
  }

  static TranscriptStatus fromValue(String value) {
    switch (value) {
      case 'transcribing':
        return TranscriptStatus.transcribing;
      case 'done':
        return TranscriptStatus.done;
      case 'failed':
        return TranscriptStatus.failed;
      case 'idle':
      default:
        return TranscriptStatus.idle;
    }
  }
}

