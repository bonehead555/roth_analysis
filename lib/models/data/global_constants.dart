/// Class to use to manage a number of global constants
class GlobalConstants {
  /// Returns a record ({DateTime firstDate, DateTime lastDate}) identifying ...
  /// * firstDate - First valid plan date.
  /// * lastDate - Last Valid Plan Date.
  static ({DateTime firstDate, DateTime lastDate}) get validDateRange {
    final int currentYear = DateTime.now().year;
    final DateTime firstDate = DateTime(currentYear-100, 1, 1);
    final DateTime lastDate = DateTime(currentYear+100, 1, 1);
    return (firstDate: firstDate, lastDate: lastDate);
  }
}