class DateFormatter {
  static String getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  static String formatDate(DateTime? date, {String fallback = 'N/A'}) {
    if (date == null) return fallback;
    return '${date.day.toString().padLeft(2, '0')} ${getMonthName(date.month)} ${date.year}';
  }

  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
