import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Theme extension for additional custom colors and styles
/// used across VibeTalk that don't fit into the base ThemeData.
class VibeTalkThemeExtension extends ThemeExtension<VibeTalkThemeExtension> {
  final Color chatBubbleSent;
  final Color chatBubbleReceived;
  final Color onlineIndicator;
  final Color callAccept;
  final Color callDecline;
  final Color unreadBadge;

  const VibeTalkThemeExtension({
    required this.chatBubbleSent,
    required this.chatBubbleReceived,
    required this.onlineIndicator,
    required this.callAccept,
    required this.callDecline,
    required this.unreadBadge,
  });

  /// Light theme extension values.
  static const light = VibeTalkThemeExtension(
    chatBubbleSent: Color(0xFF6C63FF),
    chatBubbleReceived: Color(0xFFF0F0F5),
    onlineIndicator: Color(0xFF4CAF50),
    callAccept: Color(0xFF4CAF50),
    callDecline: Color(0xFFF44336),
    unreadBadge: Color(0xFF6C63FF),
  );

  /// Dark theme extension values.
  static const dark = VibeTalkThemeExtension(
    chatBubbleSent: Color(0xFF6C63FF),
    chatBubbleReceived: Color(0xFF2A2A3C),
    onlineIndicator: Color(0xFF4CAF50),
    callAccept: Color(0xFF4CAF50),
    callDecline: Color(0xFFF44336),
    unreadBadge: Color(0xFF8B83FF),
  );

  @override
  VibeTalkThemeExtension copyWith({
    Color? chatBubbleSent,
    Color? chatBubbleReceived,
    Color? onlineIndicator,
    Color? callAccept,
    Color? callDecline,
    Color? unreadBadge,
  }) {
    return VibeTalkThemeExtension(
      chatBubbleSent: chatBubbleSent ?? this.chatBubbleSent,
      chatBubbleReceived: chatBubbleReceived ?? this.chatBubbleReceived,
      onlineIndicator: onlineIndicator ?? this.onlineIndicator,
      callAccept: callAccept ?? this.callAccept,
      callDecline: callDecline ?? this.callDecline,
      unreadBadge: unreadBadge ?? this.unreadBadge,
    );
  }

  @override
  VibeTalkThemeExtension lerp(covariant ThemeExtension<VibeTalkThemeExtension>? other, double t) {
    if (other is! VibeTalkThemeExtension) return this;
    return VibeTalkThemeExtension(
      chatBubbleSent: Color.lerp(chatBubbleSent, other.chatBubbleSent, t)!,
      chatBubbleReceived: Color.lerp(chatBubbleReceived, other.chatBubbleReceived, t)!,
      onlineIndicator: Color.lerp(onlineIndicator, other.onlineIndicator, t)!,
      callAccept: Color.lerp(callAccept, other.callAccept, t)!,
      callDecline: Color.lerp(callDecline, other.callDecline, t)!,
      unreadBadge: Color.lerp(unreadBadge, other.unreadBadge, t)!,
    );
  }
}
