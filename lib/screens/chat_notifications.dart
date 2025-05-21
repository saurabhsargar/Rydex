import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rydex/screens/chat_screen.dart';

class ChatNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  List<StreamSubscription> _subscriptions = [];
  
  // Initialize notification plugin
  Future<void> initialize(BuildContext context) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          final payloadParts = payload.split(':');
          if (payloadParts.length == 3) {
            final chatId = payloadParts[0];
            final otherUserId = payloadParts[1];
            final otherUserName = payloadParts[2];
            
            // Get ride ID from chat
            _firestore.collection('chats').doc(chatId).get().then((chatDoc) {
              if (chatDoc.exists) {
                final chatData = chatDoc.data();
                final rideId = chatData?['rideId'];
                
                if (rideId != null) {
                  // Navigate to chat screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        rideId: rideId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        isDriver: false, // This will be determined in ChatScreen
                      ),
                    ),
                  );
                }
              }
            });
          }
        }
      },
    );
  }
  
  // Start listening for new messages
  void startListening() {
    // First unsubscribe from any existing subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Subscribe to chats where current user is a participant
    final chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final chatDoc = change.doc;
        final chatData = chatDoc.data();
        
        // Check if this is a new message update
        if (change.type == DocumentChangeType.modified && 
            chatData?['lastMessageTime'] != null) {
          // Get the other user's ID
          final participants = List<String>.from(chatData?['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );
          
          if (otherUserId.isNotEmpty) {
            // Check the latest message in this chat
            _checkForNewMessage(chatDoc.id, otherUserId);
          }
        }
      }
    });
    
    _subscriptions.add(chatSubscription);
  }
  
  // Check for new unread messages
  Future<void> _checkForNewMessage(String chatId, String senderId) async {
    try {
      // Get the latest message
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: senderId) // Only messages from the other user
          .where('read', isEqualTo: false) // Only unread messages
          // .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (messagesQuery.docs.isNotEmpty) {
        final messageDoc = messagesQuery.docs.first;
        final messageData = messageDoc.data();
        
        // Get sender's name
        String senderName = 'User';
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          senderName = userData?['name'] ?? 'User';
        }
        
        // Show notification
        await _showNotification(
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          message: messageData['text'] ?? 'New message',
        );
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }
  
  // Show notification for new message
  Future<void> _showNotification({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      chatId.hashCode, // Use chat ID hash as notification ID
      senderName,
      message,
      notificationDetails,
      payload: '$chatId:$senderId:$senderName',
    );
  }
  
  // Stop listening for new messages
  void stopListening() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}

// NotificationBadge widget to show unread message count
class ChatNotificationBadge extends StatefulWidget {
  const ChatNotificationBadge({
    super.key,
    this.size = 20,
    this.color = Colors.red,
    this.textColor = Colors.white,
  });

  final double size;
  final Color color;
  final Color textColor;

  @override
  State<ChatNotificationBadge> createState() => _ChatNotificationBadgeState();
}

class _ChatNotificationBadgeState extends State<ChatNotificationBadge> {
  int _unreadCount = 0;
  StreamSubscription? _subscription;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _listenForUnreadMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenForUnreadMessages() {
    _subscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) async {
      int totalUnread = 0;
      
      for (var doc in snapshot.docs) {
        final chatId = doc.id;
        
        // Count unread messages in this chat
        final unreadQuery = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isNotEqualTo: _currentUserId)
            .where('read', isEqualTo: false)
            .count()
            .get();
        
        totalUnread += unreadQuery.count!;
      }
      
      if (mounted) {
        setState(() {
          _unreadCount = totalUnread;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unreadCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
      constraints: BoxConstraints(
        minWidth: widget.size,
        minHeight: widget.size,
      ),
      child: Center(
        child: Text(
          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
          style: TextStyle(
            color: widget.textColor,
            fontSize: widget.size * 0.6,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}