import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Reusable avatar widget with network image caching and fallback.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isOnline;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.15),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.person_rounded,
                      size: radius,
                      color: theme.colorScheme.primary,
                    ),
                    errorWidget: (context, url, error) =>
                        _buildFallback(theme),
                  ),
                )
              : _buildFallback(theme),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback(ThemeData theme) {
    if (name != null && name!.isNotEmpty) {
      final initials = name!
          .split(' ')
          .take(2)
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
          .join();
      return Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      size: radius,
      color: theme.colorScheme.primary,
    );
  }
}
