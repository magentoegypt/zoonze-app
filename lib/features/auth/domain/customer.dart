/// The signed-in customer's profile basics.
class Customer {
  const Customer({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.mobileNumber,
  });

  final String firstName;
  final String lastName;
  final String email;

  /// The verified `mobile_number` EAV attribute (set at registration; changed
  /// in-app via the OTP-gated Edit Profile flow). Null when not set.
  final String? mobileNumber;

  String get fullName => '$firstName $lastName'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    firstName: (json['firstname'] as String?) ?? '',
    lastName: (json['lastname'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    mobileNumber: _mobileFrom(json['custom_attributes']),
  );

  /// Extracts `mobile_number` from the `custom_attributes` list
  /// (`[{ code, value }]`), returning null when absent/empty.
  static String? _mobileFrom(dynamic customAttributes) {
    if (customAttributes is! List) return null;
    for (final a in customAttributes) {
      if (a is Map<String, dynamic> && a['code'] == 'mobile_number') {
        final value = a['value'] as String?;
        return (value != null && value.isNotEmpty) ? value : null;
      }
    }
    return null;
  }
}
