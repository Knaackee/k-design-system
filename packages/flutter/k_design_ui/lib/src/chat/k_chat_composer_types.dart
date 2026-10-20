part of 'k_chat_composer.dart';

class KChatComposerModel {
  const KChatComposerModel({
    required this.value,
    required this.label,
    this.icon,
    this.disabled = false,
  });

  final String value;
  final String label;
  final KIconName? icon;
  final bool disabled;
}

class KChatComposerLabels {
  const KChatComposerLabels({
    this.input = 'Message',
    this.placeholder = 'Ask anything…',
    this.send = 'Send message',
    this.stop = 'Stop response',
    this.removeAttachment = 'Remove attachment',
    this.attach = 'Attach files',
    this.voice = 'Start voice input',
    this.stopVoice = 'Stop voice input',
    this.processingVoice = 'Transcribing voice input',
    this.unavailableVoice = 'Voice input unavailable',
    this.errorVoice = 'Retry voice input',
    this.model = 'Model',
    this.cancelVoice = 'Discard recording',
    this.sendVoice = 'Transcribe and send',
    this.call = 'Start call',
  });

  final String input;
  final String placeholder;
  final String send;
  final String stop;
  final String removeAttachment;
  final String attach;
  final String voice;
  final String stopVoice;
  final String processingVoice;
  final String unavailableVoice;
  final String errorVoice;
  final String model;
  final String cancelVoice;
  final String sendVoice;
  final String call;
}

/// Host-owned inline voice capture state for [KChatComposer].
///
/// Recording, permission, draft preservation, transcription, and sending stay
/// in the consumer. The composer only presents the supplied state and actions.
class KChatVoiceCapture {
  const KChatVoiceCapture({
    required this.samples,
    required this.onCancel,
    required this.onSend,
    this.error,
  });

  /// Normalized audio history, oldest first. Values are clamped to 0..1.
  final List<double> samples;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final String? error;
}
