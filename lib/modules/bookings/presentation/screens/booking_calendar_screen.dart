import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingCalendarScreen extends StatefulWidget {
  static String routeName = "Calendar";
  static String route = "/Calendar";
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final store = dpLocator<HomeStore>();
  final _dateFormat = DateFormat('EEE MMM d, yyyy h:mm a');
  final _monthFormat = DateFormat('MMMM yyyy');
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => store.loadBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Calendar",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flexible + scrollable, not a bare child. The cells size
              // themselves from the text scale (see the grid delegate), so at
              // 2.0 the calendar is legitimately taller than a 320x568 handset
              // can spare once the schedule below it takes its share. Given a
              // bare slot it overflowed the body Column by 75px; given this it
              // simply scrolls, and the schedule list keeps its Expanded.
              Flexible(
                child: SingleChildScrollView(child: _buildCalendar()),
              ),
              const SizedBox(height: 12),
              Text(
                "Schedule",
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ColorPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Observer(
                  builder: (context) {
                    final bookings = store.bookings.toList()
                      ..sort(
                          (a, b) => a.scheduleDate.compareTo(b.scheduleDate));
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          "No bookings yet",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.secondaryText.withOpacity(.7),
                          ),
                        ),
                      );
                    }
                    final selectedBookings = bookings
                        .where((b) =>
                            DateUtils.isSameDay(b.scheduleDate, _selectedDate))
                        .toList();
                    return RefreshIndicator(
                      onRefresh: () => store.loadBookings(),
                      child: selectedBookings.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 24),
                                Center(
                                  child: Text(
                                    "No bookings on this date",
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: ColorPalette.secondaryText
                                          .withOpacity(.7),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: selectedBookings.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final b = selectedBookings[i];
                                return InkWell(
                                  // Opens the repository-backed booking
                                  // detail, not `JobOrderSummaryScreen`.
                                  //
                                  // That screen reads the merchant/job-order
                                  // surface of `Backend`, and in a release
                                  // build every method of it is a stub:
                                  // `HttpBackend.getMerchantJoDetails` returns
                                  // null, `getJobOrderItems` and
                                  // `getJobOrderEmployees` return empty lists.
                                  // Measured against that composition, tapping
                                  // a REAL booking showed a fabricated summary
                                  // — status "ACCEPTED" regardless of the
                                  // booking's actual status, today's date as
                                  // the schedule, no services, "Distance From
                                  // Office: null km", and a total of PHP 0.00.
                                  //
                                  // The list this calendar draws is real (it
                                  // comes from `GET /api/users/:id/bookings`
                                  // through HomeStore); only the destination
                                  // was not. `BookingDetailScreen` reads the
                                  // same booking through `BookingRepository`
                                  // and shows what the server actually holds.
                                  //
                                  // The job-order screens and their routes are
                                  // left in place for the release that builds
                                  // that surface — as Rewards and Favourites
                                  // were — but the affordance is withdrawn.
                                  onTap: () {
                                    context.pushNamed(
                                      BookingDetailScreen.routeName,
                                      pathParameters: {
                                        'bookingId': b.jobOrderID,
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.secondaryBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: ColorPalette.border(.55)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: ColorPalette.primaryColor
                                                .withOpacity(.12),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            color:
                                                ColorPalette.primaryColorDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.merchantName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: FontPalette
                                                      .primaryFontFamily,
                                                  fontWeight: FontWeight.w700,
                                                  color: ColorPalette
                                                      .secondaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${b.jobOrderNumber} • ${_dateFormat.format(b.scheduleDate)}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: FontPalette
                                                      .primaryFontFamily,
                                                  color: ColorPalette
                                                      .secondaryText
                                                      .withOpacity(.7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                b.jobOrderStatusToString,
                                                style: TextStyle(
                                                  fontFamily: FontPalette
                                                      .primaryFontFamily,
                                                  color: ColorPalette
                                                      .primaryColorDark,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right,
                                            color: ColorPalette.secondaryText
                                                .withOpacity(.5)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Observer(
      builder: (context) {
        final bookings = store.bookings.toList();
        final countByDay = <DateTime, int>{};
        for (final b in bookings) {
          final day = DateUtils.dateOnly(b.scheduleDate);
          countByDay[day] = (countByDay[day] ?? 0) + 1;
        }

        final days = _visibleDaysForMonth(_focusedMonth);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorPalette.border(.55)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                            _focusedMonth.year, _focusedMonth.month - 1);
                      });
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      color: ColorPalette.secondaryText.withOpacity(.7),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _monthFormat.format(_focusedMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                            _focusedMonth.year, _focusedMonth.month + 1);
                      });
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      color: ColorPalette.secondaryText.withOpacity(.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildWeekdayHeader(),
              const SizedBox(height: 4),
              GridView.builder(
                itemCount: days.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  // Without this the delegate defaults to a childAspectRatio of
                  // 1.0 — square cells, roughly 38px across on a 320px handset
                  // — so the cell height never grew with the text inside it.
                  // At text scale 1.3 EVERY day cell overflowed by 14px, and
                  // there are 27 to 43 of them on screen at once. In a release
                  // build that is silent clipping of the date itself.
                  //
                  // Scaling the extent rather than shrinking the text keeps the
                  // day numbers legible at the accessibility sizes this app
                  // says it supports.
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(44),
                ),
                itemBuilder: (context, i) {
                  final day = days[i];
                  final isCurrentMonth = day.month == _focusedMonth.month;
                  final isSelected = DateUtils.isSameDay(day, _selectedDate);
                  final count = countByDay[DateUtils.dateOnly(day)] ?? 0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateUtils.dateOnly(day);
                        _focusedMonth = DateTime(day.year, day.month);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorPalette.primaryColorDark
                            : ColorPalette.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? ColorPalette.primaryColorDark
                              : ColorPalette.border(.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${day.day}",
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isSelected
                                  ? ColorPalette.primaryText
                                  : isCurrentMonth
                                      ? ColorPalette.secondaryText
                                      : ColorPalette.secondaryText
                                          .withOpacity(.35),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorPalette.primaryText.withOpacity(.2)
                                    : ColorPalette.primaryColor
                                        .withOpacity(.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$count",
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? ColorPalette.primaryText
                                      : ColorPalette.primaryColorDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map(
            (d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.secondaryText.withOpacity(.6),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<DateTime> _visibleDaysForMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysBefore = firstOfMonth.weekday - DateTime.monday;
    final start = firstOfMonth.subtract(Duration(days: daysBefore));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }
}
