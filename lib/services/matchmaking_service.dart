import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/call_models.dart';

/// Model for a waiting user in the matchmaking queue
class WaitingUser {
  final String docId;
  final String oduserId;
  final String oddisplayName;
  final String odlanguage;
  final DateTime odcreatedAt;

  WaitingUser({
    required this.docId,
    required this.oduserId,
    required this.oddisplayName,
    required this.odlanguage,
    required this.odcreatedAt,
  });

  factory WaitingUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaitingUser(
      docId: doc.id,
      oduserId: data['userId'] ?? '',
      oddisplayName: data['displayName'] ?? 'User',
      odlanguage: data['language'] ?? '',
      odcreatedAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Model for a match between two users
class Match {
  final String matchId;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String user1Avatar;
  final String user2Avatar;
  final String user1Language;
  final String user2Language;
  final String channelName;
  final DateTime createdAt;
  final DateTime? endedAt;
  final String status;
  final int? rating1;
  final int? rating2;
  final String? feedback1;
  final String? feedback2;

  // Legacy/Computed fields for backward compatibility
  int? get rating {
    if (rating1 != null && rating2 != null) {
      return ((rating1! + rating2!) / 2).round();
    }
    return rating1 ?? rating2;
  }

  String? get feedback => feedback1 ?? feedback2;

  Match({
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    this.user1Avatar = '',
    this.user2Avatar = '',
    this.user1Language = '',
    this.user2Language = '',
    required this.channelName,
    required this.createdAt,
    this.endedAt,
    required this.status,
    this.rating1,
    this.rating2,
    this.feedback1,
    this.feedback2,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      matchId: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      user1Name: data['user1Name'] ?? 'User',
      user2Name: data['user2Name'] ?? 'User',
      user1Avatar: data['user1Avatar'] as String? ?? '',
      user2Avatar: data['user2Avatar'] as String? ?? '',
      user1Language: data['user1Language'] as String? ?? '',
      user2Language: data['user2Language'] as String? ?? '',
      channelName: data['channelName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'unknown',
      rating1:
          data['rating1'] as int? ?? data['rating'] as int?, // Backward compat
      rating2: data['rating2'] as int?,
      feedback1: data['feedback1'] as String? ?? data['feedback'] as String?,
      feedback2: data['feedback2'] as String?,
    );
  }

  // ... rest of class remains same

  // Duration in seconds (for exact time)
  int get durationSeconds {
    if (endedAt == null) return 0;
    return endedAt!.difference(createdAt).inSeconds;
  }

  // Duration in minutes (rounded up)
  int get durationMinutes {
    if (endedAt == null) return 0;
    final diff = endedAt!.difference(createdAt);
    if (diff.inSeconds > 0 && diff.inMinutes == 0) return 1;
    return diff.inMinutes;
  }

  // Formatted duration like "2m 30s" or "45s"
  String get formattedDuration {
    final totalSeconds = durationSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Helper to get partner name for a specific user ID
  String getPartnerName(String myUserId) {
    return myUserId == user1Id ? user2Name : user1Name;
  }

  // Helper to get partner avatar URL for a specific user ID
  String getPartnerAvatar(String myUserId) {
    return myUserId == user1Id ? user2Avatar : user1Avatar;
  }

  // Helper to get partner language for a specific user ID
  String getPartnerLanguage(String myUserId) {
    return myUserId == user1Id ? user2Language : user1Language;
  }
}

/// Service for matching users for video calls
class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _waitingUsersRef =>
      _firestore.collection('waiting_users');
  CollectionReference get _matchesRef => _firestore.collection('matches');

  StreamSubscription? _matchSubscription;
  String? _currentWaitingDocId;

  /// Find a match or create a waiting entry
  Future<MatchResult> findOrCreateMatch({
    required String userId,
    required String displayName,
    required String language,
    String? avatarUrl,
  }) async {
    debugPrint('MatchmakingService: Finding match for user $userId');

    // Clean up any old entries from this user first
    await _cleanupOldEntries(userId);

    // Check if there's a waiting user (not ourselves)
    final waitingSnapshot = await _waitingUsersRef
        .orderBy('createdAt')
        .limit(10)
        .get();

    // Find first user that isn't us
    DocumentSnapshot? waitingUserDoc;
    for (var doc in waitingSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        waitingUserDoc = doc;
        break;
      }
    }

    if (waitingUserDoc != null) {
      // Found a waiting user - create a match!
      final data = waitingUserDoc.data() as Map<String, dynamic>;
      final waitingUserId = data['userId'] as String;
      final waitingDisplayName = data['displayName'] as String? ?? 'User';
      final waitingLanguage = data['language'] as String? ?? '';

      final waitingAvatarUrl = data['avatarUrl'] as String? ?? '';

      debugPrint('MatchmakingService: Found waiting user $waitingUserId');

      // Generate unique channel name
      final channelName = _generateChannelName(userId, waitingUserId);

      // Create the match document
      final matchDoc = await _matchesRef.add({
        'user1Id': waitingUserId, // The waiting user
        'user2Id': userId, // The joining user
        'user1Name': waitingDisplayName,
        'user2Name': displayName,
        'user1Avatar': waitingAvatarUrl,
        'user2Avatar': avatarUrl ?? '',
        'user1Language': waitingLanguage,
        'user2Language': language,
        'channelName': channelName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Remove the waiting user from queue
      await _waitingUsersRef.doc(waitingUserDoc.id).delete();

      debugPrint('MatchmakingService: Match created with channel $channelName');

      return MatchResult(
        isMatched: true,
        channelName: channelName,
        matchId: matchDoc.id,
        partner: SpeakerMatch(
          id: waitingUserId,
          name: waitingDisplayName,
          avatarUrl: waitingAvatarUrl,
          language: waitingLanguage,
          languageFlag: '🌐',
          level: 'Intermediate',
          topic: 'General',
          topicEmoji: '💬',
        ),
      );
    } else {
      // No one waiting - add ourselves to the queue
      debugPrint('MatchmakingService: No waiting users, adding to queue');

      final docRef = await _waitingUsersRef.add({
        'userId': userId,
        'displayName': displayName,
        'language': language,
        'avatarUrl': avatarUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentWaitingDocId = docRef.id;

      return MatchResult(isMatched: false, waitingDocId: docRef.id);
    }
  }

  /// Listen for when someone matches with us
  Stream<MatchResult> listenForMatch(String userId) {
    debugPrint('MatchmakingService: Listening for match for user $userId');

    // Simple query - just listen for matches where we are user1
    return _matchesRef.where('user1Id', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'active') {
          final channelName = data['channelName'] as String?;
          final partnerName = data['user2Name'] as String? ?? 'Partner';
          final partnerId = data['user2Id'] as String? ?? '';

          final partnerAvatar = data['user2Avatar'] as String? ?? '';

          debugPrint('MatchmakingService: Match found! Channel: $channelName');

          return MatchResult(
            isMatched: true,
            channelName: channelName,
            matchId: doc.id,
            partner: SpeakerMatch(
              id: partnerId,
              name: partnerName,
              avatarUrl: partnerAvatar,
              language: 'Unknown',
              languageFlag: '🌐',
              level: 'Intermediate',
              topic: 'General',
              topicEmoji: '💬',
            ),
          );
        }
      }
      return MatchResult(isMatched: false);
    });
  }

  /// Clean up old entries from this user
  Future<void> _cleanupOldEntries(String userId) async {
    try {
      // Remove from waiting queue
      final oldWaiting = await _waitingUsersRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in oldWaiting.docs) {
        await doc.reference.delete();
      }

      // End old active matches
      final oldMatches1 = await _matchesRef
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      for (var doc in oldMatches1.docs) {
        await doc.reference.update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }

      final oldMatches2 = await _matchesRef
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      for (var doc in oldMatches2.docs) {
        await doc.reference.update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('MatchmakingService: Error cleaning up: $e');
    }
  }

  /// Leave the waiting queue
  Future<void> leaveQueue() async {
    if (_currentWaitingDocId != null) {
      debugPrint('MatchmakingService: Leaving queue');
      try {
        await _waitingUsersRef.doc(_currentWaitingDocId).delete();
      } catch (e) {
        debugPrint('MatchmakingService: Error leaving queue: $e');
      }
      _currentWaitingDocId = null;
    }
    _matchSubscription?.cancel();
    _matchSubscription = null;
  }

  /// End a match
  Future<void> endMatch(String matchId) async {
    debugPrint('MatchmakingService: Ending match $matchId');
    try {
      await _matchesRef.doc(matchId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('MatchmakingService: Error ending match: $e');
    }
  }

  /// Update rating for a match
  Future<void> updateRating(
    String matchId,
    String userId,
    int rating,
    String? feedback,
  ) async {
    debugPrint('MatchmakingService: Updating rating for $matchId by $userId');
    try {
      final docSnapshot = await _matchesRef.doc(matchId).get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data() as Map<String, dynamic>;
      final user1Id = data['user1Id'] as String?;

      final updates = <String, dynamic>{};

      if (userId == user1Id) {
        updates['rating1'] = rating;
        updates['feedback1'] = feedback;
      } else {
        updates['rating2'] = rating;
        updates['feedback2'] = feedback;
      }

      await _matchesRef.doc(matchId).update(updates);
    } catch (e) {
      debugPrint('MatchmakingService: Error updating rating: $e');
    }
  }

  /// Generate a unique channel name from two user IDs
  String _generateChannelName(String userId1, String userId2) {
    // Use unique channel for every match (safe with App ID only)
    return 'match_${DateTime.now().millisecondsSinceEpoch}_${userId1.substring(0, 4)}';
  }
}

// Better yet, let's just make it simple.
// We will fetch history by reading ONCE for "Your Circle" (future) or use a helper that combines.
// Since we don't have RxDart easily, I'll add a method that returns a Future for history to simplify UI logic.
extension MatchmakingExtensions on MatchmakingService {
  /// Stream of all ended matches for a user (real-time)
  Stream<List<Match>> getAllMatchesStream(String userId) {
    final stream1 = _matchesRef
        .where('user1Id', isEqualTo: userId)
        .snapshots();

    // Combine both streams
    return stream1.asyncMap((snapshot1) async {
      final snapshot2 = await _matchesRef
          .where('user2Id', isEqualTo: userId)
          .get();

      final all = [
        ...snapshot1.docs,
        ...snapshot2.docs,
      ].map((d) => Match.fromFirestore(d)).toList();

      // Deduplicate by matchId
      final seen = <String>{};
      final unique = all.where((m) => seen.add(m.matchId)).toList();

      final endedMatches = unique.where((m) => m.status == 'ended').toList();
      endedMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return endedMatches;
    });
  }

  Future<List<Match>> getAllMatchesFuture(String userId) async {
    // Reading without composite query to avoid manual index creation
    final q1 = await _matchesRef.where('user1Id', isEqualTo: userId).get();

    final q2 = await _matchesRef.where('user2Id', isEqualTo: userId).get();

    final all = [
      ...q1.docs,
      ...q2.docs,
    ].map((d) => Match.fromFirestore(d)).toList();

    // Client-side Filter & Sort
    final endedMatches = all.where((m) => m.status == 'ended').toList();
    endedMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return endedMatches;
  }
}

/// Result of a matchmaking attempt
class MatchResult {
  final bool isMatched;
  final String? channelName;
  final String? matchId;
  final String? waitingDocId;
  final SpeakerMatch? partner;

  MatchResult({
    required this.isMatched,
    this.channelName,
    this.matchId,
    this.waitingDocId,
    this.partner,
  });
}
