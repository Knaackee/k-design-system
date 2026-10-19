import 'dart:typed_data';

enum KIntegrationAuthType { oauth, none, bearer }

class KIntegrationIconSelection {
  const KIntegrationIconSelection({
    required this.bytes,
    required this.contentType,
  });
  final Uint8List bytes;
  final String contentType;
}

class KIntegrationDraft {
  const KIntegrationDraft({
    required this.name,
    required this.description,
    required this.category,
    required this.endpoint,
    this.authType = KIntegrationAuthType.oauth,
    this.clientId = '',
    this.scopes = '',
    this.icon,
  });

  const KIntegrationDraft.empty()
    : name = '',
      description = '',
      category = '',
      endpoint = '',
      authType = KIntegrationAuthType.oauth,
      clientId = '',
      scopes = '',
      icon = null;

  final String name;
  final String description;
  final String category;
  final String endpoint;
  final KIntegrationAuthType authType;
  final String clientId;
  final String scopes;
  final KIntegrationIconSelection? icon;

  KIntegrationDraft copyWith({
    String? name,
    String? description,
    String? category,
    String? endpoint,
    KIntegrationAuthType? authType,
    String? clientId,
    String? scopes,
    KIntegrationIconSelection? icon,
  }) => KIntegrationDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    endpoint: endpoint ?? this.endpoint,
    authType: authType ?? this.authType,
    clientId: clientId ?? this.clientId,
    scopes: scopes ?? this.scopes,
    icon: icon ?? this.icon,
  );

  KIntegrationDraft normalized() => KIntegrationDraft(
    name: name.trim(),
    description: description.trim(),
    category: category.trim(),
    endpoint: endpoint.trim(),
    authType: authType,
    clientId: clientId.trim(),
    scopes: scopes.trim(),
    icon: icon,
  );
}

Map<String, String> validateKIntegrationDraft(
  KIntegrationDraft value, {
  Set<String> allowedHttpOrigins = const {},
}) {
  final draft = value.normalized();
  final errors = <String, String>{};
  if (draft.name.isEmpty) errors['name'] = 'Bitte gib einen Namen ein.';
  if (draft.description.isEmpty) {
    errors['description'] = 'Bitte gib eine Beschreibung ein.';
  }
  if (draft.category.isEmpty) {
    errors['category'] = 'Bitte gib eine Kategorie ein.';
  }
  if (draft.endpoint.isEmpty) {
    errors['endpoint'] = 'Bitte gib einen HTTPS-Endpoint ein.';
  } else {
    final uri = Uri.tryParse(draft.endpoint);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      errors['endpoint'] = 'Bitte gib eine gültige HTTPS-URL ein.';
    } else if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' && allowedHttpOrigins.contains(uri.origin))) {
      errors['endpoint'] = 'Der Endpoint muss HTTPS verwenden.';
    } else if (uri.userInfo.isNotEmpty || uri.hasFragment) {
      errors['endpoint'] =
          'Der Endpoint darf keine Zugangsdaten oder URL-Fragmente enthalten.';
    }
  }
  return errors;
}
