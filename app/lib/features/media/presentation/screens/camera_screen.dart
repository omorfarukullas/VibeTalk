import 'package:flutter/material.dart';

/// Camera screen for capturing photos and videos in-app.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Preview',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera integration coming in Sprint 3',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                onPressed: () {
                  // TODO: Sprint 3 — Open gallery
                },
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Sprint 3 — Capture photo
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                onPressed: () {
                  // TODO: Sprint 3 — Switch camera
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
