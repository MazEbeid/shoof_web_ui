import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_status.dart';

/// A consistent status badge widget using the V2 design system.
class AdminStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double? fontSize;

  const AdminStatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = AdminStatus.getColor(status);
    final backgroundColor = AdminStatus.getBackgroundColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AdminRadius.xsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(status),
              size: 14,
              color: color,
            ),
            const SizedBox(width: AdminSpacing.xs),
          ],
          Text(
            _formatStatusLabel(status),
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize ?? 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'waiting':
        return Icons.schedule;
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'paid':
      case 'active':
        return Icons.check_circle;
      case 'rejected':
      case 'expired':
      case 'failed':
      case 'inactive':
        return Icons.cancel;
      case 'in_progress':
      case 'processing':
      case 'in progress':
        return Icons.sync;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatusLabel(String status) {
    // Convert snake_case to Title Case
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}

/// A smaller dot-style status indicator
class AdminStatusDot extends StatelessWidget {
  final String status;
  final double size;

  const AdminStatusDot({
    super.key,
    required this.status,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = AdminStatus.getColor(status);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A status indicator with label for table cells
class AdminStatusCell extends StatelessWidget {
  final String status;
  final String? label;

  const AdminStatusCell({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminStatusDot(status: status),
        const SizedBox(width: AdminSpacing.sm),
        Text(
          label ?? status,
          style: AdminTextStyles.tableCell,
        ),
      ],
    );
  }
}

