import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// What a stored file is, which decides who may see it.
///
/// [mechanicId] is the identity document the mechanic uploads to prove who
/// they are. It is deliberately NEVER shown on a profile — only the people
/// reviewing the account (moderator, admin) ever see it. The other two kinds
/// are the mechanic's credentials and are public on their profile.
enum CredentialKind { mechanicId, document, certification }

extension CredentialKindLabel on CredentialKind {
  String get label {
    switch (this) {
      case CredentialKind.mechanicId:
        return 'Mechanic ID';
      case CredentialKind.document:
        return 'Documents';
      case CredentialKind.certification:
        return 'Certifications';
    }
  }
}

/// One uploaded file, owned by exactly one mechanic.
class MechanicCredential {
  final String id;

  /// The mechanic this file belongs to. Mechanics are keyed by name
  /// throughout the app (ReviewStore, QuoteNotificationStore), so credentials
  /// follow the same convention and stay findable from the client's profile
  /// view, which only ever has a name to go on.
  final String mechanicName;

  final CredentialKind kind;

  /// What the mechanic called it during registration ('NC II', 'Valid ID') —
  /// falls back to the file name for extra certificates.
  final String label;

  final String fileName;

  /// Absolute path to the app's own copy of the file. See
  /// [MechanicCredentialStore.saveForMechanic] for why it is a copy.
  final String path;

  final DateTime uploadedAt;

  const MechanicCredential({
    required this.id,
    required this.mechanicName,
    required this.kind,
    required this.label,
    required this.fileName,
    required this.path,
    required this.uploadedAt,
  });

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'};

  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage => _imageExtensions.contains(extension);
  bool get isPdf => extension == 'pdf';

  /// False once the underlying file has been moved or deleted from disk.
  bool get fileExists => File(path).existsSync();
}

/// Singleton store for the files a mechanic uploads during registration.
///
/// The picked file lives wherever the file picker staged it — usually a cache
/// directory the OS is free to clear. [saveForMechanic] therefore COPIES each
/// file into the app's own documents directory, under a folder per mechanic,
/// and records the copy's path. That is what makes an upload survive the
/// picker's cache being cleaned and keeps every file attributable to one
/// account.
///
/// The index itself is in memory, like every other store in this app; the
/// files on disk outlive the process.
class MechanicCredentialStore extends ChangeNotifier {
  MechanicCredentialStore._internal();
  static final MechanicCredentialStore instance = MechanicCredentialStore._internal();

  static const String _folderName = 'mechanic_credentials';

  final List<MechanicCredential> _all = [];

  /// Everything on file for a mechanic, ID included. For review screens only.
  List<MechanicCredential> forMechanic(String mechanicName) =>
      _all.where((c) => c.mechanicName == mechanicName).toList();

  List<MechanicCredential> ofKind(String mechanicName, CredentialKind kind) =>
      _all.where((c) => c.mechanicName == mechanicName && c.kind == kind).toList();

  /// What a profile may show: documents and certifications, never the ID.
  List<MechanicCredential> publicFor(String mechanicName) => _all
      .where((c) => c.mechanicName == mechanicName && c.kind != CredentialKind.mechanicId)
      .toList();

  bool hasCredentials(String mechanicName) => forMechanic(mechanicName).isNotEmpty;

  /// Files the registration flow collected, copied into app storage and
  /// attached to [mechanicName]. Call it before clearing the draft — the
  /// draft holds the only reference to the picked paths.
  ///
  /// A file that cannot be copied (no app documents directory on this
  /// platform, source already gone) is still recorded, pointing at the
  /// original path: a credential that might go stale beats losing the
  /// mechanic's upload outright.
  Future<void> saveForMechanic({
    required String mechanicName,
    String? mechanicIdPath,
    List<({String label, String path})> documents = const [],
    List<String> certificationPaths = const [],
  }) async {
    final destination = await _folderFor(mechanicName);

    if (mechanicIdPath != null && mechanicIdPath.isNotEmpty) {
      await _store(mechanicName, CredentialKind.mechanicId, 'Valid ID', mechanicIdPath, destination);
    }
    for (final doc in documents) {
      if (doc.path.isEmpty) continue;
      await _store(mechanicName, CredentialKind.document, doc.label, doc.path, destination);
    }
    for (final path in certificationPaths) {
      if (path.isEmpty) continue;
      await _store(mechanicName, CredentialKind.certification, _baseName(path), path, destination);
    }

    notifyListeners();
  }

  Future<Directory?> _folderFor(String mechanicName) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/$_folderName/${_slug(mechanicName)}');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      return folder;
    } catch (_) {
      // No documents directory (tests, unsupported platform) — fall back to
      // referencing the picked file where it already is.
      return null;
    }
  }

  Future<void> _store(
    String mechanicName,
    CredentialKind kind,
    String label,
    String sourcePath,
    Directory? destination,
  ) async {
    final fileName = _baseName(sourcePath);
    var storedPath = sourcePath;

    if (destination != null) {
      try {
        final source = File(sourcePath);
        if (source.existsSync()) {
          // Prefix with the timestamp so two uploads of "id.jpg" cannot
          // overwrite each other.
          final target = '${destination.path}/${DateTime.now().microsecondsSinceEpoch}_$fileName';
          await source.copy(target);
          storedPath = target;
        }
      } catch (_) {
        // Keep the source path; the credential is still recorded.
      }
    }

    _all.add(MechanicCredential(
      id: 'cred_${DateTime.now().microsecondsSinceEpoch}_${_all.length}',
      mechanicName: mechanicName,
      kind: kind,
      label: label,
      fileName: fileName,
      path: storedPath,
      uploadedAt: DateTime.now(),
    ));
  }

  static String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

  static String _slug(String value) {
    final cleaned = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned.isEmpty ? 'mechanic' : cleaned;
  }

  /// Test/demo hook — drops the index. Files already written stay on disk.
  void clear() {
    _all.clear();
    notifyListeners();
  }
}
