import 'package:flutter/material.dart';

class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String amount;
  final bool isIncome;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF182131) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? const Color(0xFFADB5C4) : Colors.grey.shade600;
    final color = isIncome ? const Color(0xFF2E8B57) : const Color(0xFFD35B5B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: isDark ? 0.20 : 0.10),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  category,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}