class AppDateUtils {
  /// Calculates the number of calendar days left until [endDate] from today.
  /// Normalizes both dates to the start of the day to ensure the count
  /// decrements exactly at midnight.
  static int calculateDaysLeft(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(endDate.year, endDate.month, endDate.day);
    
    // The user wants 365 days validity to show as 364 days left on day one.
    // So we subtract 1 from the actual day difference.
    //final diff = expiryDate.difference(today).inDays;
    //return diff > 0 ? diff - 1 : diff;
    return expiryDate.difference(today).inDays;
  }

  /// Returns true if the subscription or item is expired based on calendar date.
  /// Modified to match the offset calculation.
  static bool isExpired(DateTime endDate) {
    // If the difference is 0 or less, it's the expiry day or later.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(endDate.year, endDate.month, endDate.day);
    return expiryDate.isBefore(today);
  }
}
