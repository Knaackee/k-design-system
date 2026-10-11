part of 'k_files.dart';

class KStorageEntry {
  const KStorageEntry({
    required this.id,
    required this.label,
    required this.bytes,
    this.detail,
  });
  final String id, label;
  final int bytes;
  final Widget? detail;
}

class KStorageBreakdown extends StatelessWidget {
  const KStorageBreakdown({
    required this.entries,
    required this.formatBytes,
    this.title = 'Speicherverbrauch',
    this.checkedAt,
    this.child,
    super.key,
  });
  final List<KStorageEntry> entries;
  final String Function(int) formatBytes;
  final String title;
  final Widget? checkedAt, child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.bytes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Padding(
          padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
          child: Text(
            formatBytes(total),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ?checkedAt,
        for (final entry in entries)
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.spaceControlInsetInline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(entry.label)),
                    Text(
                      formatBytes(entry.bytes),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: t.spaceControlGap),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : entry.bytes / total,
                  minHeight: t.spaceTight,
                ),
                if (entry.detail != null) entry.detail!,
              ],
            ),
          ),
        ?child,
      ],
    );
  }
}
