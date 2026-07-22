import '../models/invite.dart';

/// Static stand-in data so the UI is explorable without a backend.
/// Swap these for API calls when the service layer lands.
class DemoData {
  const DemoData._();

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

  /// Unsplash imagery for the sponsored banner. Loaded through
  /// CachedNetworkImage with a gradient fallback, so a network failure
  /// degrades gracefully instead of breaking the layout.
  static const bannerImage =
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=900&q=70';
}
