import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';
  
  // Find or create a chat between users for a specific ride
  Future<String> findOrCreateChat(String rideId, String otherUserId) async {
    try {
      // Check if chat already exists
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('rideId', isEqualTo: rideId)
          .where('participants', arrayContains: currentUserId)
          .get();
      
      // Look through results to find a chat with both users
      for (var doc in existingChatQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.contains(otherUserId)) {
          return doc.id; // Return existing chat ID
        }
      }
      
      // Create a new chat if none exists
      final newChatRef = await _firestore.collection('chats').add({
        'rideId': rideId,
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
      
      return newChatRef.id;
    } catch (e) {
      throw Exception('Failed to find or create chat: $e');
    }
  }
  
  // Get user details by ID
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        return {
          'id': userId,
          'name': userData['name'] ?? 'User',
          'profileImage': userData['profileImage'],
          ...userData,
        };
      }
      
      return {
        'id': userId,
        'name': 'User',
      };
    } catch (e) {
      return {
        'id': userId,
        'name': 'User',
      };
    }
  }
  
  // Get chat messages stream
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        // .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Get all chats for current user
  Stream<QuerySnapshot> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        // .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
  
  // Send a message
  Future<void> sendMessage(String chatId, String message) async {
    try {
      // Get current user name
      String senderName = 'User';
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        senderName = userData?['name'] ?? 'User';
      }
      
      // Create a transaction to ensure both operations succeed or fail together
      return _firestore.runTransaction((transaction) async {
        // Add message to the messages subcollection
        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();
            
        transaction.set(messageRef, {
          'text': message,
          'senderId': currentUserId,
          'senderName': senderName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        
        // Update the main chat document with last message info
        transaction.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }
  
  // Get ride details by ID
  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      
      if (rideDoc.exists) {
        final rideData = rideDoc.data() ?? {};
        return {
          'id': rideId,
          'from': rideData['from'] ?? '',
          'to': rideData['to'] ?? '',
          'date': rideData['date'],
          'time': rideData['time'],
          'driverId': rideData['userId'], // The ride creator is the driver
          ...rideData,
        };
      }
      
      return {
        'id': rideId,
      };
    } catch (e) {
      return {
        'id': rideId,
      };
    }
  }
  
  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      // First delete all messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Then delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}