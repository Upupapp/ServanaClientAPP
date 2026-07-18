import 'package:intl/intl.dart';

class DateTimeHelper {
  static String formatDateToTime(DateTime dateTime) {
    String formattedTime = DateFormat('hh:mm aa').format(dateTime);

    return formattedTime;
  }

  static String formatDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
