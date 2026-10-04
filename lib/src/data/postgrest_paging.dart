/// PostgREST caps EVERY response at the server's max-rows setting (Supabase
/// default 1,000) — an explicit larger `.limit()` is silently truncated.
/// Reads that can exceed the cap must page with `.range()`.
///
/// The query passed to [fetchAllPages] MUST have a deterministic `.order()`
/// applied by the caller, otherwise pages can overlap or skip rows.
Future<List<Map<String, dynamic>>> fetchAllPages(
  Future<List<dynamic>> Function(int from, int to) fetchPage, {
  int pageSize = 1000,
  int maxRows = 200000,
}) async {
  final all = <Map<String, dynamic>>[];
  var from = 0;
  while (from < maxRows) {
    final page = await fetchPage(from, from + pageSize - 1);
    all.addAll(page.cast<Map<String, dynamic>>());
    if (page.length < pageSize) break;
    from += pageSize;
  }
  return all;
}
