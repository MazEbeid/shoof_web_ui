// Pure CSV formatting (no dart:html) so data-layer code stays unit-testable.

String _escapeCsv(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// One CSV line (no trailing newline) with Excel-safe escaping.
String csvLine(Iterable<Object?> cells) =>
    cells.map((cell) => _escapeCsv(cell?.toString() ?? '')).join(',');
