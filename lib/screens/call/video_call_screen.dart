import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../models/call_models.dart';
import '../../core/theme/app_colors.dart';
import '../../services/agora_service.dart';
import '../../services/matchmaking_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

import '../../services/agora_translation_service.dart';
import '../../utils/agora_stt_helper.dart';
import '../../services/vocabulary_service.dart';
import 'widgets/call_widgets.dart';
import 'call_summary_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final SpeakerMatch partner;
  final String channelName;
  final String matchId;

  const VideoCallScreen({
    super.key,
    required this.partner,
    required this.channelName,
    required this.matchId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final AgoraTranslationService _translationService = AgoraTranslationService();
  final VocabularyService _vocabularyService = VocabularyService();
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isMicOn = true;
  bool _isVideoOn = true;
  bool _isTranslating = false;
  String? _currentUserLanguageCode; // Store mapped language code
  String _spokenText = '';
  String _translatedText = '';
  int? _remoteUid;
  bool _isJoined = false;

  // Conversation messages for summary
  final List<ConversationMessage> _conversationMessages = [];

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
    _fetchUserLanguage();
    // Short delay to avoid permission conflict with Agora (reduced from 3s to 1s)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _initTranslation();
    });
  }

  Future<void> _fetchUserLanguage() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _firestoreService.getUser(user.uid);
      if (userModel != null && userModel.selectedLanguage != null) {
        if (mounted) {
          setState(() {
            _currentUserLanguageCode =
                AgoraTranslationService.mapLanguageToCode(
                  userModel.selectedLanguage!,
                );
          });
          debugPrint(
            'User language fetched: ${userModel.selectedLanguage} -> $_currentUserLanguageCode',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _agoraService.dispose();
    _translationService.dispose();
    super.dispose();
  }

  Future<void> _initTranslation() async {
    // Set up translation callbacks
    _translationService.onTranslation = (originalText, translatedText) {
      if (mounted) {
        setState(() {
          _spokenText = originalText;
          _translatedText = translatedText;
        });
      }
    };

    _translationService.onError = (error) {
      debugPrint('Translation error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    };
  }

  bool _isTranslationLoading = false;

  void _toggleTranslation() async {
    if (_isTranslationLoading) return;
    if (!mounted) return;

    setState(() {
      _isTranslationLoading = true;
    });

    final currentUser = _authService.currentUser;
    final userId = currentUser?.uid ?? 'unknown';

    try {
      if (_isTranslating) {
        // Stop translation
        await _translationService.stopTranscription();
        debugPrint('Translation stopped');
      } else {
        // Start translation via Firebase Cloud Functions
        debugPrint('Starting translation via Cloud Functions...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting translator... please wait')),
          );
        }

        final targetLanguage = AgoraTranslationService.mapLanguageToCode(
          widget.partner.language,
        );
        // Use fetched language code as source, default to 'en-US' if not found
        final sourceLanguage = _currentUserLanguageCode ?? 'en-US';

        final success = await _translationService.startTranscription(
          channelName: widget.channelName,
          userId: userId,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );

        if (!success && mounted) {
          throw Exception('Failed to start translator');
        }
      }

      if (mounted) {
        setState(() {
          _isTranslating = !_isTranslating;
          if (!_isTranslating) {
            _spokenText = '';
            _translatedText = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling translation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranslationLoading = false;
        });
      }
    }
  }

  Future<void> _initAgora() async {
    debugPrint(
      'VideoCallScreen: Initializing Agora for channel: ${widget.channelName}',
    );

    // Set up callbacks
    _agoraService.onUserJoined = (int uid) {
      debugPrint('VideoCallScreen: Remote user joined with UID: $uid');

      // Ignore STT bot UIDs (pubBotUid: 88888, subBotUid: 99999)
      if (uid == 88888 || uid == 99999) {
        debugPrint('VideoCallScreen: Ignoring STT bot UID: $uid');
        return;
      }

      if (mounted) {
        setState(() {
          _remoteUid = uid;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partner connected!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };

    _agoraService.onUserOffline = (int uid) {
      debugPrint('VideoCallScreen: Remote user left with UID: $uid');

      // Ignore STT bot UIDs (pubBotUid: 88888, subBotUid: 99999)
      if (uid == 88888 || uid == 99999) {
        debugPrint('VideoCallScreen: Ignoring STT bot leaving UID: $uid');
        return;
      }

      if (mounted) {
        setState(() {
          _remoteUid = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner disconnected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        // Automatically end call when partner leaves
        _endCall();
      }
    };

    _agoraService.onJoinChannelSuccess = () {
      debugPrint(
        'VideoCallScreen: Successfully joined channel ${widget.channelName}',
      );
      if (mounted) {
        setState(() {
          _isJoined = true;
        });
      }
    };

    _agoraService.onLeaveChannel = () {
      debugPrint('Left channel');
    };

    _agoraService.onError = (String error) {
      debugPrint('Agora error (logged only): $error');
      // Errors are logged but not shown to user unless critical
    };

    _agoraService.onStreamMessage = (int uid, Uint8List data) {
      debugPrint(
        'VideoCallScreen: Stream Message from $uid. Length: ${data.length}',
      );

      // Use AgoraSttHelper to decode the binary Protobuf data
      final result = AgoraSttHelper.decode(data);
      debugPrint('VideoCallScreen: Decoded result: $result');

      if (result.original != null || result.translated != null) {
        if (mounted) {
          setState(() {
            if (result.original != null && result.original!.isNotEmpty) {
              _spokenText = result.original!;
            }
            if (result.translated != null && result.translated!.isNotEmpty) {
              _translatedText = result.translated!;
            }
            // Auto-show subtitles if we receive them (REMOVED to fix toggle bug)
            // if (!_isTranslating) _isTranslating = true;
          });

          // Add to conversation messages for summary (include all messages, but avoid duplicates)
          if (result.original != null && result.original!.isNotEmpty) {
            // Check if this is a duplicate of the last message
            final isDuplicate =
                _conversationMessages.isNotEmpty &&
                _conversationMessages.last.original == result.original;

            if (!isDuplicate) {
              _conversationMessages.add(
                ConversationMessage(
                  original: result.original!,
                  translated:
                      result.translated ?? '', // Empty string if no translation
                  timestamp: DateTime.now(),
                ),
              );
            }
          }

          // Save vocabulary when we have translation (meaningful word pairs)
          if (result.original != null &&
              result.original!.isNotEmpty &&
              result.translated != null &&
              result.translated!.isNotEmpty) {
            // Save words (splits and filters stop words)
            final targetLang = AgoraTranslationService.mapLanguageToCode(
              widget.partner.language,
            );
            _vocabularyService.saveWords(
              originalSentence: result.original!,
              translatedSentence: result.translated!,
              sourceLanguage: 'en-US',
              targetLanguage: targetLang,
              sessionId: widget.channelName,
            );
          }
        }
      }
    };

    // Initialize and join channel
    try {
      await _agoraService.initialize();
      await _agoraService.joinChannel(widget.channelName);
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });

      // 5 Minute Warning (300 seconds)
      if (_secondsElapsed == 300) {
        _showTimeWarning("5 minutes up! Time to switch roles.", Colors.orange);
      }

      // 10 Minute Limit (600 seconds)
      if (_secondsElapsed >= 600) {
        _timer.cancel();
        _showTimeWarning("10 minutes up! Call ending...", Colors.red);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _endCall();
        });
      }
    });
  }

  void _showTimeWarning(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  String get _formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _endCall() async {
    // End the match in Firestore
    await _matchmakingService.endMatch(widget.matchId);
    await _agoraService.leaveChannel();
    _vocabularyService.clearSessionCache();

    if (mounted) {
      // Navigate to Call Summary Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CallSummaryScreen(
            partner: widget.partner,
            matchId: widget.matchId,
            channelName: widget.channelName,
            durationSeconds: _secondsElapsed,
            messages: _conversationMessages,
          ),
        ),
      );
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
    });
    _agoraService.toggleMic(_isMicOn);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    _agoraService.toggleCamera(_isVideoOn);
  }

  /// Build the remote video view (partner's video)
  Widget _buildRemoteVideo() {
    if (_remoteUid != null && _agoraService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      // Waiting for partner
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade800, Colors.grey.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 100, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                _isJoined ? 'Waiting for partner...' : 'Connecting...',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Build the local video view (self)
  Widget _buildLocalVideo() {
    if (_agoraService.engine != null && _isVideoOn) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraService.engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return Center(
        child: Icon(
          _isVideoOn ? Icons.person : Icons.videocam_off,
          size: 40,
          color: Colors.white38,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video (partner's video)
          Positioned.fill(child: _buildRemoteVideo()),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isJoined ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isJoined ? 'Live' : 'Connecting',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 1,
                            height: 16,
                            color: Colors.white24,
                          ),
                          Text(
                            '${widget.partner.topicEmoji}${widget.partner.topic}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _formattedTime,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Self video (small, top right)
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () => _agoraService.switchCamera(),
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildLocalVideo(),
                ),
              ),
            ),
          ),

          // Bottom section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Subtitle overlay - always show when translating
                if (_isTranslating)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Speaker header
                        Text(
                          '${widget.partner.name} says:',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Original text (prominent)
                        if (_spokenText.isEmpty && _translatedText.isEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Listening...',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        if (_spokenText.isNotEmpty)
                          Text(
                            _spokenText,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        // Translated text with checkmark
                        if (_translatedText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '"$_translatedText"',
                                  style: GoogleFonts.inter(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallControlButton(
                          icon: _isMicOn ? Icons.mic : Icons.mic_off,
                          onTap: _toggleMic,
                          backgroundColor: _isMicOn
                              ? Colors.grey.shade800
                              : Colors.red.shade400,
                        ),
                        CallControlButton(
                          icon: _isVideoOn
                              ? Icons.videocam
                              : Icons.videocam_off,
                          onTap: _toggleVideo,
                          backgroundColor: _isVideoOn
                              ? Colors.grey.shade800
                              : Colors.red.shade400,
                        ),
                        CallControlButton(
                          icon: Icons.call_end,
                          onTap: _endCall,
                          backgroundColor: Colors.red,
                          size: 64,
                        ),
                        CallControlButton(
                          icon: _isTranslating
                              ? Icons.translate
                              : Icons.translate,
                          onTap: _toggleTranslation,
                          backgroundColor: _isTranslating
                              ? AppColors.primary
                              : Colors.grey.shade800,
                          child: _isTranslationLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.translate,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        CallControlButton(
                          icon: Icons.cameraswitch,
                          onTap: () => _agoraService.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
