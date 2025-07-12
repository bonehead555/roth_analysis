import 'dart:io';

/// Enumeraton of possible message severities.
enum MessageSeverity {
  info('Information'),
  warning('Warning'),
  error('Error');

  final String label;

  /// Returns a human readable string representing the message severity.
  const MessageSeverity(this.label);
}

/// Class to represent a single message.
/// * [severity] - [MessageSeverity] for this message.
/// * [message] - Message text for this message.
class Message {
  final MessageSeverity severity;
  final String message;
  const Message(this.severity, this.message);

  @override
  String toString() {
    return '${severity.label}: $message';
  }
}

/// Class represnting a collection of messages.
class MessageService {
  int _errorCount = 0;
  int _warningCount = 0;
  int _infoCount = 0;
  final List<Message> _messages = [];

  /// Constructor.
  MessageService();

  /// Returns the number of messages held by the service with severity of error.
  int get errorCount => _errorCount;

  /// Returns the number of messages held by the service with severity of warning.
  int get warningCount => _warningCount;

  /// Returns the number of messages held by the service with severity of info.
  int get infoCount => _infoCount;

  /// Returns the total number messages held by this service, independent of severity.
  int get counts => errorCount + warningCount + infoCount;

  /// Adds an "info" message to the service.
  void addInfo(String text) {
    _messages.add(Message(MessageSeverity.info, text));
    _infoCount++;
  }

  /// Adds a "warning" message to the service.
  void addWarning(String text) {
    _messages.add(Message(MessageSeverity.warning, text));
    _warningCount++;
  }

  /// Adds an "error" message to the service.
  void addError(String text) {
    _messages.add(Message(MessageSeverity.error, text));
    _errorCount++;
  }

  /// Resets the service so that it has zero messages.
  void clearAllMessages() {
    _messages.clear();
    _infoCount = 0;
    _warningCount = 0;
    _errorCount = 0;
  }

  /// Gets a list of all the messages currently held by the service.
  List<Message> getMessages() {
    return List.unmodifiable(_messages);
  }

  /// Gets a list of all the messages of the specified [severity] currently held by the service.
  List<Message> getFilteredMessages(MessageSeverity severity) {
    return List.unmodifiable(
        _messages.where((item) => item.severity == severity).toList());
  }

  /// Creates a string containing N lines where each line is a CSV representation of one [Message]
  /// held in the [MessageService].
  String dumpMessages() {
    StringBuffer buffer = StringBuffer();
    String header = 'Type, Message';
    buffer.write(header);
    buffer.write(Platform.lineTerminator);
    for (final message in getMessages()) {
      String csvLine = '${message.severity.label},"${message.message}"';
      buffer.write(csvLine);
      buffer.write(Platform.lineTerminator);
    }
    return buffer.toString();
  }

  /// Writes/Dumps the [MessageService] messages to a CSV file specified as [fullPath].
  /// Each [Message] is output as one CSV line.
  void dumpToFile(String fullPath) {
    final file = File(fullPath);
    file.writeAsStringSync(dumpMessages());
  }
}
