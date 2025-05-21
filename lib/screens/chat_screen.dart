import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rydex/screens/chat_components.dart';
import 'dart:async';

import 'package:rydex/screens/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserId;
  final String otherUserName;
  final bool isDriver;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isDriver,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String _chatId = '';
  List<Map<String, dynamic>> _messages = [];
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _currentUserName = '';
  Map<String, dynamic> _rideDetails = {};
  
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;
  Timer? _otherUserTypingTimer;
  StreamSubscription? _typingSubscription;
  
  // For the enhanced UI components
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _typingTimer?.cancel();
    _otherUserTypingTimer?.cancel();
    _typingSubscription?.cancel();
    
    // Update user status when leaving chat
    _updateUserPresence(false);
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update user presence based on app state
    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached) {
      _updateUserPresence(false);
    }
  }

  // Initialize the chat data
  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's name
      final userDetails = await _chatService.getUserDetails(_currentUserId);
      _currentUserName = userDetails['name'];

      // Find or create the chat
      _chatId = await _chatService.findOrCreateChat(widget.rideId, widget.otherUserId);
      
      // Get ride details
      _rideDetails = await _chatService.getRideDetails(widget.rideId);
      
      // Mark messages as read when chat opens
      await _markMessagesAsRead();
      
      // Update user presence
      _updateUserPresence(true);
      
      // Initialize message listener
      _setupMessageListener();
      
      // Initialize typing indicator listener
      _setupTypingListener();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error initializing chat: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Set up real-time message listener
  void _setupMessageListener() {
    _chatService.getChatMessages(_chatId).listen((snapshot) {
      if (mounted) {
        setState(() {
          _messages = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          _isLoading = false;
        });
        
        // Mark messages as read when receiving new ones
        _markMessagesAsRead();
        
        // Scroll to bottom on new messages
        if (_scrollController.hasClients && _messages.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      }
    }, onError: (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading messages: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  // Set up typing indicator listener
  void _setupTypingListener() {
    _typingSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // Check if the other user is typing
        final isTyping = data['${widget.otherUserId}_typing'] == true;
        
        if (isTyping != _isOtherUserTyping) {
          setState(() {
            _isOtherUserTyping = isTyping;
          });
          
          // If other user started typing, set a timer to automatically turn it off
          // in case they don't send a message or stop typing for a while
          if (isTyping) {
            _otherUserTypingTimer?.cancel();
            _otherUserTypingTimer = Timer(const Duration(seconds: 5), () {
              if (mounted && _isOtherUserTyping) {
                setState(() {
                  _isOtherUserTyping = false;
                });
              }
            });
          }
        }
      }
    });
  }
  
  // Update typing indicator
  void _updateTypingStatus(bool isTyping) {
    try {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({
        '${_currentUserId}_typing': isTyping,
      });
    } catch (e) {
      // Silently fail for typing indicators
    }
  }
  
  // Update user presence (online/offline)
  void _updateUserPresence(bool isOnline) {
    try {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({
        '${_currentUserId}_online': isOnline,
        '${_currentUserId}_last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for presence updates
    }
  }
  
  // Mark messages as read
  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(_chatId);
    } catch (e) {
      // Silently fail for read receipts
    }
  }

  // Send a new message
  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    try {
      // Cancel typing indicator
      _updateTypingStatus(false);
      _typingTimer?.cancel();
      
      // Send the message
      await _chatService.sendMessage(_chatId, message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sending message: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }
  
  // Handle text input changes and update typing status
  void _handleTextChanged(String text) {
    // Update typing status
    if (text.isNotEmpty) {
      _updateTypingStatus(true);
      
      // Reset timer for typing status
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _updateTypingStatus(false);
      });
    } else {
      _updateTypingStatus(false);
      _typingTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                widget.otherUserName.isNotEmpty 
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isDriver ? "Driver" : "Passenger",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Ride details button
          IconButton(
            onPressed: () => _showRideDetails(context),
            icon: const Icon(Icons.info_outline),
            tooltip: "Ride Details",
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.teal.shade600),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? ChatEmptyState(
                          rideFrom: _rideDetails['from'] ?? '',
                          rideTo: _rideDetails['to'] ?? '',
                          otherUserName: widget.otherUserName,
                        )
                      : Stack(
                          children: [
                            // Messages
                            ChatMessageList(
                              messages: _messages,
                              currentUserId: _currentUserId,
                              otherUserName: widget.otherUserName,
                              scrollController: _scrollController,
                            ),
                            
                            // Typing indicator
                            if (_isOtherUserTyping)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: TypingIndicator(
                                  username: widget.otherUserName,
                                ),
                              ),
                          ],
                        ),
                ),
                
                // Message input area
                ChatInputField(
                  onSend: _sendMessage,
                  hint: "Type a message...",
                  onTextChanged: _handleTextChanged,
                ),
              ],
            ),
    );
  }
  
  // Show ride details dialog
  void _showRideDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Ride Details",
          style: TextStyle(
            color: Colors.teal.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route visualization
            Container(
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
                          _rideDetails['from'] ?? 'Starting location',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
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
                          _rideDetails['to'] ?? 'Destination',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rideDetails['date'] != null
                        ? DateFormat('EEE, MMM d, yyyy').format(
                            DateTime.parse(_rideDetails['date']),
                          )
                        : 'Date not specified',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  _rideDetails['time'] ?? 'Time not specified',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.event_seat,
                  size: 18,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  "${_rideDetails['seats_available'] ?? 0} seats available",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: Colors.teal.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// Update ChatInputField to include onTextChanged callback
class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final Function(String)? onTextChanged;
  final String hint;

  const ChatInputField({
    super.key, 
    required this.onSend,
    this.onTextChanged,
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
    
    // Notify parent about text changes
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(_controller.text);
    }
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

// Inbox screen to show all chat conversations
class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChats();
    _updateUserPresence(true);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserPresence(false);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update user presence based on app state
    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached) {
      _updateUserPresence(false);
    }
  }
  
  // Update user presence
  void _updateUserPresence(bool isOnline) {
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for presence updates
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen for chats where current user is a participant
      _chatService.getUserChats().listen((snapshot) async {
        final chats = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          
          // Get the other user's ID
          final otherUserId = participants.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );
          
          if (otherUserId.isNotEmpty) {
            // Get other user's name
            final otherUserDetails = await _chatService.getUserDetails(otherUserId);
            
            // Get ride details
            final rideDetails = await _chatService.getRideDetails(data['rideId']);
            
            // Get unread count
            final unreadCount = await _getUnreadCount(doc.id);
            
            // Check if the other user is online
            final isOnline = data['${otherUserId}_online'] == true;
            
            chats.add({
              'id': doc.id,
              'rideId': data['rideId'],
              'otherUserId': otherUserId,
              'otherUserName': otherUserDetails['name'],
              'lastMessage': data['lastMessage'],
              'lastMessageTime': data['lastMessageTime'],
              'fromLocation': rideDetails['from'] ?? '',
              'toLocation': rideDetails['to'] ?? '',
              'isDriver': rideDetails['driverId'] == _currentUserId,
              'unreadCount': unreadCount,
              'isOnline': isOnline,
            });
          }
        }
        
        if (mounted) {
          setState(() {
            _chats = chats;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error loading chats: $e"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
          
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error initializing chats: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Get unread message count
  Future<int?> _getUnreadCount(String chatId) async {
    try {
      final unreadQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      
      return unreadQuery.count;
    } catch (e) {
      return 0;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return DateFormat('E').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.teal.shade600),
            )
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 80,
                        color: Colors.teal.shade200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No messages yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your conversations will appear here",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey.shade200,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              rideId: chat['rideId'],
                              otherUserId: chat['otherUserId'],
                              otherUserName: chat['otherUserName'],
                              isDriver: chat['isDriver'],
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              chat['otherUserName'].isNotEmpty
                                  ? chat['otherUserName'][0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (chat['isOnline'])
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['otherUserName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(chat['lastMessageTime']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            chat['lastMessage'] ?? '',
                            style: TextStyle(
                              color: chat['unreadCount'] > 0
                                  ? Colors.black
                                  : Colors.grey.shade700,
                              fontWeight: chat['unreadCount'] > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 14,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${chat['fromLocation']} → ${chat['toLocation']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: chat['unreadCount'] > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade600,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                chat['unreadCount'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}

// Missing UI components that were referenced in the code

// ChatEmptyState widget for when there are no messages
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
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.teal.shade200,
            ),
            const SizedBox(height: 20),
            Text(
              "Start chatting with $otherUserName",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
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
                          rideFrom.isNotEmpty ? rideFrom : 'Starting location',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                          rideTo.isNotEmpty ? rideTo : 'Destination',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Say hello and discuss the ride details!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}