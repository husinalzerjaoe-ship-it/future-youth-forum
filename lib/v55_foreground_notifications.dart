import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Foreground-only sound alerts. Background/terminated delivery needs FCM push.
class V55ForegroundNotificationService {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifications;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publicMessages;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversations;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _privateMessages = {};
  bool _disposed = false;

  void start() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen(_bindUser);
  }

  Future<void> _bindUser(User? user) async {
    await _cancelUserStreams();
    if (_disposed || user == null) return;
    final uid = user.uid;

    var firstNotifications = true;
    _notifications = FirebaseFirestore.instance.collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (firstNotifications) { firstNotifications = false; return; }
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            change.doc.data()?['type'] != 'message') {
          _playAlert();
          break;
        }
      }
    }, onError: (Object error) {
      // Keep the app usable if notification rules or the network are unavailable.
    });

    var firstPublic = true;
    _publicMessages = FirebaseFirestore.instance.collection('messages')
        .orderBy('createdAt', descending: true).limit(1)
        .snapshots()
        .listen((snapshot) {
      if (firstPublic) { firstPublic = false; return; }
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            change.doc.data()['senderId'] != uid) {
          _playAlert();
          break;
        }
      }
    }, onError: (Object error) {});

    _conversations = FirebaseFirestore.instance.collection('conversations')
        .where('members', arrayContains: uid).limit(50)
        .snapshots()
        .listen((snapshot) {
      for (final conversation in snapshot.docs) {
        final id = conversation.id;
        if (_privateMessages.containsKey(id)) continue;
        var firstMessageSnapshot = true;
        _privateMessages[id] = conversation.reference.collection('messages')
            .orderBy('createdAt', descending: true).limit(1)
            .snapshots()
            .listen((messages) {
          if (firstMessageSnapshot) { firstMessageSnapshot = false; return; }
          for (final change in messages.docChanges) {
            if (change.type == DocumentChangeType.added &&
                change.doc.data()['senderId'] != uid) {
              _playAlert();
              break;
            }
          }
        }, onError: (Object error) {});
      }
    }, onError: (Object error) {});
  }

  void _playAlert() {
    if (_disposed) return;
    SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _cancelUserStreams() async {
    await _notifications?.cancel();
    await _publicMessages?.cancel();
    await _conversations?.cancel();
    _notifications = null;
    _publicMessages = null;
    _conversations = null;
    final subscriptions = _privateMessages.values.toList();
    _privateMessages.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _authSubscription?.cancel();
    _authSubscription = null;
    await _cancelUserStreams();
  }
}
