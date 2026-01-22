import 'package:flutter/material.dart';
import 'admin_colors.dart';

/// Status color helper for Shoof web applications.
class AdminStatus {
  AdminStatus._();

  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'waiting':
        return AdminColors.warning;
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'paid':
      case 'active':
        return AdminColors.success;
      case 'rejected':
      case 'expired':
      case 'failed':
      case 'inactive':
        return AdminColors.error;
      case 'in_progress':
      case 'processing':
      case 'in progress':
        return AdminColors.info;
      default:
        return AdminColors.textMuted;
    }
  }

  static Color getBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'waiting':
        return AdminColors.warningLight;
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'paid':
      case 'active':
        return AdminColors.successLight;
      case 'rejected':
      case 'expired':
      case 'failed':
      case 'inactive':
        return AdminColors.errorLight;
      case 'in_progress':
      case 'processing':
      case 'in progress':
        return AdminColors.infoLight;
      default:
        return AdminColors.backgroundHover;
    }
  }
}

