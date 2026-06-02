import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Result of parsing an Agora STT message.
class SttResult {
  final String? original;
  final String? translated;
  final bool isFinal;

  SttResult({this.original, this.translated, this.isFinal = false});

  @override
  String toString() =>
      'SttResult(original: $original, translated: $translated, isFinal: $isFinal)';
}

/// Helper to decode Agora STT binary (Protobuf) messages.
class AgoraSttHelper {
  // Keywords to filter out - these are message types/metadata, not actual text
  static const _keywords = {
    'transcribe',
    'translate',
    'en-US',
    'es-ES',
    'es',
    'gu-IN',
    'hi-IN',
    'fr-FR',
    'de-DE',
    'ja-JP',
    'ko-KR',
    'zh-CN',
    'ar',
    'ru-RU',
  };

  /// Decode an Agora STT message.
  static SttResult decode(Uint8List data) {
    try {
      final strings = _extractUtf8Strings(data);
      debugPrint('AgoraSttHelper: Raw strings: $strings');

      if (strings.isEmpty) return SttResult();

      // Determine message type
      final isTranslateMessage = strings.any(
        (s) => s.toLowerCase() == 'translate',
      );

      // Filter out keywords, short strings, and garbled data
      final textStrings = strings.where((s) {
        final trimmed = s.trim();
        final lower = trimmed.toLowerCase();

        // Skip keywords
        if (_keywords.contains(lower)) return false;

        // Skip very short strings
        if (trimmed.length < 2) return false;

        // Skip language codes like "en-US", "hi-IN"
        if (RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(trimmed)) return false;

        // Skip strings that are only punctuation/symbols
        if (RegExp(
          r'^[^a-zA-Z\u0900-\u097F\u0600-\u06FF\u4E00-\u9FFF]+$',
        ).hasMatch(trimmed))
          return false;

        // Skip garbled/binary data - reject if contains control characters (except space)
        if (trimmed.runes.any((r) => r < 0x20 && r != 0x20)) return false;

        // Skip if it contains replacement character (indicates bad decode)
        if (trimmed.contains('�')) return false;

        // Skip if string has too many non-letter characters (likely binary junk)
        int letterCount = trimmed.runes
            .where(
              (r) =>
                  (r >= 0x41 && r <= 0x5A) || // A-Z
                  (r >= 0x61 && r <= 0x7A) || // a-z
                  (r >= 0x0900 && r <= 0x097F) || // Devanagari
                  (r >= 0x0600 && r <= 0x06FF) || // Arabic
                  (r >= 0x4E00 && r <= 0x9FFF) || // CJK
                  (r >= 0x00C0 && r <= 0x024F), // Extended Latin
            )
            .length;
        if (letterCount < trimmed.length * 0.5) return false;

        return true;
      }).toList();

      debugPrint('AgoraSttHelper: Filtered text: $textStrings');

      if (textStrings.isEmpty) return SttResult();

      String? original;
      String? translated;

      if (isTranslateMessage && textStrings.length >= 2) {
        // For translate messages, find the two longest meaningful strings
        final sorted = List<String>.from(textStrings)
          ..sort((a, b) => b.length.compareTo(a.length));
        translated = sorted[0];
        original = sorted.length > 1 ? sorted[1] : null;
      } else {
        // For transcribe messages, only original text exists
        final sorted = List<String>.from(textStrings)
          ..sort((a, b) => b.length.compareTo(a.length));
        if (sorted.isNotEmpty) {
          original = sorted[0];
        }
      }

      return SttResult(original: original, translated: translated);
    } catch (e) {
      debugPrint('AgoraSttHelper: Error decoding: $e');
      return SttResult();
    }
  }

  /// Extract all valid UTF-8 strings from binary data.
  static List<String> _extractUtf8Strings(Uint8List data) {
    final List<String> result = [];
    int i = 0;

    while (i < data.length - 1) {
      final byte = data[i];
      final wireType = byte & 0x07;

      if (wireType == 2 && i + 1 < data.length) {
        final lengthResult = _readVarint(data, i + 1);
        if (lengthResult != null) {
          final length = lengthResult.value;
          final startOfString = lengthResult.nextIndex;
          final endOfString = startOfString + length;

          if (length > 0 && length < 500 && endOfString <= data.length) {
            try {
              final bytes = data.sublist(startOfString, endOfString);
              // Use utf8.decode for proper multi-byte character support (Hindi, etc.)
              try {
                final str = utf8.decode(bytes, allowMalformed: true).trim();
                if (str.isNotEmpty && _isPrintableString(str)) {
                  result.add(str);
                }
              } catch (_) {
                // Fallback to fromCharCodes for non-UTF8 data
                if (_isPrintableUtf8(bytes)) {
                  final str = String.fromCharCodes(bytes).trim();
                  if (str.isNotEmpty) {
                    result.add(str);
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
      i++;
    }
    return result;
  }

  static ({int value, int nextIndex})? _readVarint(Uint8List data, int start) {
    int value = 0;
    int shift = 0;
    int i = start;

    while (i < data.length) {
      final byte = data[i];
      value |= (byte & 0x7F) << shift;
      i++;
      if ((byte & 0x80) == 0) {
        return (value: value, nextIndex: i);
      }
      shift += 7;
      if (shift > 35) return null;
    }
    return null;
  }

  static bool _isPrintableUtf8(Uint8List bytes) {
    for (final b in bytes) {
      if (b < 0x20 && b != 0x09 && b != 0x0A && b != 0x0D) {
        return false;
      }
    }
    return true;
  }

  /// Check if a decoded string contains mostly printable characters
  static bool _isPrintableString(String str) {
    if (str.isEmpty) return false;
    int printableCount = 0;
    for (final rune in str.runes) {
      // Allow: printable ASCII, extended Latin, Devanagari, Arabic, CJK, etc.
      if (rune >= 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        printableCount++;
      }
    }
    // At least 80% should be printable
    return printableCount > (str.runes.length * 0.8);
  }
}
