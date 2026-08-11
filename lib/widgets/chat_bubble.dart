import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;
    final textColor = isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message.content!, style: TextStyle(color: textColor)),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.createdAt),
              style: TextStyle(fontSize: 10, color: textColor?.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
