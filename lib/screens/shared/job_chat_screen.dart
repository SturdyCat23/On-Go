import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/app_session.dart';
import '../../data/chat_store.dart';
import '../../theme/app_theme.dart';

class JobChatScreen extends StatefulWidget {
  final String requestId;
  final String otherPartyName;

  const JobChatScreen({super.key, required this.requestId, required this.otherPartyName});

  @override
  State<JobChatScreen> createState() => _JobChatScreenState();
}

class _JobChatScreenState extends State<JobChatScreen> {
  final _store = ChatStore.instance;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    _store.markSeen(widget.requestId, AppSession.instance.currentRole);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      _store.sendMessage(widget.requestId, text: text, replyToId: _replyingTo?.id);
      _controller.clear();
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      _store.sendMessage(widget.requestId, imagePath: file.path, replyToId: _replyingTo?.id);
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not attach photo: $e')));
    }
  }

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (msg.text != null)
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.primary),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text!));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _senderLabel(ChatMessage msg) => msg.sender == ChatSender.client ? 'Client' : widget.otherPartyName;

  @override
  Widget build(BuildContext context) {
    final messages = _store.messagesFor(widget.requestId);
    final myRole = AppSession.instance.currentRole;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(widget.otherPartyName),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('Send a message to get started', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = (myRole == AppRole.client && msg.sender == ChatSender.client) ||
                          (myRole == AppRole.mechanic && msg.sender == ChatSender.mechanic);
                      final repliedTo = msg.replyToId == null ? null : _store.messageById(widget.requestId, msg.replyToId!);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () => _showMessageOptions(msg),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (repliedTo != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                                    ),
                                    child: Text(
                                      repliedTo.text ?? (repliedTo.imagePath != null ? 'Photo' : ''),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                    ),
                                  ),
                                msg.imagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(File(msg.imagePath!), width: 180, fit: BoxFit.cover),
                                      )
                                    : Text(msg.text ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.background,
              child: Row(
                children: [
                  Container(width: 3, height: 32, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Replying to ${_senderLabel(_replyingTo!)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        Text(
                          _replyingTo!.text ?? (_replyingTo!.imagePath != null ? 'Photo' : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textGrey),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppColors.textGrey),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none, isDense: true),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}