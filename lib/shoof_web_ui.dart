/// Shoof Web UI - Shared components for Shoof web applications
///
/// This package provides a consistent design system and reusable widgets
/// for ShooofAdmin and shoof_insights web applications.
library shoof_web_ui;

// Design System
export 'src/theme/admin_colors.dart';
export 'src/theme/admin_spacing.dart';
export 'src/theme/admin_radius.dart';
export 'src/theme/admin_typography.dart';
export 'src/theme/admin_shadows.dart';
export 'src/theme/admin_decorations.dart';
export 'src/theme/admin_button_styles.dart';
export 'src/theme/admin_status.dart';
export 'src/theme/admin_breakpoints.dart';
export 'src/theme/admin_durations.dart';
export 'src/theme/admin_theme.dart';

// Common Widgets
export 'src/widgets/admin_card.dart';
export 'src/widgets/admin_stat_card.dart';
export 'src/widgets/admin_date_range_picker.dart';
export 'src/widgets/admin_dialog.dart';
export 'src/widgets/admin_status_badge.dart';
export 'src/widgets/admin_action_buttons.dart';
export 'src/widgets/admin_table_cells.dart';
export 'src/widgets/admin_text_field.dart';
export 'src/widgets/admin_flushbar.dart';

// Table Widgets
export 'src/widgets/admin_data_table.dart';

// Insights Widgets (for shoof_insights)
export 'src/widgets/insights_hero_banner.dart';
export 'src/widgets/insights_health_score.dart';
export 'src/widgets/insights_story_card.dart';
export 'src/widgets/insights_mission_card.dart';

// Dashboard Models (shared between ShooAdmin and shoof_insights)
export 'src/models/dashboard_config.dart';

// Chart Components (reusable analytics charts)
export 'src/widgets/charts/charts.dart';
