import 'package:flutter/material.dart';

/// Full-screen media viewer for images, videos, and documents.
class MediaViewerScreen extends StatelessWidget {
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // TODO: Sprint 3 — Share media
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              // TODO: Sprint 3 — Download media
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Media Viewer',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Media ID: $mediaId',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
