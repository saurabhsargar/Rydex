import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Message bubble component
class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final String otherUserName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.otherUserName,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return DateFormat('E, HH:mm').format(date);
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade100,
              child: Text(
                message['senderName'] != null && 
                message['senderName'].toString().isNotEmpty
                    ? message['senderName'][0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.teal.shade500
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message['timestamp']),
                        style: TextStyle(
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['read'] == true
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message['read'] == true
                              ? Colors.blue.shade100
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade700,
              child: Text(
                message['senderName'] != null && 
                message['senderName'].toString().isNotEmpty
                    ? message['senderName'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhanced chat input field
class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final String hint;

  const ChatInputField({
    super.key, 
    required this.onSend,
    this.hint = "Type a message...",
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSubmitted() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    
    widget.onSend(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _handleSubmitted(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _isComposing 
                        ? Colors.teal.shade600 
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isComposing ? _handleSubmitted : null,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                    tooltip: "Send message",
                    disabledColor: Colors.grey.shade400,
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}

// Date divider for grouping messages by date
class DateDivider extends StatelessWidget {
  final DateTime date;
  
  const DateDivider({
    super.key,
    required this.date,
  });
  
  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name (e.g., "Monday")
    } else {
      return DateFormat('MMM d, yyyy').format(date); // e.g., "May 21, 2025"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Typing indicator
class TypingIndicator extends StatelessWidget {
  final String username;
  
  const TypingIndicator({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal.shade100,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(0),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  "$username is typing",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    ...List.generate(3, (index) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Chat empty state
class ChatEmptyState extends StatelessWidget {
  final String rideFrom;
  final String rideTo;
  final String otherUserName;
  
  const ChatEmptyState({
    super.key,
    required this.rideFrom,
    required this.rideTo,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.teal.shade200,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            "Start chatting with $otherUserName",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.green.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rideFrom,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 7),
                  width: 2,
                  height: 25,
                  color: Colors.grey.shade300,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rideTo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 16),
          Text(
            "Discuss pickup details, timing, or\nany other information about the ride.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }
}

// Chat message list with grouping by date
class ChatMessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final String currentUserId;
  final String otherUserName;
  final ScrollController scrollController;
  
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.otherUserName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Group messages by date
    final groupedMessages = <String, List<Map<String, dynamic>>>{};
    
    for (var message in messages) {
      final timestamp = message['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        
        if (!groupedMessages.containsKey(dateKey)) {
          groupedMessages[dateKey] = [];
        }
        
        groupedMessages[dateKey]!.add(message);
      }
    }
    
    // Sort dates
    final sortedDates = groupedMessages.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending
    
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final messagesForDate = groupedMessages[dateKey] ?? [];
        final date = DateTime.parse(dateKey);
        
        return Column(
          children: [
            DateDivider(date: date),
            ...messagesForDate.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              final isCurrentUser = message['senderId'] == currentUserId;
              
              return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                otherUserName: otherUserName,
              ).animate().fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: index * 50),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}