import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledSession {
  final String id;
  final String hostId;
  final String? participantId;
  final String? participantName;
  final String? participantAvatar;
  final String hostName;
  final String hostAvatar; // URL or asset path
  final String language;
  final String level;
  final String topic;
  final DateTime scheduledTime;
  final int durationMinutes;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String channelId;

  ScheduledSession({
    required this.id,
    required this.hostId,
    this.participantId,
    this.participantName,
    this.participantAvatar,
    required this.hostName,
    required this.hostAvatar,
    required this.language,
    required this.level,
    required this.topic,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.status,
    required this.channelId,
  });

  factory ScheduledSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledSession(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      participantId: data['participantId'],
      participantName: data['participantName'],
      participantAvatar: data['participantAvatar'],
      hostName: data['hostName'] ?? 'Language Partner',
      hostAvatar: data['hostAvatar'] ?? '',
      language: data['language'] ?? 'English',
      level: data['level'] ?? 'Intermediate',
      topic: data['topic'] ?? 'General',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 30,
      status: data['status'] ?? 'scheduled',
      channelId: data['channelId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'language': language,
      'level': level,
      'topic': topic,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'durationMinutes': durationMinutes,
      'status': status,
      'channelId': channelId,
    };
  }

  bool get isPending => status == 'pending';
  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
