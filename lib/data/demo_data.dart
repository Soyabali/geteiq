import '../models/guest_entry.dart';
import '../models/invite.dart';
import '../models/month_report.dart';

/// Static stand-in data so the UI is explorable without a backend.
/// Swap these for API calls when the service layer lands.
class DemoData {
  const DemoData._();

  /// Builds a timestamp relative to *now* so the "Today / Tomorrow / Yesterday"
  /// labels in the guest lists stay correct whenever the app is opened.
  static DateTime _at(int addDays, int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + addDays, hour, minute);
  }

  /// Rows for the "Invite guest list" screen.
  static List<GuestEntry> get invitedGuests => [
    GuestEntry(
      name: 'Rahul Sharma',
      phone: '+91 98765 43210',
      scheduledAt: _at(0, 16, 30),
      department: 'HR',
      status: GuestStatus.expected,
    ),
    GuestEntry(
      name: 'Priya Mehta',
      phone: '+91 98111 22334',
      scheduledAt: _at(0, 11, 10),
      department: 'Sales',
      status: GuestStatus.checkedIn,
    ),
    GuestEntry(
      name: 'Amit Verma',
      phone: '+91 99001 11223',
      scheduledAt: _at(0, 18, 0),
      department: 'IT',
      status: GuestStatus.pending,
    ),
    GuestEntry(
      name: 'Neha Kapoor',
      phone: '+91 88776 65544',
      scheduledAt: _at(1, 10, 0),
      department: 'Admin',
      status: GuestStatus.expected,
    ),
  ];

  /// Rows for the "Invited by Guard" screen.
  static List<GuestEntry> get guardEntries => [
    GuestEntry(
      name: 'BlueDart Courier',
      phone: '+91 90000 12345',
      scheduledAt: _at(0, 9, 20),
      department: 'Gate 2',
      status: GuestStatus.checkedIn,
    ),
    GuestEntry(
      name: 'Rohit Singh',
      phone: '+91 98200 33445',
      scheduledAt: _at(0, 12, 45),
      department: 'Facility',
      status: GuestStatus.checkedIn,
    ),
    GuestEntry(
      name: 'Electrician',
      phone: '+91 91234 56780',
      scheduledAt: _at(0, 14, 5),
      department: 'Maintenance',
      status: GuestStatus.pending,
    ),
    GuestEntry(
      name: 'Anjali Rao',
      phone: '+91 99887 66554',
      scheduledAt: _at(0, 17, 30),
      department: 'Reception',
      status: GuestStatus.checkedOut,
    ),
  ];

  /// Rows for the "Yesterday guest list" screen.
  static List<GuestEntry> get yesterdayGuests => [
    GuestEntry(
      name: 'Vikram Nair',
      phone: '+91 98450 11220',
      scheduledAt: _at(-1, 10, 15),
      department: 'Finance',
      status: GuestStatus.checkedOut,
    ),
    GuestEntry(
      name: 'Sana Sheikh',
      phone: '+91 97400 55661',
      scheduledAt: _at(-1, 13, 0),
      department: 'HR',
      status: GuestStatus.checkedOut,
    ),
    GuestEntry(
      name: 'Deepak Joshi',
      phone: '+91 90090 88770',
      scheduledAt: _at(-1, 15, 40),
      department: 'Sales',
      status: GuestStatus.denied,
    ),
    GuestEntry(
      name: 'Meera Iyer',
      phone: '+91 93000 22114',
      scheduledAt: _at(-1, 18, 25),
      department: 'Admin',
      status: GuestStatus.checkedOut,
    ),
  ];

  static const flat = 'T 1 304';
  static const society = 'Charms Solitaire';
  static const address =
      'Kanawani Village, Indirapuram, Ghaziabad, Uttar Pradesh 201014';
  static const host = 'Jitender Wadhawan';

  /// Frequent entries shown as avatars on the dashboard.
  static const frequent = <Guest>[
    Guest(name: 'InstaHelp', phone: '+91 98110 22456'),
    Guest(name: 'Mamta Devi', phone: '+91 98110 33127'),
    Guest(name: 'Vandana', phone: '+91 99532 87410'),
    Guest(name: 'Ravi Yadav', phone: '+91 78149 45231'),
  ];

  /// Phone contacts offered on the Select Guests screen.
  static const contacts = <Guest>[
    Guest(name: 'Amit Sharma', phone: '+91 97111 07824'),
    Guest(name: 'Priya Nair', phone: '+91 81784 06887'),
    Guest(name: 'Rohit Verma', phone: '+91 78149 45231'),
    Guest(name: 'Sneha Kapoor', phone: '+91 82398 36709'),
    Guest(name: 'Imran Qureshi', phone: '+91 99104 55218'),
    Guest(name: 'Neha Gupta', phone: '+91 98730 11294'),
    Guest(name: 'Arjun Mehta', phone: '+91 90045 67312'),
    Guest(name: 'Kavya Reddy', phone: '+91 96543 20981'),
  ];

  /// Recently invited people.
  static const recent = <Guest>[
    Guest(name: 'Swiggy Delivery', phone: '+91 80088 12345'),
    Guest(name: 'Ravi Yadav', phone: '+91 78149 45231'),
    Guest(name: 'Amazon Courier', phone: '+91 80102 99887'),
  ];

  /// Payload for the "Month guest Report" screen.
  static const MonthReport monthReport = MonthReport(
    stats: [
      ReportStat(value: '142', label: 'Total'),
      ReportStat(value: '128', label: 'Checked in'),
      ReportStat(value: '18', label: 'Interviews'),
    ],
    rows: [
      ReportRow(
        title: 'Total Guests',
        subtitle: '142 entries',
        detail: 'Invites 98 · Guard 44',
        badgeLabel: 'July',
        badgeTone: ReportTone.info,
        breakdown: [
          ReportFact(label: 'Invites', value: '98'),
          ReportFact(label: 'Guard entries', value: '44'),
          ReportFact(label: 'Total', value: '142'),
        ],
      ),
      ReportRow(
        title: 'Checked In',
        subtitle: '128 completed',
        detail: 'Avg stay 1h 42m',
        badgeLabel: '90%',
        badgeTone: ReportTone.success,
        breakdown: [
          ReportFact(label: 'Completed', value: '128'),
          ReportFact(label: 'Average stay', value: '1h 42m'),
          ReportFact(label: 'Check-in rate', value: '90%'),
        ],
      ),
      ReportRow(
        title: 'Interviews',
        subtitle: '18 candidates',
        detail: 'Hired follow-ups: 3',
        badgeLabel: 'HR',
        badgeTone: ReportTone.warning,
        breakdown: [
          ReportFact(label: 'Candidates', value: '18'),
          ReportFact(label: 'Hired follow-ups', value: '3'),
          ReportFact(label: 'Department', value: 'HR'),
        ],
      ),
      ReportRow(
        title: 'Peak Day',
        subtitle: '22 Jul · 19 guests',
        detail: 'Mostly Sales + IT',
        badgeLabel: 'Busy',
        badgeTone: ReportTone.brand,
        breakdown: [
          ReportFact(label: 'Date', value: '22 Jul'),
          ReportFact(label: 'Guests', value: '19'),
          ReportFact(label: 'Top departments', value: 'Sales + IT'),
        ],
      ),
    ],
  );

  /// Unsplash imagery for the sponsored banner. Loaded through
  /// CachedNetworkImage with a gradient fallback, so a network failure
  /// degrades gracefully instead of breaking the layout.
  static const bannerImage =
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=900&q=70';
}
