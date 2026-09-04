import 'package:flutter/foundation.dart';
import 'app_session.dart';

enum ChatSender { client, mechanic }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String? text;
  final String? imagePath;
  final DateTime sentAt;
  final String? replyToId;

  ChatMessage({
    required this.id,
    required this.sender,
    this.text,
    this.imagePath,
    required this.sentAt,
    this.replyToId,
  });
}

/// Singleton in-memory store for job-scoped chat between a client and their
/// mechanic. Messages are keyed by requestId and are ephemeral — cleared by
/// QuoteNotificationStore the moment a job's payment completes (or a
/// mechanic cancels it), so the conversation genuinely disappears once the
/// job is done rather than lingering as unreachable dead data.
class ChatStore extends ChangeNotifier {
  ChatStore._internal();
  static final ChatStore instance = ChatStore._internal();

  final Map<String, List<ChatMessage>> _messages = {};

  /// requestId -> { role: last time that role opened this conversation }
  final Map<String, Map<AppRole, DateTime>> _lastSeen = {};

  List<ChatMessage> messagesFor(String requestId) => List.unmodifiable(_messages[requestId] ?? const []);

  ChatMessage? messageById(String requestId, String messageId) {
    final list = _messages[requestId];
    if (list == null) return null;
    final match = list.where((m) => m.id == messageId);
    return match.isEmpty ? null : match.first;
  }

  /// Sends as whichever role the active shell currently is. Throws if
  /// called from neither client nor mechanic.
  void sendMessage(String requestId, {String? text, String? imagePath, String? replyToId}) {
    final role = AppSession.instance.currentRole;
    final ChatSender sender;
    if (role == AppRole.client) {
      sender = ChatSender.client;
    } else if (role == AppRole.mechanic) {
      sender = ChatSender.mechanic;
    } else {
      throw StateError('Only the Client or Mechanic UI can send job chat messages.');
    }

    final list = _messages.putIfAbsent(requestId, () => []);
    list.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_${list.length}',
      sender: sender,
      text: text,
      imagePath: imagePath,
      sentAt: DateTime.now(),
      replyToId: replyToId,
    ));
    // Sending counts as having seen your own conversation up to now.
    _lastSeen.putIfAbsent(requestId, () => {})[role] = DateTime.now();
    notifyListeners();
  }

  /// Number of messages from the OTHER party sent after [forRole] last
  /// opened this conversation.
  int unreadCountFor(String requestId, AppRole forRole) {
    if (forRole != AppRole.client && forRole != AppRole.mechanic) return 0;
    final messages = _messages[requestId];
    if (messages == null || messages.isEmpty) return 0;

    final theirSender = forRole == AppRole.client ? ChatSender.mechanic : ChatSender.client;
    final lastSeen = _lastSeen[requestId]?[forRole];

    return messages.where((m) => m.sender == theirSender && (lastSeen == null || m.sentAt.isAfter(lastSeen))).length;
  }

  /// Call the moment a conversation is opened by [forRole], or whenever a
  /// new message might have just arrived while it's already open.
  ///
  /// CRITICAL: only notifies listeners when there was actually something
  /// unread to clear. Without this guard, a screen that listens to this
  /// store AND calls markSeen from its own change-listener (as
  /// JobChatScreen does, to clear the badge the instant a new message
  /// arrives) creates an infinite synchronous loop — notify triggers the
  /// listener, which calls markSeen, which notifies again, forever — and
  /// freezes/crashes the app. Making this a true no-op once nothing is
  /// unread breaks that loop.
  void markSeen(String requestId, AppRole forRole) {
    if (forRole != AppRole.client && forRole != AppRole.mechanic) return;
    if (unreadCountFor(requestId, forRole) == 0) return;
    _lastSeen.putIfAbsent(requestId, () => {})[forRole] = DateTime.now();
    notifyListeners();
  }

  void clearChat(String requestId) {
    final removed = _messages.remove(requestId) != null;
    _lastSeen.remove(requestId);
    if (removed) notifyListeners();
  }
}