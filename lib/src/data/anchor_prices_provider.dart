import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Mission-level anchor prices — editable by admin and client.
/// Path: clients/{clientId}/missions/{missionId}/anchorPrices
class AnchorPricesState {
  final Map<String, double> prices;
  final DateTime? updatedAt;

  const AnchorPricesState({
    this.prices = const {},
    this.updatedAt,
  });

  AnchorPricesState copyWith({
    Map<String, double>? prices,
    DateTime? updatedAt,
  }) =>
      AnchorPricesState(
        prices: prices ?? this.prices,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AnchorPricesParams {
  final String clientId;
  final String missionId;

  const AnchorPricesParams({
    required this.clientId,
    required this.missionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnchorPricesParams &&
          clientId == other.clientId &&
          missionId == other.missionId;

  @override
  int get hashCode => clientId.hashCode ^ missionId.hashCode;
}

DocumentReference<Map<String, dynamic>> _anchorPricesRef(
  String clientId,
  String missionId,
) {
  return FirebaseFirestore.instance
      .collection('clients')
      .doc(clientId)
      .collection('missions')
      .doc(missionId)
      .collection('anchorPrices')
      .doc('prices');
}

final anchorPricesProvider = StateNotifierProvider.autoDispose
    .family<AnchorPricesNotifier, AsyncValue<AnchorPricesState>, AnchorPricesParams>(
  (ref, params) => AnchorPricesNotifier(params),
);

class AnchorPricesNotifier extends StateNotifier<AsyncValue<AnchorPricesState>> {
  final AnchorPricesParams params;

  AnchorPricesNotifier(this.params) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await _anchorPricesRef(params.clientId, params.missionId).get();
      if (!doc.exists) {
        state = const AsyncValue.data(AnchorPricesState());
        return;
      }
      final data = doc.data()!;
      final raw = data['prices'] as Map<String, dynamic>? ?? {};
      final prices = raw.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
      final updatedAt = data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null;
      state = AsyncValue.data(AnchorPricesState(prices: prices, updatedAt: updatedAt));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPrice(String skuKey, double price) async {
    final current = state.value ?? const AnchorPricesState();
    final updated = Map<String, double>.from(current.prices)..[skuKey] = price;
    state = AsyncValue.data(current.copyWith(prices: updated));
    await _save(updated);
  }

  Future<void> removePrice(String skuKey) async {
    final current = state.value ?? const AnchorPricesState();
    final updated = Map<String, double>.from(current.prices)..remove(skuKey);
    state = AsyncValue.data(current.copyWith(prices: updated));
    await _save(updated);
  }

  Future<void> _save(Map<String, double> prices) async {
    await _anchorPricesRef(params.clientId, params.missionId).set({
      'prices': prices,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Stable key for a price observation SKU row.
String priceSkuKey({
  required String productName,
  String? size,
  String? packaging,
}) {
  final name = productName.trim();
  final s = (size ?? '').trim();
  final p = (packaging ?? '').trim();
  return '$name|$s|$p';
}

String priceSkuLabel(String skuKey) {
  final parts = skuKey.split('|');
  if (parts.length < 3) return skuKey;
  final name = parts[0];
  final size = parts[1];
  final packaging = parts[2];
  if (size.isEmpty && packaging.isEmpty) return name;
  if (packaging.isEmpty) return '$name ($size)';
  return '$name ($size $packaging)';
}
