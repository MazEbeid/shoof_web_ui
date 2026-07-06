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

// Shared dashboard data layer (Supabase/Firestore providers + models)
export 'src/data/supabase_client_provider.dart';
export 'src/data/cities_constants.dart';
export 'src/data/widget_data_providers.dart';
export 'src/data/anchor_prices_provider.dart';
export 'src/data/price_monitor_provider.dart';

// Dashboard widgets (rendered by both ShooofAdmin and shoof_insights)
export 'src/widgets/dashboard/price_widget_shell.dart';
export 'src/widgets/dashboard/price_filter_controls.dart';
export 'src/widgets/dashboard/price_sku_picker.dart';
export 'src/widgets/dashboard/price_sku_summary_cards.dart';
export 'src/widgets/dashboard/price_observations_dialog.dart';
export 'src/widgets/dashboard/price_trend_widget.dart';
export 'src/widgets/dashboard/price_vs_anchor_widget.dart';
export 'src/widgets/dashboard/price_today_widget.dart';
export 'src/widgets/dashboard/price_comparison_widget.dart';
export 'src/widgets/dashboard/price_range_widget.dart';
export 'src/widgets/dashboard/price_movers_widget.dart';
export 'src/widgets/dashboard/availability_vs_price_widget.dart';
export 'src/widgets/dashboard/availability_analysis_widget.dart';
export 'src/widgets/dashboard/coverage_map_widget.dart';
export 'src/widgets/dashboard/mission_overview_widget.dart';
export 'src/widgets/dashboard/section_widget.dart';
export 'src/widgets/dashboard/widget_filters_row.dart';
