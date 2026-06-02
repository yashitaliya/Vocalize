import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_models.dart';
import 'notification_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get _sessionsRef =>
      _firestore.collection('scheduled_sessions');

  /// Get stream of upcoming sessions for a user
  Stream<List<ScheduledSession>> getMySessions(String userId) {
    // Query where user is host OR participant
    // Note: Firestore OR queries require composite indexes or multiple queries.
    // For simplicity, we'll stream all active sessions and filter client-side,
    // or use client-side merge if scale allows.
    // A better approach for scale: store 'participants' array field and use array-contains.

    // We'll assume the user is stored in 'participants' array for query efficiency
    // But adhering to the simple model:
    // Simplified query to avoid index requirement (status + orderBy)
    return _sessionsRef.where('status', isEqualTo: 'scheduled').snapshots().map(
      (snapshot) {
        final sessions = snapshot.docs
            .map((doc) => ScheduledSession.fromFirestore(doc))
            .where(
              (session) =>
                  session.hostId == userId || session.participantId == userId,
            )
            .toList();

        // Client-side sort
        sessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

        return sessions;
      },
    );
  }

  /// Book a new session
  Future<void> bookSession({
    required String hostId,
    required String hostName,
    required String language,
    required String topic,
    required DateTime scheduledTime,
  }) async {
    await _sessionsRef.add({
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': 'https://i.pravatar.cc/150?u=$hostId', // Placeholder
      'language': language,
      'level': 'Intermediate', // Default or fetch from profile
      'topic': topic,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'durationMinutes': 30,
      'status': 'scheduled',
      'channelId': 'session_${DateTime.now().millisecondsSinceEpoch}',
      'participants': [hostId], // For potential future queries
    });
  }

  /// Get pending requests for a user
  Stream<List<ScheduledSession>> getPendingRequests(String userId) {
    // Simplified query to avoid index requirement (status + participantId)
    // We stream all 'pending' and filter locally
    return _sessionsRef.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final sessions = snapshot.docs
          .map((doc) => ScheduledSession.fromFirestore(doc))
          .where(
            (session) => session.participantId == userId,
          ) // Requests FOR me
          .toList();

      sessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return sessions;
    });
  }

  /// Get outgoing pending requests for a user
  Stream<List<ScheduledSession>> getOutgoingRequests(String userId) {
    return _sessionsRef.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final sessions = snapshot.docs
          .map((doc) => ScheduledSession.fromFirestore(doc))
          .where((session) => session.hostId == userId) // Requests BY me
          .toList();

      sessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return sessions;
    });
  }

  /// Send a session request to another user
  Future<void> sendRequest({
    required String hostId,
    required String hostName,
    required String hostAvatar,
    required String participantId,
    required String participantName,
    required String participantAvatar,
    required String language,
    required String level,
    required String topic,
    required DateTime scheduledTime,
  }) async {
    await _sessionsRef.add({
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'language': language,
      'level': level,
      'topic': topic,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'durationMinutes': 30,
      'status': 'pending',
      'channelId': 'request_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  /// Cancel a pending request
  Future<void> cancelRequest(String sessionId) async {
    await _sessionsRef.doc(sessionId).delete();
  }

  /// Accept a request and schedule reminder notification
  Future<void> acceptRequest(
    String sessionId, {
    String? partnerName,
    DateTime? scheduledTime,
    String? participantName,
    String? participantAvatar,
  }) async {
    final Map<String, dynamic> updates = {'status': 'scheduled'};
    if (participantName != null) updates['participantName'] = participantName;
    if (participantAvatar != null) updates['participantAvatar'] = participantAvatar;

    await _sessionsRef.doc(sessionId).update(updates);
    
    // Schedule reminder notification if details provided
    if (partnerName != null && scheduledTime != null) {
      await _notificationService.scheduleSessionReminder(
        sessionId: sessionId,
        partnerName: partnerName,
        scheduledTime: scheduledTime,
        minutesBefore: 15,
      );
    }
  }

  /// Get past/history sessions for a user
  Stream<List<ScheduledSession>> getSessionHistory(String userId) {
    // Return all sessions that are NOT 'scheduled' or 'pending' (i.e. completed/cancelled)
    // Or just all sessions and we filter in UI.
    // For simplicity, let's fetch 'completed'.
    return _sessionsRef.where('status', isEqualTo: 'completed').snapshots().map(
      (snapshot) {
        final sessions = snapshot.docs
            .map((doc) => ScheduledSession.fromFirestore(doc))
            .where(
              (session) =>
                  session.hostId == userId || session.participantId == userId,
            )
            .toList();

        // Sort new to old
        sessions.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
        return sessions;
      },
    );
  }

  /// Decline a request
  Future<void> declineRequest(String sessionId) async {
    await _sessionsRef.doc(sessionId).delete();
  }
}
