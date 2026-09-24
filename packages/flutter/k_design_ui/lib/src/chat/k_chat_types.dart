enum KChatRole { user, assistant, system }

enum KChatRunState {
  idle,
  submitted,
  streaming,
  awaitingInput,
  stopped,
  completed,
  failed,
}

enum KAgentToolState {
  pending,
  running,
  approvalRequired,
  succeeded,
  failed,
  cancelled,
}

enum KAgentResolutionState {
  pending,
  answered,
  approved,
  rejected,
  cancelled,
  expired,
}

sealed class KChatMessagePart {
  const KChatMessagePart({required this.id});
  final String id;
}

class KChatTextPart extends KChatMessagePart {
  const KChatTextPart({
    required super.id,
    required this.text,
    this.streaming = false,
  });
  final String text;
  final bool streaming;
}

class KChatAttachmentPart extends KChatMessagePart {
  const KChatAttachmentPart({
    required super.id,
    required this.title,
    this.description,
    this.mediaType,
    this.progress,
    this.state = KChatAttachmentPartState.ready,
  });
  final String title;
  final String? description;
  final String? mediaType;
  final double? progress;
  final KChatAttachmentPartState state;
}

enum KChatAttachmentPartState { ready, uploading, processing, error, complete }

class KAgentSourcePart extends KChatMessagePart {
  const KAgentSourcePart({
    required super.id,
    required this.title,
    this.description,
    this.url,
  });
  final String title;
  final String? description;
  final Uri? url;
}

class KAgentToolPart extends KChatMessagePart {
  const KAgentToolPart({
    required super.id,
    required this.toolName,
    required this.title,
    required this.state,
    this.description,
    this.arguments,
    this.result,
    this.error,
  });
  final String toolName;
  final String title;
  final String? description;
  final KAgentToolState state;
  final Object? arguments;
  final Object? result;
  final String? error;
}

class KAgentApprovalOption {
  const KAgentApprovalOption({
    required this.id,
    required this.label,
    this.primary = false,
  });
  final String id;
  final String label;
  final bool primary;
}

class KAgentApprovalPart extends KChatMessagePart {
  const KAgentApprovalPart({
    required super.id,
    required this.title,
    required this.state,
    required this.options,
    this.description,
    this.detail,
    this.selectedOptionId,
    this.responseSummary,
  });
  final String title;
  final String? description;
  final String? detail;
  final KAgentResolutionState state;
  final List<KAgentApprovalOption> options;
  final String? selectedOptionId;
  final String? responseSummary;
}

enum KAgentQuestionKind {
  text,
  singleChoice,
  multipleChoice,
  confirmation,
  custom,
}

class KAgentQuestionOption {
  const KAgentQuestionOption({
    required this.id,
    required this.label,
    this.description,
  });
  final String id;
  final String label;
  final String? description;
}

class KAgentQuestionPart extends KChatMessagePart {
  const KAgentQuestionPart({
    required super.id,
    required this.title,
    required this.kind,
    required this.state,
    this.description,
    this.options = const [],
    this.selectedOptionIds = const [],
    this.answerSummary,
    this.placeholder,
    this.submitLabel,
  });
  final String title;
  final String? description;
  final KAgentQuestionKind kind;
  final KAgentResolutionState state;
  final List<KAgentQuestionOption> options;
  final List<String> selectedOptionIds;
  final String? answerSummary;
  final String? placeholder;
  final String? submitLabel;
}

enum KAgentTaskState { pending, active, completed, failed, skipped }

class KAgentTaskItem {
  const KAgentTaskItem({
    required this.id,
    required this.title,
    required this.state,
    this.description,
  });
  final String id;
  final String title;
  final String? description;
  final KAgentTaskState state;
}

class KAgentTaskPart extends KChatMessagePart {
  const KAgentTaskPart({
    required super.id,
    required this.title,
    required this.items,
  });
  final String title;
  final List<KAgentTaskItem> items;
}

class KAgentArtifactPart extends KChatMessagePart {
  const KAgentArtifactPart({
    required super.id,
    required this.title,
    required this.reference,
    this.description,
    this.artifactType,
  });
  final String title;
  final String? description;
  final String? artifactType;
  final String reference;
}

class KAgentActivityPart extends KChatMessagePart {
  const KAgentActivityPart({
    required super.id,
    required this.title,
    required this.summary,
    this.active = false,
  });
  final String title;
  final String summary;
  final bool active;
}

enum KAgentStatusTone { neutral, info, success, warning, error }

class KAgentStatusPart extends KChatMessagePart {
  const KAgentStatusPart({
    required super.id,
    required this.title,
    this.description,
    this.tone = KAgentStatusTone.neutral,
  });
  final String title;
  final String? description;
  final KAgentStatusTone tone;
}

class KChatMessageValue {
  const KChatMessageValue({
    required this.id,
    required this.role,
    required this.parts,
    this.authorLabel,
    this.timestamp,
    this.status,
  });
  final String id;
  final KChatRole role;
  final List<KChatMessagePart> parts;
  final String? authorLabel;
  final DateTime? timestamp;
  final KChatMessageStatus? status;
}

enum KChatMessageStatus { sending, sent, failed }

class KAgentApprovalResponse {
  const KAgentApprovalResponse({
    required this.approvalId,
    required this.optionId,
    this.reason,
  });
  final String approvalId;
  final String optionId;
  final String? reason;
}

class KAgentQuestionResponse {
  const KAgentQuestionResponse({
    required this.questionId,
    this.optionIds = const [],
    this.text,
    this.value,
  });
  final String questionId;
  final List<String> optionIds;
  final String? text;
  final Object? value;
}

abstract interface class KAgentUiAdapter<TSnapshot, TIntent> {
  List<KChatMessageValue> toMessages(TSnapshot snapshot);
  KChatRunState toRunState(TSnapshot snapshot);
  TIntent toHostIntent(KAgentUiIntent intent);
}

sealed class KAgentUiIntent {
  const KAgentUiIntent();
}

class KAgentSubmitMessageIntent extends KAgentUiIntent {
  const KAgentSubmitMessageIntent(this.text);
  final String text;
}

class KAgentStopRunIntent extends KAgentUiIntent {
  const KAgentStopRunIntent();
}

class KAgentLoadOlderIntent extends KAgentUiIntent {
  const KAgentLoadOlderIntent();
}

class KAgentActivateAttachmentIntent extends KAgentUiIntent {
  const KAgentActivateAttachmentIntent(this.partId);
  final String partId;
}

class KAgentActivateSourceIntent extends KAgentUiIntent {
  const KAgentActivateSourceIntent(this.partId);
  final String partId;
}

class KAgentActivateArtifactIntent extends KAgentUiIntent {
  const KAgentActivateArtifactIntent(this.partId);
  final String partId;
}

class KAgentApprovalIntent extends KAgentUiIntent {
  const KAgentApprovalIntent(this.response);
  final KAgentApprovalResponse response;
}

class KAgentQuestionIntent extends KAgentUiIntent {
  const KAgentQuestionIntent(this.response);
  final KAgentQuestionResponse response;
}
