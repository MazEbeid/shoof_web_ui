# Shoof Web UI

> **Shared Design System for Shoof Web Applications**  
> Consistent components for ShooofAdmin and shoof_insights

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shoof_web_ui:
    path: ../shoof_web_ui
```

Import in your Dart files:

```dart
import 'package:shoof_web_ui/shoof_web_ui.dart';
```

---

## 🎨 Design System

### Colors (`AdminColors`)

```dart
// Primary Brand
AdminColors.primary         // #2962FF - Main brand blue
AdminColors.primaryDark     // #0039CB
AdminColors.primaryLight    // #768FFF
AdminColors.primarySurface  // #E8F0FE - Light blue tint

// Accent
AdminColors.accent          // #FFB800 - Warm gold
AdminColors.accentLight     // #FFD54F

// Mission Types
AdminColors.streetMission   // #6C5CE7 - Purple
AdminColors.consumerMission // #00B894 - Teal
AdminColors.censusMission   // #E17055 - Coral
AdminColors.trainingMission // #0984E3 - Blue

// Semantic
AdminColors.success         // #00C853 - Green
AdminColors.successLight    // #E8F5E9
AdminColors.warning         // #FFAB00 - Amber
AdminColors.warningLight    // #FFF8E1
AdminColors.error           // #FF1744 - Red
AdminColors.errorLight      // #FFEBEE
AdminColors.info            // #00B0FF - Light blue
AdminColors.infoLight       // #E1F5FE

// Brand Colors (for competitive analysis charts)
AdminColors.cocaCola        // #E31837
AdminColors.pepsi           // #004B93
AdminColors.schweppes       // #FFD700
AdminColors.fayrouz         // #00A650

// Backgrounds
AdminColors.backgroundPage    // #F5F7FA
AdminColors.backgroundCard    // #FFFFFF
AdminColors.backgroundSidebar // #1E293B
AdminColors.backgroundHover   // #F1F5F9

// Text
AdminColors.textPrimary     // #1E293B
AdminColors.textSecondary   // #64748B
AdminColors.textMuted       // #94A3B8
AdminColors.textOnPrimary   // #FFFFFF

// Sidebar
AdminColors.sidebarBackground // #1E293B
AdminColors.sidebarText       // #CBD5E1
AdminColors.sidebarTextActive // #FFFFFF
AdminColors.sidebarItemHover  // #334155
AdminColors.sidebarItemActive // #2962FF

// Table
AdminColors.tableHeader     // #F8FAFC
AdminColors.tableRowHover   // #EFF6FF
AdminColors.tableRowSelected // #DBEAFE

// Chart Palette (10 colors for data visualization)
AdminColors.chartPalette    // List<Color>

// Gradients
AdminColors.primaryGradient // Blue → Purple
AdminColors.heroGradient    // Deep navy gradient
AdminColors.successGradient // Green gradient

// Helper Methods
AdminColors.getStatusColor('completed')           // → success green
AdminColors.getStatusBackgroundColor('pending')   // → warning light
```

---

### Typography (`AdminTextStyles`)

```dart
// Display (Large hero numbers/KPIs)
AdminTextStyles.displayLarge   // 56px Bold
AdminTextStyles.displayMedium  // 40px Bold
AdminTextStyles.displaySmall   // 32px Bold

// Page & Section Headers
AdminTextStyles.pageTitle      // 24px Bold
AdminTextStyles.sectionTitle   // 18px Bold
AdminTextStyles.cardTitle      // 16px SemiBold
AdminTextStyles.subtitle       // 14px Medium (secondary color)

// Headlines
AdminTextStyles.headlineLarge  // 28px Bold
AdminTextStyles.headlineMedium // 24px Bold
AdminTextStyles.headlineSmall  // 20px Bold

// Titles
AdminTextStyles.titleLarge     // 18px Medium
AdminTextStyles.titleMedium    // 16px Medium
AdminTextStyles.titleSmall     // 14px Medium

// Body
AdminTextStyles.bodyLarge      // 16px Regular
AdminTextStyles.bodyMedium     // 14px Regular
AdminTextStyles.bodySmall      // 12px Regular (secondary color)

// Labels
AdminTextStyles.labelLarge     // 14px Medium
AdminTextStyles.labelMedium    // 12px Medium
AdminTextStyles.labelSmall     // 11px Medium (muted color)

// Stats/KPIs
AdminTextStyles.statLarge      // 48px Bold
AdminTextStyles.statMedium     // 32px Bold
AdminTextStyles.statSmall      // 24px SemiBold

// Table
AdminTextStyles.tableHeader    // 12px SemiBold (secondary color)
AdminTextStyles.tableCell      // 14px Regular

// Sidebar
AdminTextStyles.sidebarItem       // 14px Medium
AdminTextStyles.sidebarItemActive // 14px SemiBold (white)
AdminTextStyles.sidebarHeader     // 11px SemiBold (muted)

// Buttons
AdminTextStyles.buttonLarge    // 16px SemiBold
AdminTextStyles.buttonMedium   // 14px SemiBold
AdminTextStyles.buttonSmall    // 12px SemiBold

// Input
AdminTextStyles.inputText      // 14px Regular
AdminTextStyles.inputHint      // 14px Regular (muted)
AdminTextStyles.inputLabel     // 13px Medium
AdminTextStyles.inputError     // 12px Regular (error color)

// Charts
AdminTextStyles.chartLabel     // 11px Regular (muted)
AdminTextStyles.chartTooltip   // 12px Medium (white)

// Links
AdminTextStyles.link           // 14px Medium (link color)
AdminTextStyles.linkUnderlined // 14px Medium (underlined)

// Extension Methods
AdminTextStyles.bodyMedium.onDark      // White text
AdminTextStyles.bodyMedium.muted       // Muted color
AdminTextStyles.bodyMedium.secondary   // Secondary color
AdminTextStyles.bodyMedium.primaryColor // Primary blue
AdminTextStyles.bodyMedium.success     // Green
AdminTextStyles.bodyMedium.warning     // Amber
AdminTextStyles.bodyMedium.error       // Red
AdminTextStyles.bodyMedium.bold        // Bold weight
AdminTextStyles.bodyMedium.semiBold    // SemiBold weight
```

---

### Spacing (`AdminSpacing`)

```dart
// Base Spacing
AdminSpacing.xxs   // 2.0
AdminSpacing.xs    // 4.0
AdminSpacing.sm    // 8.0
AdminSpacing.md    // 12.0
AdminSpacing.lg    // 16.0
AdminSpacing.xl    // 24.0
AdminSpacing.xxl   // 32.0
AdminSpacing.xxxl  // 48.0
AdminSpacing.xxxxl // 64.0

// Page Layout
AdminSpacing.pageHorizontal  // 24.0
AdminSpacing.pageVertical    // 24.0
AdminSpacing.sectionGap      // 24.0
AdminSpacing.cardGap         // 16.0

// Sidebar
AdminSpacing.sidebarWidth          // 260.0
AdminSpacing.sidebarCollapsedWidth // 72.0
AdminSpacing.sidebarItemHeight     // 44.0
AdminSpacing.sidebarPadding        // 16.0
AdminSpacing.topBarHeight          // 64.0

// Cards
AdminSpacing.cardPadding    // 20.0
AdminSpacing.cardPaddingSm  // 16.0
AdminSpacing.cardPaddingLg  // 24.0

// Table
AdminSpacing.tableCellPadding   // 12.0
AdminSpacing.tableHeaderHeight  // 48.0
AdminSpacing.tableRowHeight     // 52.0

// Buttons
AdminSpacing.buttonHeightSm          // 32.0
AdminSpacing.buttonHeightMd          // 40.0
AdminSpacing.buttonHeightLg          // 48.0
AdminSpacing.buttonPaddingHorizontal // 16.0

// Dialogs
AdminSpacing.dialogWidthSm  // 400.0
AdminSpacing.dialogWidthMd  // 560.0
AdminSpacing.dialogWidthLg  // 720.0
AdminSpacing.dialogPadding  // 24.0

// Stat Cards
AdminSpacing.statCardMinWidth // 200.0
AdminSpacing.statCardHeight   // 120.0
```

---

### Border Radius (`AdminRadius`)

```dart
AdminRadius.xs   // 4.0
AdminRadius.sm   // 6.0
AdminRadius.md   // 8.0
AdminRadius.lg   // 12.0
AdminRadius.xl   // 16.0
AdminRadius.full // 999.0 (pill shape)

// Pre-built BorderRadius
AdminRadius.xsAll   // BorderRadius.all(Radius.circular(4))
AdminRadius.smAll   // BorderRadius.all(Radius.circular(6))
AdminRadius.mdAll   // BorderRadius.all(Radius.circular(8))
AdminRadius.lgAll   // BorderRadius.all(Radius.circular(12))
AdminRadius.xlAll   // BorderRadius.all(Radius.circular(16))
AdminRadius.fullAll // BorderRadius.all(Radius.circular(999))
```

---

### Shadows (`AdminShadows`)

```dart
AdminShadows.xs     // Subtle shadow (blur: 2)
AdminShadows.sm     // Card shadow (blur: 4)
AdminShadows.md     // Elevated shadow (blur: 8)
AdminShadows.lg     // Modal shadow (blur: 16)
AdminShadows.xl     // Floating shadow (blur: 24)
AdminShadows.sidebar // Sidebar shadow (right-facing)

// Glow Effects
AdminShadows.primaryGlow(opacity: 0.3)  // Blue glow
AdminShadows.successGlow(opacity: 0.3)  // Green glow
AdminShadows.errorGlow(opacity: 0.3)    // Red glow
```

---

### Breakpoints (`AdminBreakpoints`)

```dart
AdminBreakpoints.mobile     // 480px
AdminBreakpoints.tablet     // 768px
AdminBreakpoints.desktop    // 1024px
AdminBreakpoints.widescreen // 1280px
AdminBreakpoints.ultrawide  // 1536px

// Helper Methods
AdminBreakpoints.isMobile(context)     // bool
AdminBreakpoints.isTablet(context)     // bool
AdminBreakpoints.isDesktop(context)    // bool
AdminBreakpoints.isWidescreen(context) // bool
AdminBreakpoints.isUltrawide(context)  // bool

AdminBreakpoints.getGridColumns(context)   // 1-4 based on width
AdminBreakpoints.getStatCardCount(context) // 1-5 based on width
```

---

## 📦 Widgets

### Cards

#### `AdminCard`

Standard card container with optional title and actions.

```dart
AdminCard(
  title: 'Card Title',
  actions: [
    AdminSecondaryButton(label: 'Action', onPressed: () {}),
  ],
  elevated: true, // Optional: adds more shadow
  onTap: () {},   // Optional: makes card tappable
  child: Text('Card content'),
)
```

#### `AdminCardFlat`

Flat card variant with border instead of shadow.

```dart
AdminCardFlat(
  title: 'Flat Card',
  child: Text('Content'),
)
```

#### `AdminEmptyState`

Empty state placeholder for cards/tables.

```dart
AdminEmptyState(
  title: 'No Data Found',
  subtitle: 'Try adjusting your filters',
  icon: Icons.inbox_outlined,
  action: AdminPrimaryButton(label: 'Add New', onPressed: () {}),
)
```

#### `AdminErrorState`

Error state with retry button.

```dart
AdminErrorState(
  title: 'Something went wrong',
  subtitle: 'Please try again',
  onRetry: () => _loadData(),
)
```

#### `AdminLoadingState`

Loading spinner with optional message.

```dart
AdminLoadingState(message: 'Loading data...')
```

---

### Stat Cards

#### `AdminStatCard`

KPI/metric card with icon, value, and trend.

```dart
AdminStatCard(
  title: 'Total Missions',
  value: '1,247',
  icon: Icons.assignment_rounded,
  accentColor: AdminColors.primary,
  trend: '+12%',
  trendUp: true,
  subtitle: 'This month',
  onTap: () => navigateToMissions(),
  isLoading: false,
)
```

#### `AdminStatCardRow`

Responsive row of stat cards.

```dart
AdminStatCardRow(
  cards: [
    AdminStatCard(title: 'Missions', value: '1,247', ...),
    AdminStatCard(title: 'Availability', value: '89%', ...),
    AdminStatCard(title: 'Coverage', value: '23', ...),
  ],
)
```

#### `AdminStatCardCompact`

Compact inline stat badge.

```dart
AdminStatCardCompact(
  title: 'missions',
  value: '42',
  icon: Icons.check,
  color: AdminColors.success,
)
```

#### `AdminBalanceCard`

Balance/wallet style card.

```dart
AdminBalanceCard(
  title: 'Fawry Balance',
  value: 'EGP 5,240.00',
  subtitle: 'Last updated: 2 min ago',
  icon: Icons.account_balance_wallet,
  accentColor: AdminColors.success,
  isLoading: false,
  isError: false,
  onTap: () {},
)
```

---

### Buttons

#### `AdminPrimaryButton`

Primary filled button.

```dart
AdminPrimaryButton(
  label: 'Save Changes',
  icon: Icons.save,
  onPressed: () => save(),
  isLoading: false,
  width: 200, // Optional fixed width
)
```

#### `AdminSecondaryButton`

Secondary outlined button.

```dart
AdminSecondaryButton(
  label: 'Cancel',
  icon: Icons.close,
  onPressed: () => cancel(),
)
```

#### `AdminDangerButton`

Danger/delete button (red).

```dart
AdminDangerButton(
  label: 'Delete',
  icon: Icons.delete,
  onPressed: () => confirmDelete(),
  isLoading: isDeleting,
)
```

#### `AdminActionButton`

Compact icon button for table actions.

```dart
AdminActionButton(
  icon: Icons.edit,
  tooltip: 'Edit',
  onPressed: () => edit(),
  color: AdminColors.primary,
  size: 32,
)
```

#### Preset Action Buttons

```dart
AdminEditButton(onPressed: () => edit())
AdminDeleteButton(onPressed: () => delete(), isLoading: false)
AdminViewButton(onPressed: () => view())
AdminResetButton(onPressed: () => reset())
AdminCopyButton(onPressed: () => copy())
AdminExportButton(onPressed: () => export())
```

#### `AdminActionButtonRow`

Groups multiple action buttons.

```dart
AdminActionButtonRow(
  children: [
    AdminViewButton(onPressed: () {}),
    AdminEditButton(onPressed: () {}),
    AdminDeleteButton(onPressed: () {}),
  ],
)
```

#### `AdminTextActionButton`

Text button with optional icon and border.

```dart
AdminTextActionButton(
  label: 'View Details',
  icon: Icons.open_in_new,
  onPressed: () {},
  color: AdminColors.info,
  compact: true,
)
```

---

### Status Badges

#### `AdminStatusBadge`

Status badge with background color.

```dart
AdminStatusBadge(
  status: 'completed', // auto-colors based on status
  showIcon: true,
  fontSize: 12,
)

// Supported statuses:
// 'approved', 'accepted', 'completed', 'paid', 'active' → Green
// 'pending', 'waiting', 'in_review' → Amber
// 'rejected', 'expired', 'failed', 'inactive' → Red
// 'in_progress', 'processing' → Blue
```

#### `AdminStatusDot`

Small colored dot indicator.

```dart
AdminStatusDot(status: 'active', size: 8)
```

#### `AdminStatusCell`

Status dot with label for table cells.

```dart
AdminStatusCell(
  status: 'completed',
  label: 'Completed', // Optional custom label
)
```

---

### Dialogs

#### `AdminDialog`

Standard dialog with title, content, and actions.

```dart
AdminDialog.show(
  context: context,
  title: 'Edit Mission',
  subtitle: 'Update mission details',
  titleIcon: Icons.edit,
  titleIconColor: AdminColors.primary,
  width: 500,
  content: Form(...),
  actions: [
    AdminSecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
    AdminPrimaryButton(label: 'Save', onPressed: () => save()),
  ],
);
```

#### `AdminConfirmDialog`

Confirmation dialog with confirm/cancel.

```dart
final confirmed = await AdminConfirmDialog.show(
  context: context,
  title: 'Delete Mission?',
  message: 'This action cannot be undone.',
  confirmLabel: 'Delete',
  cancelLabel: 'Cancel',
  isDanger: true,
  icon: Icons.delete,
);
if (confirmed == true) {
  // Delete
}
```

#### `AdminLoadingDialog`

Loading overlay dialog.

```dart
// Show
AdminLoadingDialog.show(context, message: 'Saving...');

// Hide
AdminLoadingDialog.hide(context);
```

#### `AdminFormDialog`

Form dialog with submit/cancel.

```dart
AdminFormDialog(
  title: 'Add Item',
  subtitle: 'Fill in the details',
  titleIcon: Icons.add,
  submitLabel: 'Create',
  cancelLabel: 'Cancel',
  isSubmitting: isLoading,
  onSubmit: () => create(),
  content: Column(
    children: [
      AdminDialogField(label: 'Name', controller: nameController),
      AdminDialogDropdown(label: 'Type', items: [...], value: selected),
    ],
  ),
)
```

#### Dialog Form Fields

```dart
// Text field
AdminDialogField(
  label: 'Name',
  hint: 'Enter name',
  controller: controller,
  isRequired: true,
  maxLines: 1,
  helperText: 'This will be displayed publicly',
)

// Dropdown
AdminDialogDropdown<String>(
  label: 'Category',
  value: selectedCategory,
  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
  onChanged: (v) => setState(() => selectedCategory = v),
  isRequired: true,
)
```

---

### Text Fields

#### `AdminTextField`

Standard text input with label.

```dart
AdminTextField(
  label: 'Email',
  hintText: 'Enter your email',
  controller: emailController,
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  onChanged: (v) => validate(),
  validator: (v) => v!.isEmpty ? 'Required' : null,
)
```

#### `AdminPasswordField`

Password field with visibility toggle.

```dart
AdminPasswordField(
  label: 'Password',
  hintText: 'Enter password',
  controller: passwordController,
  onSubmitted: (v) => login(),
)
```

#### `AdminSearchField`

Search input with search icon.

```dart
AdminSearchField(
  hintText: 'Search missions...',
  controller: searchController,
  onChanged: (v) => filter(v),
  onClear: () => clearSearch(),
  width: 300,
)
```

#### `AdminDropdownField<T>`

Styled dropdown to match text fields.

```dart
AdminDropdownField<String>(
  label: 'Status',
  hintText: 'Select status',
  value: selectedStatus,
  items: [
    DropdownMenuItem(value: 'all', child: Text('All')),
    DropdownMenuItem(value: 'active', child: Text('Active')),
    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
  ],
  onChanged: (v) => setState(() => selectedStatus = v),
)
```

---

### Flushbar (Toast/Snackbar)

#### `AdminFlushbar`

Toast notifications.

```dart
// Success
AdminFlushbar.success(context, message: 'Saved successfully!');

// Error
AdminFlushbar.error(context, message: 'Something went wrong');

// Warning
AdminFlushbar.warning(context, message: 'Please check your input');

// Info
AdminFlushbar.info(context, message: 'New update available');

// Custom
AdminFlushbar.show(
  context,
  message: 'Custom message',
  icon: Icons.star,
  backgroundColor: AdminColors.primary,
  duration: Duration(seconds: 3),
);
```

---

## 🎯 Best Practices

### 1. Consistent Spacing

Always use `AdminSpacing` constants:

```dart
// ✅ Good
padding: EdgeInsets.all(AdminSpacing.lg),
SizedBox(height: AdminSpacing.md),

// ❌ Avoid
padding: EdgeInsets.all(16),
SizedBox(height: 12),
```

### 2. Use Semantic Colors

```dart
// ✅ Good
color: AdminColors.success,
color: AdminColors.getStatusColor(status),

// ❌ Avoid
color: Colors.green,
color: Color(0xFF00C853),
```

### 3. Responsive Layouts

```dart
if (AdminBreakpoints.isMobile(context)) {
  return Column(children: cards);
} else {
  return Row(children: cards.map((c) => Expanded(child: c)).toList());
}
```

### 4. Consistent Cards

```dart
// ✅ Good - Using AdminCard
AdminCard(
  title: 'My Card',
  child: content,
)

// ❌ Avoid - Custom containers
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: content,
)
```

---

## 📱 Font Configuration

The package uses NeoSans by default for Arabic support. To switch to Google Fonts:

```dart
void main() {
  AdminFonts.useGoogleFonts(); // Switch to Plus Jakarta Sans
  runApp(MyApp());
}
```

---

## 🔧 Theme Integration

Apply the admin theme to your app:

```dart
MaterialApp(
  theme: AdminTheme.lightTheme,
  // ...
)
```

---

*Last Updated: January 2026*

