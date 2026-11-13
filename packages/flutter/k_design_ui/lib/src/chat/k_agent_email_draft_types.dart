import 'package:flutter/foundation.dart';

enum KAgentEmailDraftStatus { pending, submitting, sent, discarded }

enum KAgentEmailDraftField { to, cc, bcc, subject, markdown }

@immutable
class KAgentEmailDraftValue {
  const KAgentEmailDraftValue({
    required this.to,
    required this.subject,
    required this.markdown,
    this.cc = '',
    this.bcc = '',
  });

  /// Display strings; recipient parsing and policy belong to the host.
  final String to, cc, bcc, subject, markdown;
  KAgentEmailDraftValue copyWith({
    String? to,
    String? cc,
    String? bcc,
    String? subject,
    String? markdown,
  }) => KAgentEmailDraftValue(
    to: to ?? this.to,
    cc: cc ?? this.cc,
    bcc: bcc ?? this.bcc,
    subject: subject ?? this.subject,
    markdown: markdown ?? this.markdown,
  );
}

@immutable
class KAgentEmailDraftAttachment {
  const KAgentEmailDraftAttachment({
    required this.id,
    required this.name,
    this.description,
  });
  final String id, name;
  final String? description;
}

@immutable
class KAgentEmailDraftLabels {
  const KAgentEmailDraftLabels({
    this.from = 'From',
    this.to = 'To',
    this.cc = 'Cc',
    this.bcc = 'Bcc',
    this.subject = 'Subject',
    this.message = 'Message',
    this.showBcc = 'Add Bcc',
    this.recipientPlaceholder = 'name@example.com',
    this.attachments = 'Attachments',
    this.addAttachment = 'Add attachment',
    this.removeAttachment,
    this.send = 'Send',
    this.discard = 'Discard',
    this.expand = 'Expand editor',
    this.collapse = 'Return to editor',
  });
  final String from,
      to,
      cc,
      bcc,
      subject,
      message,
      showBcc,
      recipientPlaceholder,
      attachments,
      addAttachment,
      send,
      discard,
      expand,
      collapse;
  final String Function(String name)? removeAttachment;
}
