String formatLibraryEditedAt(DateTime updatedAt) {
  final now = DateTime.now();
  final difference = now.difference(updatedAt);
  if (difference.inMinutes < 1) return 'Edited just now';
  if (difference.inHours < 1) return 'Edited ${difference.inMinutes}m ago';
  if (difference.inDays < 1) return 'Edited ${difference.inHours}h ago';
  if (difference.inDays < 7) {
    return 'Edited ${difference.inDays}d ago';
  }
  if (now.year == updatedAt.year) {
    return 'Edited ${_month(updatedAt.month)} ${updatedAt.day}';
  }
  return 'Edited ${_month(updatedAt.month)} ${updatedAt.day}, ${updatedAt.year}';
}

String _month(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month.clamp(1, 12) - 1];
}
