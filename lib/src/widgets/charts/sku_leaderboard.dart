import 'package:flutter/material.dart';

/// SKU ranking data for leaderboard
class SkuRankingData {
  final String id;
  final String name;
  final String brand;
  final String company;
  final double avgMarkup;
  final double volatility;
  final int violationCount;
  final double severityScore;
  final double factoryPrice;
  final double avgPrice;

  const SkuRankingData({
    required this.id,
    required this.name,
    required this.brand,
    required this.company,
    required this.avgMarkup,
    required this.volatility,
    required this.violationCount,
    required this.severityScore,
    required this.factoryPrice,
    required this.avgPrice,
  });
}

/// SKU offenders leaderboard - shows worst offenders by severity
class SkuLeaderboard extends StatelessWidget {
  final List<SkuRankingData> data;
  final String title;
  final String? subtitle;
  final double height;
  final ValueChanged<SkuRankingData>? onSkuTap;
  final String? highlightedSkuId;
  final Color highlightColor;

  const SkuLeaderboard({
    super.key,
    required this.data,
    this.title = 'SKU Offenders',
    this.subtitle,
    this.height = 350,
    this.onSkuTap,
    this.highlightedSkuId,
    this.highlightColor = const Color(0xFF9C27B0),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[400], size: 40),
              const SizedBox(height: 8),
              Text(
                'No pricing issues found!',
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${data.length} SKUs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const SizedBox(width: 28), // Rank
              Expanded(
                flex: 4,
                child: Text(
                  'SKU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Avg Markup',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Volatility',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  'Violations',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  'Severity',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // List
        SizedBox(
          height: height,
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final sku = data[index];
              return _buildSkuRow(sku, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkuRow(SkuRankingData sku, int index) {
    final isHighlighted = highlightedSkuId == sku.id;
    final severityColor = _getSeverityColor(sku.severityScore);

    return InkWell(
      onTap: onSkuTap != null ? () => onSkuTap!(sku) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? highlightColor.withOpacity(0.1)
              : index.isEven 
                  ? Colors.grey.withOpacity(0.03) 
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isHighlighted 
              ? Border.all(color: highlightColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
            ),

            // SKU info
            Expanded(
              flex: 4,
              child: Tooltip(
                message: '${sku.name}\nFactory: EGP ${sku.factoryPrice.toStringAsFixed(2)}\nAvg: EGP ${sku.avgPrice.toStringAsFixed(2)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sku.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                        color: isHighlighted ? highlightColor : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${sku.brand} · ${sku.company}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Avg Markup
            SizedBox(
              width: 60,
              child: Text(
                '${sku.avgMarkup >= 0 ? '+' : ''}${sku.avgMarkup.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sku.avgMarkup > 10 
                      ? Colors.red[700] 
                      : sku.avgMarkup > 5 
                          ? Colors.orange[700] 
                          : Colors.grey[700],
                ),
              ),
            ),

            // Volatility
            SizedBox(
              width: 50,
              child: Text(
                '${sku.volatility.toStringAsFixed(1)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ),

            // Violations
            SizedBox(
              width: 55,
              child: Text(
                '${sku.violationCount}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: sku.violationCount > 10 
                      ? Colors.red[700] 
                      : Colors.grey[700],
                ),
              ),
            ),

            // Severity bar
            SizedBox(
              width: 55,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (sku.severityScore / 50).clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: severityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(double severity) {
    if (severity > 30) return Colors.red[700]!;
    if (severity > 20) return Colors.orange[700]!;
    if (severity > 10) return Colors.amber[700]!;
    return Colors.grey[600]!;
  }
}
