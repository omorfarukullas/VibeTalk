/// Input validation utilities for forms throughout the app.
class Validators {
  Validators._();

  /// Validates a phone number (E.164 format: +<country_code><number>).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates OTP input (exactly 6 digits).
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  /// Validates a user display name.
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validates a user bio (optional but length-limited).
  static String? bio(String? value) {
    if (value != null && value.length > 200) {
      return 'Bio must be less than 200 characters';
    }
    return null;
  }

  /// Validates a group name.
  static String? groupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }
    if (value.trim().length < 2) {
      return 'Group name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Group name must be less than 100 characters';
    }
    return null;
  }

  /// Validates message content.
  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.length > 4096) {
      return 'Message is too long (max 4096 characters)';
    }
    return null;
  }

  /// Validates a URL string.
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a valid URL';
    }
    return null;
  }

  /// Validates file size against maximum allowed.
  static String? fileSize(int bytes, {int maxBytes = 50 * 1024 * 1024}) {
    if (bytes <= 0) {
      return 'Invalid file';
    }
    if (bytes > maxBytes) {
      final maxMB = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'File size exceeds ${maxMB}MB limit';
    }
    return null;
  }
}
