import 'enums.dart';
import 'json.dart';

/// One file a mechanic uploaded during registration, as a reviewer sees it.
///
/// The mobile app owns the bytes today (they sit in the app's own documents
/// directory); the console only ever needs a reference plus enough metadata to
/// label and preview it. [uri] is deliberately opaque — a local file path
/// while the two apps are unconnected, an https URL once the backend serves
/// uploads — so neither side hard-codes an assumption about storage.
class CredentialDocument {
  final String id;

  /// The mechanic this file belongs to. Mechanics are keyed by name
  /// throughout the product, so credentials follow the same convention.
  final String ownerName;

  final CredentialKind kind;

  /// What the mechanic called it during registration ('NC II', 'Valid ID'),
  /// falling back to the file name.
  final String label;

  final String fileName;

  /// Where the file lives. Opaque to every consumer — see the class doc.
  final String uri;

  final DateTime uploadedAt;

  const CredentialDocument({
    required this.id,
    required this.ownerName,
    required this.kind,
    required this.label,
    required this.fileName,
    required this.uri,
    required this.uploadedAt,
  });

  static const Set<String> _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic',
  };

  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage => _imageExtensions.contains(extension);

  bool get isPdf => extension == 'pdf';

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerName': ownerName,
        'kind': kind.wireName,
        'label': label,
        'fileName': fileName,
        'uri': uri,
        'uploadedAt': writeDate(uploadedAt),
      };

  factory CredentialDocument.fromJson(Map<String, dynamic> json) => CredentialDocument(
        id: readString(json['id']),
        ownerName: readString(json['ownerName']),
        kind: CredentialKind.fromWire(readString(json['kind'])),
        label: readString(json['label']),
        fileName: readString(json['fileName']),
        uri: readString(json['uri']),
        uploadedAt: readDate(json['uploadedAt']),
      );
}
