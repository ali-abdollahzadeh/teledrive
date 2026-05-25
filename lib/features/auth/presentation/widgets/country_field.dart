import 'package:flutter/material.dart';

class CountryField extends StatelessWidget {
  const CountryField({
    required this.countryName,
    required this.countryFlag,
    required this.onTap,
  });

  final String countryName;
  final String countryFlag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(500),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(500),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Text(
              countryFlag,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                countryName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 32,
              color: theme.iconTheme.color?.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
