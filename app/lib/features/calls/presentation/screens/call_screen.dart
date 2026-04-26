import 'package:flutter/material.dart';

/// Active call screen with WebRTC controls.
class CallScreen extends StatelessWidget {
  final String callId;

  const CallScreen({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121220),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Caller info
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Calling...',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Call ID: $callId',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            // Call controls
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: Icons.mic_off_rounded,
                    label: 'Mute',
                    onPressed: () {
                      // TODO: Sprint 3 — Toggle mute
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: Colors.red,
                    size: 64,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.volume_up_rounded,
                    label: 'Speaker',
                    onPressed: () {
                      // TODO: Sprint 3 — Toggle speaker
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white24,
    double size = 56,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
