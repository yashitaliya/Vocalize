import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Configuration for Agora
class AgoraConfig {
  static const String appId = String.fromEnvironment('AGORA_APP_ID');
  static const String token = String.fromEnvironment('AGORA_TOKEN');
}

/// Service to handle Agora video calls
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Callbacks
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserOffline;
  Function()? onJoinChannelSuccess;
  Function()? onLeaveChannel;
  Function(String error)? onError;
  Function(int uid, Uint8List data)? onStreamMessage;

  /// Check if engine is initialized
  bool get isInitialized => _isInitialized;

  /// Get the RTC engine
  RtcEngine? get engine => _engine;

  /// Request camera and microphone permissions
  Future<bool> requestPermissions() async {
    debugPrint('AgoraService: Requesting permissions...');
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();

    debugPrint(
      'AgoraService: Camera: ${camera.isGranted}, Mic: ${microphone.isGranted}',
    );
    return camera.isGranted && microphone.isGranted;
  }

  /// Initialize the Agora engine
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('AgoraService: Already initialized');
      return;
    }

    debugPrint('AgoraService: Initializing engine...');

    // Request permissions
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      throw Exception('Camera and microphone permissions are required');
    }

    // Create Agora engine
    if (AgoraConfig.appId.isEmpty) {
      throw Exception(
        'Agora App ID is missing. Run with --dart-define=AGORA_APP_ID=your_app_id',
      );
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Set up event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('AgoraService: ✅ JOINED channel ${connection.channelId} (elapsed: ${elapsed}ms)');
          onJoinChannelSuccess?.call();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('AgoraService: ✅ Remote user $remoteUid JOINED');
          onUserJoined?.call(remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint('AgoraService: ❌ Remote user $remoteUid LEFT (reason: $reason)');
              onUserOffline?.call(remoteUid);
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('AgoraService: Left channel');
          onLeaveChannel?.call();
        },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              debugPrint('AgoraService: 🔄 Connection state: $state, reason: $reason');
            },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('AgoraService: ⚠️ Token will expire soon!');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('AgoraService: ⚠️ ERROR: $err - $msg');
          onError?.call('$err: $msg');
        },
        onStreamMessage:
            (
              RtcConnection connection,
              int remoteUid,
              int streamId,
              Uint8List data,
              int length,
              int sentTs,
            ) {
              debugPrint('AgoraService: Stream message from $remoteUid');
              onStreamMessage?.call(remoteUid, data);
            },
      ),
    );

    // Enable video and audio
    await _engine!.enableVideo();
    debugPrint('AgoraService: Video enabled');
    await _engine!.enableAudio();
    debugPrint('AgoraService: Audio enabled');
    await _engine!.startPreview();
    debugPrint('AgoraService: Preview started');

    _isInitialized = true;
    debugPrint('AgoraService: Initialization complete');
  }

  /// Join a video call channel
  Future<void> joinChannel(String channelName, {int uid = 0}) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('AgoraService: =========================================');
    debugPrint('AgoraService: Joining channel: $channelName');
    debugPrint('AgoraService: UID: $uid (0 means auto-assign)');
    debugPrint('AgoraService: =========================================');

    try {
      debugPrint('AgoraService: 🔄 Calling joinChannel NOW...');
      await _engine!.joinChannel(
        token: AgoraConfig.token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      debugPrint('AgoraService: ✅ joinChannel call returned successfully');
    } catch (e) {
      debugPrint('AgoraService: ❌ joinChannel EXCEPTION: $e');
      rethrow;
    }
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    debugPrint('AgoraService: Leaving channel');
    await _engine?.leaveChannel();
  }

  /// Toggle local audio (mute/unmute)
  Future<void> toggleMic(bool enabled) async {
    debugPrint('AgoraService: Mic enabled: $enabled');
    await _engine?.muteLocalAudioStream(!enabled);
  }

  /// Toggle local video (on/off)
  Future<void> toggleCamera(bool enabled) async {
    debugPrint('AgoraService: Camera enabled: $enabled');
    await _engine?.muteLocalVideoStream(!enabled);
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    debugPrint('AgoraService: Switching camera...');
    try {
      await _engine?.switchCamera();
      debugPrint('AgoraService: Camera switch command sent');
    } catch (e) {
      debugPrint('AgoraService: Error switching camera: $e');
    }
  }

  /// Dispose the engine
  Future<void> dispose() async {
    debugPrint('AgoraService: Disposing engine');
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }

  /// Check if an error is critical and should be shown to user
  bool _isCriticalError(ErrorCodeType err) {
    // List of critical errors that should be shown to user
    const criticalErrors = [
      ErrorCodeType.errFailed,
      ErrorCodeType.errInvalidToken,
      ErrorCodeType.errTokenExpired,
      ErrorCodeType.errNotInitialized,
      ErrorCodeType.errConnectionLost,
    ];
    return criticalErrors.contains(err);
  }
}
