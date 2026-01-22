/// Dashboard Configuration Models
///
/// Shared between ShooAdmin (builder) and Shoof Insights (renderer)
/// These models define the structure of dynamic dashboards stored in Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// WIDGET TYPES
// =============================================================================

/// Supported widget types for dashboards
enum WidgetType {
  counter,
  pie,
  bar,
  line,
  table,
  heatmap,
}

extension WidgetTypeExtension on WidgetType {
  String get value {
    switch (this) {
      case WidgetType.counter:
        return 'counter';
      case WidgetType.pie:
        return 'pie';
      case WidgetType.bar:
        return 'bar';
      case WidgetType.line:
        return 'line';
      case WidgetType.table:
        return 'table';
      case WidgetType.heatmap:
        return 'heatmap';
    }
  }

  String get label {
    switch (this) {
      case WidgetType.counter:
        return 'Counter';
      case WidgetType.pie:
        return 'Pie Chart';
      case WidgetType.bar:
        return 'Bar Chart';
      case WidgetType.line:
        return 'Line Chart';
      case WidgetType.table:
        return 'Data Table';
      case WidgetType.heatmap:
        return 'Heatmap';
    }
  }

  String get icon {
    switch (this) {
      case WidgetType.counter:
        return 'numbers';
      case WidgetType.pie:
        return 'pie_chart';
      case WidgetType.bar:
        return 'bar_chart';
      case WidgetType.line:
        return 'show_chart';
      case WidgetType.table:
        return 'table_chart';
      case WidgetType.heatmap:
        return 'grid_on';
    }
  }

  static WidgetType fromString(String value) {
    return WidgetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WidgetType.counter,
    );
  }
}

// =============================================================================
// AGGREGATION TYPES
// =============================================================================

/// Aggregation functions for data queries
enum AggregationType {
  count,
  sum,
  avg,
  min,
  max,
}

extension AggregationTypeExtension on AggregationType {
  String get value {
    switch (this) {
      case AggregationType.count:
        return 'count';
      case AggregationType.sum:
        return 'sum';
      case AggregationType.avg:
        return 'avg';
      case AggregationType.min:
        return 'min';
      case AggregationType.max:
        return 'max';
    }
  }

  String get label {
    switch (this) {
      case AggregationType.count:
        return 'Count';
      case AggregationType.sum:
        return 'Sum';
      case AggregationType.avg:
        return 'Average';
      case AggregationType.min:
        return 'Minimum';
      case AggregationType.max:
        return 'Maximum';
    }
  }

  static AggregationType fromString(String value) {
    return AggregationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AggregationType.count,
    );
  }
}

// =============================================================================
// DATA SOURCE TYPES
// =============================================================================

/// Available Supabase views/tables for data queries
/// Available Supabase data sources for widgets
/// These map directly to existing tables/views in Supabase
enum DataSourceView {
  // ============ RAW DATA ============
  /// Raw submission data - main table with all input types
  submissionAnswers,

  // ============ PRICE & AVAILABILITY ============
  /// Individual price/availability observations per SKU
  priceObservations,

  /// Daily aggregated prices with day-over-day change
  dailyPrices,

  /// Weekly aggregated prices with week-over-week change
  weeklyPrices,

  /// Monthly aggregated prices with month-over-month change
  monthlyPrices,

  /// Day-of-week price patterns and volatility
  dayPatterns,

  /// Significant price changes (>5% increase/decrease)
  priceAlerts,

  // ============ MISSION OVERVIEW ============
  /// Mission-level submission counts and coverage
  missionOverview,

  /// Daily submission counts for trend charts
  missionDailyStats,

  /// Submissions grouped by city
  missionCityStats,

  /// Submissions grouped by location type
  missionLocationTypeStats,

  // ============ AGGREGATES ============
  /// High-level KPI summary per client
  kpiSummary,

  /// Statistics grouped by input type
  inputTypeStats,

  // ============ OTHER INPUT TYPES ============
  /// Yes/No question responses
  yesNoResponses,

  /// Checklist/multi-select responses
  checklistResponses,

  /// Geographic/location data
  locationData,
}

extension DataSourceViewExtension on DataSourceView {
  /// The actual Supabase table/view name
  String get value {
    switch (this) {
      case DataSourceView.submissionAnswers:
        return 'submission_answers';
      case DataSourceView.priceObservations:
        return 'v_price_observations';
      case DataSourceView.dailyPrices:
        return 'v_daily_prices';
      case DataSourceView.weeklyPrices:
        return 'v_weekly_prices';
      case DataSourceView.monthlyPrices:
        return 'v_monthly_prices';
      case DataSourceView.dayPatterns:
        return 'v_day_patterns';
      case DataSourceView.priceAlerts:
        return 'v_price_alerts';
      case DataSourceView.missionOverview:
        return 'v_mission_overview';
      case DataSourceView.missionDailyStats:
        return 'v_mission_daily_stats';
      case DataSourceView.missionCityStats:
        return 'v_mission_city_stats';
      case DataSourceView.missionLocationTypeStats:
        return 'v_mission_location_type_stats';
      case DataSourceView.kpiSummary:
        return 'v_kpi_summary';
      case DataSourceView.inputTypeStats:
        return 'v_input_type_stats';
      case DataSourceView.yesNoResponses:
        return 'v_yes_no_responses';
      case DataSourceView.checklistResponses:
        return 'v_checklist_responses';
      case DataSourceView.locationData:
        return 'v_location_data';
    }
  }

  /// Human-readable label for the UI
  String get label {
    switch (this) {
      case DataSourceView.submissionAnswers:
        return 'Raw Answers';
      case DataSourceView.priceObservations:
        return 'Price Observations';
      case DataSourceView.dailyPrices:
        return 'Daily Prices';
      case DataSourceView.weeklyPrices:
        return 'Weekly Prices';
      case DataSourceView.monthlyPrices:
        return 'Monthly Prices';
      case DataSourceView.dayPatterns:
        return 'Day Patterns';
      case DataSourceView.priceAlerts:
        return 'Price Alerts';
      case DataSourceView.missionOverview:
        return 'Mission Overview';
      case DataSourceView.missionDailyStats:
        return 'Daily Submissions';
      case DataSourceView.missionCityStats:
        return 'Submissions by City';
      case DataSourceView.missionLocationTypeStats:
        return 'Submissions by Location Type';
      case DataSourceView.kpiSummary:
        return 'KPI Summary';
      case DataSourceView.inputTypeStats:
        return 'Input Type Stats';
      case DataSourceView.yesNoResponses:
        return 'Yes/No Responses';
      case DataSourceView.checklistResponses:
        return 'Checklist Responses';
      case DataSourceView.locationData:
        return 'Location Data';
    }
  }

  /// Brief description of what this data source contains
  String get description {
    switch (this) {
      case DataSourceView.submissionAnswers:
        return 'Raw submission data with all fields';
      case DataSourceView.priceObservations:
        return 'Per-SKU price & availability';
      case DataSourceView.dailyPrices:
        return 'Daily avg/min/max with DoD change';
      case DataSourceView.weeklyPrices:
        return 'Weekly aggregates with WoW change';
      case DataSourceView.monthlyPrices:
        return 'Monthly aggregates with MoM change';
      case DataSourceView.dayPatterns:
        return 'Day-of-week patterns & volatility';
      case DataSourceView.priceAlerts:
        return 'Price changes >5%';
      case DataSourceView.missionOverview:
        return 'Total submissions, coverage, date range';
      case DataSourceView.missionDailyStats:
        return 'Submissions per day for trends';
      case DataSourceView.missionCityStats:
        return 'Submissions grouped by city';
      case DataSourceView.missionLocationTypeStats:
        return 'Submissions by channel/location type';
      case DataSourceView.kpiSummary:
        return 'High-level KPIs per client';
      case DataSourceView.inputTypeStats:
        return 'Answer counts by input type';
      case DataSourceView.yesNoResponses:
        return 'Yes/No question responses';
      case DataSourceView.checklistResponses:
        return 'Multi-select checklist responses';
      case DataSourceView.locationData:
        return 'GPS & location data';
    }
  }

  /// Category for grouping in UI
  String get category {
    switch (this) {
      case DataSourceView.submissionAnswers:
        return 'Raw Data';
      case DataSourceView.priceObservations:
      case DataSourceView.dailyPrices:
      case DataSourceView.weeklyPrices:
      case DataSourceView.monthlyPrices:
      case DataSourceView.dayPatterns:
      case DataSourceView.priceAlerts:
        return 'Price & Availability';
      case DataSourceView.missionOverview:
      case DataSourceView.missionDailyStats:
      case DataSourceView.missionCityStats:
      case DataSourceView.missionLocationTypeStats:
        return 'Mission Stats';
      case DataSourceView.kpiSummary:
      case DataSourceView.inputTypeStats:
        return 'Aggregates';
      case DataSourceView.yesNoResponses:
      case DataSourceView.checklistResponses:
      case DataSourceView.locationData:
        return 'Other Input Types';
    }
  }

  /// Common fields available in this data source (based on actual schema)
  List<String> get availableFields {
    switch (this) {
      case DataSourceView.submissionAnswers:
        return [
          'client_id',
          'mission_id',
          'submission_id',
          'input_type',
          'question',
          'node',
          'value_text',
          'value_number',
          'value_bool',
          'city',
          'channel',
          'location_name',
          'observed_date',
          'crowd_id',
          'qa_status',
        ];
      case DataSourceView.priceObservations:
        return [
          'client_id',
          'mission_id',
          'product_name_ar',
          'product_name',
          'brand_owner',
          'brand_name',
          'size',
          'packaging',
          'price',
          'is_available',
          'city',
          'channel',
          'location_name',
          'observed_date',
        ];
      case DataSourceView.dailyPrices:
        return [
          'client_id',
          'mission_id',
          'product_name_ar',
          'brand_owner',
          'size',
          'packaging',
          'city',
          'channel',
          'observed_date',
          'avg_price',
          'min_price',
          'max_price',
          'available_count',
          'total_observations',
          'availability_pct',
          'dod_change',
          'dod_pct',
        ];
      case DataSourceView.weeklyPrices:
        return [
          'client_id',
          'product_name_ar',
          'brand_owner',
          'size',
          'city',
          'year',
          'week_number',
          'week_start',
          'avg_price',
          'observations',
          'availability_pct',
          'wow_pct',
        ];
      case DataSourceView.monthlyPrices:
        return [
          'client_id',
          'product_name_ar',
          'brand_owner',
          'size',
          'city',
          'year',
          'month',
          'month_name',
          'avg_price',
          'observations',
          'availability_pct',
          'mom_pct',
        ];
      case DataSourceView.dayPatterns:
        return [
          'client_id',
          'product_name_ar',
          'brand_owner',
          'day_of_week',
          'day_name',
          'avg_price',
          'price_volatility',
          'availability_pct',
          'observations',
        ];
      case DataSourceView.priceAlerts:
        return [
          'client_id',
          'mission_id',
          'product_name_ar',
          'brand_owner',
          'city',
          'channel',
          'observed_date',
          'avg_price',
          'dod_change',
          'dod_pct',
          'alert_type',
        ];
      case DataSourceView.missionOverview:
        return [
          'client_id',
          'mission_id',
          'total_submissions',
          'total_answers',
          'cities_count',
          'location_types_count',
          'locations_count',
          'collectors_count',
          'first_submission',
          'last_submission',
          'days_active',
        ];
      case DataSourceView.missionDailyStats:
        return [
          'client_id',
          'mission_id',
          'observed_date',
          'submissions',
          'answers',
          'cities',
          'collectors',
        ];
      case DataSourceView.missionCityStats:
        return [
          'client_id',
          'mission_id',
          'city',
          'submissions',
          'answers',
          'locations',
          'collectors',
          'first_date',
          'last_date',
        ];
      case DataSourceView.missionLocationTypeStats:
        return [
          'client_id',
          'mission_id',
          'location_type',
          'submissions',
          'answers',
          'cities',
          'locations',
          'collectors',
        ];
      case DataSourceView.kpiSummary:
        return [
          'client_id',
          'first_observation',
          'last_observation',
          'days_tracked',
          'total_observations',
          'missions_count',
          'products_tracked',
          'cities_covered',
          'locations_visited',
          'overall_availability_pct',
          'overall_avg_price',
        ];
      case DataSourceView.inputTypeStats:
        return [
          'client_id',
          'input_type',
          'count',
          'first_seen',
          'last_seen',
        ];
      case DataSourceView.yesNoResponses:
        return [
          'client_id',
          'mission_id',
          'question',
          'node',
          'city',
          'channel',
          'location_name',
          'observed_date',
          'response',
        ];
      case DataSourceView.checklistResponses:
        return [
          'client_id',
          'mission_id',
          'question',
          'node',
          'city',
          'channel',
          'observed_date',
          'selected_option',
        ];
      case DataSourceView.locationData:
        return [
          'client_id',
          'mission_id',
          'city',
          'region',
          'channel',
          'location_name',
          'lat',
          'lng',
          'what3words',
          'observed_date',
        ];
    }
  }

  static DataSourceView fromString(String value) {
    return DataSourceView.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DataSourceView.submissionAnswers,
    );
  }
}

// =============================================================================
// FILTER CONFIG
// =============================================================================

/// A single filter condition for data queries
class FilterConfig {
  final String field;
  final String operator; // '=', '!=', '>', '>=', '<', '<=', 'in', 'like'
  final dynamic value; // Can be string, number, bool, or {{variable}}

  const FilterConfig({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toMap() => {
        'field': field,
        'operator': operator,
        'value': value,
      };

  factory FilterConfig.fromMap(Map<String, dynamic> map) => FilterConfig(
        field: map['field'] ?? '',
        operator: map['operator'] ?? '=',
        value: map['value'],
      );

  FilterConfig copyWith({
    String? field,
    String? operator,
    dynamic value,
  }) =>
      FilterConfig(
        field: field ?? this.field,
        operator: operator ?? this.operator,
        value: value ?? this.value,
      );
}

// =============================================================================
// DATA SOURCE CONFIG
// =============================================================================

/// Configuration for how a widget fetches its data
class DataSourceConfig {
  final String type; // 'supabase' or 'firestore'
  final String view; // Table or view name
  final String? valueField; // Field to aggregate
  final String aggregation; // count, sum, avg, min, max
  final String? groupBy; // Field to group by (for charts)
  final String? orderBy; // e.g., "count DESC"
  final int? limit;
  final List<FilterConfig> filters;

  const DataSourceConfig({
    this.type = 'supabase',
    required this.view,
    this.valueField,
    this.aggregation = 'count',
    this.groupBy,
    this.orderBy,
    this.limit,
    this.filters = const [],
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'view': view,
        if (valueField != null) 'valueField': valueField,
        'aggregation': aggregation,
        if (groupBy != null) 'groupBy': groupBy,
        if (orderBy != null) 'orderBy': orderBy,
        if (limit != null) 'limit': limit,
        'filters': filters.map((f) => f.toMap()).toList(),
      };

  factory DataSourceConfig.fromMap(Map<String, dynamic> map) =>
      DataSourceConfig(
        type: map['type'] ?? 'supabase',
        view: map['view'] ?? 'submission_answers',
        valueField: map['valueField'],
        aggregation: map['aggregation'] ?? 'count',
        groupBy: map['groupBy'],
        orderBy: map['orderBy'],
        limit: map['limit'],
        filters: (map['filters'] as List<dynamic>?)
                ?.map((f) => FilterConfig.fromMap(f as Map<String, dynamic>))
                .toList() ??
            [],
      );

  DataSourceConfig copyWith({
    String? type,
    String? view,
    String? valueField,
    String? aggregation,
    String? groupBy,
    String? orderBy,
    int? limit,
    List<FilterConfig>? filters,
  }) =>
      DataSourceConfig(
        type: type ?? this.type,
        view: view ?? this.view,
        valueField: valueField ?? this.valueField,
        aggregation: aggregation ?? this.aggregation,
        groupBy: groupBy ?? this.groupBy,
        orderBy: orderBy ?? this.orderBy,
        limit: limit ?? this.limit,
        filters: filters ?? this.filters,
      );
}

// =============================================================================
// WIDGET POSITION
// =============================================================================

/// Position and size of a widget in the dashboard grid
class WidgetPosition {
  final int x; // Column (0-11)
  final int y; // Row
  final int w; // Width in columns (1-12)
  final int h; // Height in row units

  const WidgetPosition({
    this.x = 0,
    this.y = 0,
    this.w = 3,
    this.h = 2,
  });

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
      };

  factory WidgetPosition.fromMap(Map<String, dynamic> map) => WidgetPosition(
        x: map['x'] ?? 0,
        y: map['y'] ?? 0,
        w: map['w'] ?? 3,
        h: map['h'] ?? 2,
      );

  WidgetPosition copyWith({int? x, int? y, int? w, int? h}) => WidgetPosition(
        x: x ?? this.x,
        y: y ?? this.y,
        w: w ?? this.w,
        h: h ?? this.h,
      );
}

// =============================================================================
// DISPLAY CONFIG
// =============================================================================

/// Display/styling configuration for a widget
class DisplayConfig {
  final String? icon; // Material icon name
  final String color; // Hex color
  final bool showTrend; // Show trend indicator
  final String? trendPeriod; // 'day', 'week', 'month'
  final List<String>? colors; // Color palette for charts
  final String? format; // Number format: 'number', 'currency', 'percent'
  final String? prefix; // e.g., "EGP "
  final String? suffix; // e.g., "%"

  const DisplayConfig({
    this.icon,
    this.color = '#2196F3',
    this.showTrend = false,
    this.trendPeriod,
    this.colors,
    this.format,
    this.prefix,
    this.suffix,
  });

  Map<String, dynamic> toMap() => {
        if (icon != null) 'icon': icon,
        'color': color,
        'showTrend': showTrend,
        if (trendPeriod != null) 'trendPeriod': trendPeriod,
        if (colors != null) 'colors': colors,
        if (format != null) 'format': format,
        if (prefix != null) 'prefix': prefix,
        if (suffix != null) 'suffix': suffix,
      };

  factory DisplayConfig.fromMap(Map<String, dynamic> map) => DisplayConfig(
        icon: map['icon'],
        color: map['color'] ?? '#2196F3',
        showTrend: map['showTrend'] ?? false,
        trendPeriod: map['trendPeriod'],
        colors: (map['colors'] as List<dynamic>?)?.cast<String>(),
        format: map['format'],
        prefix: map['prefix'],
        suffix: map['suffix'],
      );

  DisplayConfig copyWith({
    String? icon,
    String? color,
    bool? showTrend,
    String? trendPeriod,
    List<String>? colors,
    String? format,
    String? prefix,
    String? suffix,
  }) =>
      DisplayConfig(
        icon: icon ?? this.icon,
        color: color ?? this.color,
        showTrend: showTrend ?? this.showTrend,
        trendPeriod: trendPeriod ?? this.trendPeriod,
        colors: colors ?? this.colors,
        format: format ?? this.format,
        prefix: prefix ?? this.prefix,
        suffix: suffix ?? this.suffix,
      );
}

// =============================================================================
// WIDGET CONFIG
// =============================================================================

/// Complete configuration for a single dashboard widget
class WidgetConfig {
  final String id;
  final String type; // counter, pie, bar, line, table, heatmap
  final String title;
  final String? titleAr;
  final WidgetPosition position;
  final DataSourceConfig dataSource;
  final DisplayConfig display;

  const WidgetConfig({
    required this.id,
    required this.type,
    required this.title,
    this.titleAr,
    required this.position,
    required this.dataSource,
    required this.display,
  });

  WidgetType get widgetType => WidgetTypeExtension.fromString(type);

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        if (titleAr != null) 'titleAr': titleAr,
        'position': position.toMap(),
        'dataSource': dataSource.toMap(),
        'display': display.toMap(),
      };

  factory WidgetConfig.fromMap(Map<String, dynamic> map) => WidgetConfig(
        id: map['id'] ?? '',
        type: map['type'] ?? 'counter',
        title: map['title'] ?? '',
        titleAr: map['titleAr'],
        position: WidgetPosition.fromMap(map['position'] ?? {}),
        dataSource: DataSourceConfig.fromMap(map['dataSource'] ?? {}),
        display: DisplayConfig.fromMap(map['display'] ?? {}),
      );

  WidgetConfig copyWith({
    String? id,
    String? type,
    String? title,
    String? titleAr,
    WidgetPosition? position,
    DataSourceConfig? dataSource,
    DisplayConfig? display,
  }) =>
      WidgetConfig(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        titleAr: titleAr ?? this.titleAr,
        position: position ?? this.position,
        dataSource: dataSource ?? this.dataSource,
        display: display ?? this.display,
      );

  /// Create a default counter widget
  factory WidgetConfig.defaultCounter() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'counter',
        title: 'New Counter',
        position: const WidgetPosition(x: 0, y: 0, w: 3, h: 2),
        dataSource: const DataSourceConfig(
          view: 'submission_answers',
          aggregation: 'count',
        ),
        display: const DisplayConfig(
          icon: 'numbers',
          color: '#2196F3',
        ),
      );

  /// Create a default pie chart widget
  factory WidgetConfig.defaultPie() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'pie',
        title: 'New Pie Chart',
        position: const WidgetPosition(x: 0, y: 0, w: 4, h: 3),
        dataSource: const DataSourceConfig(
          view: 'submission_answers',
          aggregation: 'count',
          groupBy: 'channel',
          limit: 6,
        ),
        display: const DisplayConfig(
          colors: [
            '#F44336',
            '#2196F3',
            '#4CAF50',
            '#FF9800',
            '#9C27B0',
            '#00BCD4'
          ],
        ),
      );

  /// Create a default bar chart widget
  factory WidgetConfig.defaultBar() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'bar',
        title: 'New Bar Chart',
        position: const WidgetPosition(x: 0, y: 0, w: 6, h: 3),
        dataSource: const DataSourceConfig(
          view: 'v_price_observations',
          valueField: 'price',
          aggregation: 'avg',
          groupBy: 'channel',
          orderBy: 'avg DESC',
          limit: 10,
        ),
        display: const DisplayConfig(
          color: '#4CAF50',
        ),
      );

  /// Create a default line chart widget
  factory WidgetConfig.defaultLine() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'line',
        title: 'New Line Chart',
        position: const WidgetPosition(x: 0, y: 0, w: 6, h: 3),
        dataSource: const DataSourceConfig(
          view: 'v_daily_prices',
          valueField: 'avg_price',
          aggregation: 'avg',
          groupBy: 'observed_date',
          orderBy: 'observed_date ASC',
        ),
        display: const DisplayConfig(
          color: '#2196F3',
          showTrend: true,
        ),
      );

  /// Create a default table widget
  factory WidgetConfig.defaultTable() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'table',
        title: 'New Table',
        position: const WidgetPosition(x: 0, y: 0, w: 12, h: 4),
        dataSource: const DataSourceConfig(
          view: 'v_price_observations',
          orderBy: 'observed_date DESC',
          limit: 20,
        ),
        display: const DisplayConfig(),
      );

  /// Create a default heatmap widget
  factory WidgetConfig.defaultHeatmap() => WidgetConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'heatmap',
        title: 'New Heatmap',
        position: const WidgetPosition(x: 0, y: 0, w: 8, h: 4),
        dataSource: const DataSourceConfig(
          view: 'v_day_patterns',
          valueField: 'availability_pct',
        ),
        display: const DisplayConfig(
          colors: ['#FFCDD2', '#FFF9C4', '#C8E6C9'],
        ),
      );
}

// =============================================================================
// GLOBAL FILTER CONFIG
// =============================================================================

/// Configuration for dashboard-level filters
class GlobalFilterConfig {
  final bool dateRangeEnabled;
  final String
      defaultDateRange; // 'last_7_days', 'last_30_days', 'last_90_days', 'custom'
  final bool cityEnabled;
  final bool channelEnabled;

  const GlobalFilterConfig({
    this.dateRangeEnabled = true,
    this.defaultDateRange = 'last_30_days',
    this.cityEnabled = true,
    this.channelEnabled = true,
  });

  Map<String, dynamic> toMap() => {
        'dateRangeEnabled': dateRangeEnabled,
        'defaultDateRange': defaultDateRange,
        'cityEnabled': cityEnabled,
        'channelEnabled': channelEnabled,
      };

  factory GlobalFilterConfig.fromMap(Map<String, dynamic> map) =>
      GlobalFilterConfig(
        dateRangeEnabled: map['dateRangeEnabled'] ?? true,
        defaultDateRange: map['defaultDateRange'] ?? 'last_30_days',
        cityEnabled: map['cityEnabled'] ?? true,
        channelEnabled: map['channelEnabled'] ?? true,
      );
}

// =============================================================================
// DASHBOARD CONFIG
// =============================================================================

/// Complete dashboard configuration
class DashboardConfig {
  final String id;
  final String clientId;
  final String? missionId;
  final String title;
  final String? titleAr;
  final String status; // 'draft', 'published'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final GlobalFilterConfig globalFilters;
  final List<WidgetConfig> widgets;

  const DashboardConfig({
    required this.id,
    required this.clientId,
    this.missionId,
    required this.title,
    this.titleAr,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.globalFilters = const GlobalFilterConfig(),
    this.widgets = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        if (missionId != null) 'missionId': missionId,
        'title': title,
        if (titleAr != null) 'titleAr': titleAr,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (createdBy != null) 'createdBy': createdBy,
        'globalFilters': globalFilters.toMap(),
        'widgets': widgets.map((w) => w.toMap()).toList(),
      };

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return DashboardConfig(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      missionId: map['missionId'],
      title: map['title'] ?? '',
      titleAr: map['titleAr'],
      status: map['status'] ?? 'draft',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      createdBy: map['createdBy'],
      globalFilters: GlobalFilterConfig.fromMap(map['globalFilters'] ?? {}),
      widgets: (map['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetConfig.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  DashboardConfig copyWith({
    String? id,
    String? clientId,
    String? missionId,
    String? title,
    String? titleAr,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    GlobalFilterConfig? globalFilters,
    List<WidgetConfig>? widgets,
  }) =>
      DashboardConfig(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        missionId: missionId ?? this.missionId,
        title: title ?? this.title,
        titleAr: titleAr ?? this.titleAr,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        globalFilters: globalFilters ?? this.globalFilters,
        widgets: widgets ?? this.widgets,
      );

  /// Create a new empty dashboard for a mission
  factory DashboardConfig.forMission({
    required String clientId,
    required String missionId,
    required String missionName,
  }) =>
      DashboardConfig(
        id: '${missionId}_dashboard',
        clientId: clientId,
        missionId: missionId,
        title: '$missionName Dashboard',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        widgets: [],
      );

  /// Check if dashboard has unsaved changes
  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
}
