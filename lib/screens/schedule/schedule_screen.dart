import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../services/matchmaking_service.dart';
import '../../models/schedule_models.dart';
import '../../models/call_models.dart';
import '../../services/firestore_service.dart';
import '../call/video_call_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final AuthService _authService = AuthService();

  late Stream<List<ScheduledSession>> _sessionsStream;
  late Stream<List<ScheduledSession>> _pendingRequestsStream;
  late Stream<List<ScheduledSession>> _outgoingRequestsStream;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    final user = _authService.currentUser;
    if (user != null) {
      _sessionsStream = _scheduleService.getMySessions(user.uid);
      _pendingRequestsStream = _scheduleService.getPendingRequests(user.uid);
      _outgoingRequestsStream = _scheduleService.getOutgoingRequests(user.uid);
    } else {
      _sessionsStream = Stream.value([]);
      _pendingRequestsStream = Stream.value([]);
      _outgoingRequestsStream = Stream.value([]);
    }
  }

  void _showBookSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookSessionSheet(
        scheduleService: _scheduleService,
        authService: _authService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: _showBookSessionSheet,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pending Request Card (Stream)
              StreamBuilder<List<ScheduledSession>>(
                stream: _pendingRequestsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final requests = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: requests
                          .map(
                            (req) => _PendingRequestCard(
                              session: req,
                              onAccept: () {
                                final user = _authService.currentUser;
                                _scheduleService.acceptRequest(
                                  req.id,
                                  partnerName: req.hostName,
                                  scheduledTime: req.scheduledTime,
                                  participantName: user?.displayName ?? 'User',
                                  participantAvatar: user?.photoURL ?? '',
                                );
                              },
                              onDecline: () =>
                                  _scheduleService.declineRequest(req.id),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),

              // 1.5 Outgoing Requests (Sent by me)
              StreamBuilder<List<ScheduledSession>>(
                stream: _outgoingRequestsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final requests = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Sent Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        ...requests.map(
                          (req) => _PendingRequestCard(
                            session: req,
                            isOutgoing: true,
                            onCancel: () =>
                                _scheduleService.cancelRequest(req.id),
                            onAccept: () {}, // Not used for outgoing
                            onDecline: () {}, // Not used for outgoing
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. Calendar
              // 2. Calendar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    markerDecoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Upcoming Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Sessions List (Filtered)
              StreamBuilder<List<ScheduledSession>>(
                stream: _sessionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final allSessions = snapshot.data ?? [];
                  // Filter by selected day
                  final sessions = allSessions.where((s) {
                    if (_selectedDay == null) return true;
                    return isSameDay(s.scheduledTime, _selectedDay);
                  }).toList();

                  if (sessions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No sessions for this day.\nTap "+" to book.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final currentUserId = _authService.currentUser?.uid ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: () {
                          final isHost = session.hostId == currentUserId;
                          final partnerName = isHost
                              ? (session.participantName ?? 'Partner')
                              : session.hostName;
                          final partnerAvatar = isHost
                              ? (session.participantAvatar ??
                                  'https://i.pravatar.cc/150?u=${session.participantId}')
                              : session.hostAvatar;

                          return _ScheduleCard(
                            session: session,
                            currentUserId: currentUserId,
                            time: DateFormat(
                              'hh:mm a',
                            ).format(session.scheduledTime),
                            name: partnerName,
                            imageUrl: partnerAvatar.isNotEmpty
                                ? partnerAvatar
                                : 'https://i.pravatar.cc/150?u=${isHost ? session.participantId : session.hostId}',
                            language: session.language,
                            level: session.level,
                            tag: session.topic,
                            flag: _getLanguageFlag(session.language),
                            dayLabel: DateFormat(
                              'E',
                            ).format(session.scheduledTime).toUpperCase(),
                            date: DateFormat('d').format(session.scheduledTime),
                            month: DateFormat(
                              'MMM',
                            ).format(session.scheduledTime).toUpperCase(),
                          );
                        }(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get flag emoji for a given language name
  String _getLanguageFlag(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return '🇪🇸';
      case 'french':
        return '🇫🇷';
      case 'german':
        return '🇩🇪';
      case 'italian':
        return '🇮🇹';
      case 'portuguese':
        return '🇵🇹';
      case 'japanese':
        return '🇯🇵';
      case 'chinese':
        return '🇨🇳';
      case 'korean':
        return '🇰🇷';
      case 'arabic':
        return '🇸🇦';
      case 'hindi':
        return '🇮🇳';
      case 'russian':
        return '🇷🇺';
      case 'dutch':
        return '🇳🇱';
      case 'turkish':
        return '🇹🇷';
      default:
        return '🌐';
    }
  }
}

class _BookSessionSheet extends StatefulWidget {
  final ScheduleService scheduleService;
  final AuthService authService;

  const _BookSessionSheet({
    required this.scheduleService,
    required this.authService,
  });

  @override
  State<_BookSessionSheet> createState() => _BookSessionSheetState();
}

class _BookSessionSheetState extends State<_BookSessionSheet> {
  final MatchmakingService _matchmakingService = MatchmakingService();

  Future<List<Match>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    final user = widget.authService.currentUser;
    if (user != null) {
      _historyFuture = _matchmakingService.getAllMatchesFuture(user.uid);
    }
  }

  Future<void> _reconnect(
    BuildContext context,
    String partnerId,
    String partnerName,
    String partnerAvatar,
    String language,
    String topic,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 14, minute: 0),
      );

      if (time != null && context.mounted) {
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final user = widget.authService.currentUser;
        if (user != null) {
          // Fetch the latest user profile to ensure avatar is up to date
          final firestoreService = FirestoreService();
          final userData = await firestoreService.getUser(user.uid);
          final hostAvatar = userData?.avatarUrl ?? user.photoURL ?? '';
          
          // Calculate user's level based on test results
          final sessionLanguage = language.isNotEmpty
              ? language
              : (userData?.selectedLanguage ?? 'Language');
          final level = await _calculateUserLevel(user.uid, sessionLanguage);

          // Send request
          await widget.scheduleService.sendRequest(
            hostId: user.uid,
            hostName: userData?.fullName ?? user.displayName ?? 'User',
            hostAvatar: hostAvatar,
            participantId: partnerId,
            participantName: partnerName,
            participantAvatar: partnerAvatar,
            language: sessionLanguage,
            level: level,
            topic: topic.isNotEmpty ? topic : 'Conversation',
            scheduledTime: scheduledTime,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Request sent!')));
          }
        }
      }
    }
  }

  /// Calculate user's level for a specific language based on test results
  Future<String> _calculateUserLevel(String userId, String language) async {
    try {
      final testResults = await FirestoreService().getUserTestResults(userId);
      
      // Count passed levels for this language
      int passedCount = 0;
      for (final result in testResults) {
        if (result.testId.contains(language.toLowerCase()) && result.percentage >= 80) {
          passedCount++;
        }
      }
      
      if (passedCount >= 8) return 'Expert';
      if (passedCount >= 4) return 'Intermediate';
      return 'Beginner';
    } catch (e) {
      return 'Beginner';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Book a Session',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reconnect with past partners or find new ones.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          const Text(
            'Reconnect with...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: FutureBuilder<List<Match>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final matches = snapshot.data ?? [];

                if (matches.isEmpty) {
                  return Center(
                    child: Text(
                      'No past sessions yet.',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  );
                }

                // Dedup partners logic: Keep most recent match per partner
                final user = widget.authService.currentUser;
                final myId = user?.uid ?? '';
                final Map<String, Match> uniquePartnerMatches = {};

                for (var match in matches) {
                  final partnerId = match.user1Id == myId
                      ? match.user2Id
                      : match.user1Id;
                  if (partnerId.isNotEmpty &&
                      !uniquePartnerMatches.containsKey(partnerId)) {
                    uniquePartnerMatches[partnerId] = match;
                  }
                }

                final uniqueMatches = uniquePartnerMatches.values.toList();

                // Map to displayable items
                return ListView.separated(
                  itemCount: uniqueMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final match = uniqueMatches[index];
                    final partnerName = match.getPartnerName(myId);
                    final partnerId = match.user1Id == myId
                        ? match.user2Id
                        : match.user1Id;

                    // Get partner's actual avatar and language from Match model
                    final avatarUrl = match.getPartnerAvatar(myId);
                    final language = match.getPartnerLanguage(myId);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        partnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Last call: ${DateFormat('MMM d').format(match.createdAt)}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _reconnect(
                          context,
                          partnerId,
                          partnerName,
                          avatarUrl,
                          language.isNotEmpty ? language : 'Language',
                          'Conversation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Reconnect'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final ScheduledSession session;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onCancel;
  final bool isOutgoing;

  const _PendingRequestCard({
    required this.session,
    required this.onAccept,
    required this.onDecline,
    this.onCancel,
    this.isOutgoing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOutgoing ? Icons.outbox : Icons.inbox,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOutgoing ? 'Request Sent' : 'New Request',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: session.hostAvatar.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          session.hostAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isOutgoing
                          ? 'Waiting for ${session.hostName} to accept...'
                          : 'Wants to practice ${session.language}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat(
                  'EEE, MMM d • hh:mm a',
                ).format(session.scheduledTime),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                '${session.durationMinutes} min',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: isOutgoing
                    ? OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel Request'),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4A00E0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onDecline,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduledSession session;
  final String currentUserId;
  final String time;
  final String name;
  final String imageUrl;
  final String language;
  final String level;
  final String tag;
  final String flag;
  final String dayLabel;
  final String date;
  final String month;

  const _ScheduleCard({
    required this.session,
    required this.currentUserId,
    required this.time,
    required this.name,
    required this.imageUrl,
    required this.language,
    required this.level,
    required this.tag,
    required this.flag,
    required this.dayLabel,
    required this.date,
    required this.month,
  });

  bool get _isTimeToJoin {
    final now = DateTime.now();
    final sessionTime = session.scheduledTime;
    // Allow joining 5 minutes before and up to 30 minutes after scheduled time
    final joinWindowStart = sessionTime.subtract(const Duration(minutes: 5));
    final joinWindowEnd = sessionTime.add(const Duration(minutes: 30));
    return now.isAfter(joinWindowStart) && now.isBefore(joinWindowEnd);
  }

  String get _timeUntilSession {
    final now = DateTime.now();
    final diff = session.scheduledTime.difference(now);
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  void _joinSession(BuildContext context) {
    // Determine partner info based on current user
    final isHost = session.hostId == currentUserId;
    final partnerId = isHost ? session.participantId : session.hostId;
    final partnerName = isHost
        ? (session.participantName ?? 'Partner')
        : session.hostName;
    final partnerAvatar = isHost
        ? (session.participantAvatar ??
            'https://i.pravatar.cc/150?u=$partnerId')
        : session.hostAvatar;

    // Create SpeakerMatch for the partner
    final partner = SpeakerMatch(
      id: partnerId ?? '',
      name: partnerName,
      language: session.language,
      languageFlag: _getLanguageFlag(session.language),
      level: session.level,
      topic: session.topic,
      topicEmoji: '💬',
      avatarUrl: partnerAvatar,
    );

    // Navigate to video call with the scheduled channel
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          partner: partner,
          channelName: session.channelId,
          matchId: session.id,
        ),
      ),
    );
  }

  String _getLanguageFlag(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return '🇪🇸';
      case 'french':
        return '🇫🇷';
      case 'german':
        return '🇩🇪';
      case 'italian':
        return '🇮🇹';
      case 'portuguese':
        return '🇵🇹';
      case 'japanese':
        return '🇯🇵';
      case 'chinese':
        return '🇨🇳';
      case 'korean':
        return '🇰🇷';
      case 'arabic':
        return '🇸🇦';
      case 'hindi':
        return '🇮🇳';
      case 'russian':
        return '🇷🇺';
      case 'dutch':
        return '🇳🇱';
      case 'turkish':
        return '🇹🇷';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Column
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 50),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$flag $language • $level',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.local_offer,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Join Button with Lock
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTimeToJoin ? () => _joinSession(context) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTimeToJoin 
                                  ? AppColors.primary 
                                  : Colors.grey.shade300,
                              foregroundColor: _isTimeToJoin 
                                  ? Colors.white 
                                  : Colors.grey.shade600,
                              disabledBackgroundColor: Colors.grey.shade200,
                              disabledForegroundColor: Colors.grey.shade500,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              _isTimeToJoin ? Icons.video_call : Icons.lock_outline,
                              size: 20,
                            ),
                            label: Text(
                              _isTimeToJoin ? 'Join Now' : 'Starts in $_timeUntilSession',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
