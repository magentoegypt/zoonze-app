class CustomerAddress {
  const CustomerAddress({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.telephone,
    required this.street,
    required this.city,
    this.postcode = '',
    this.region = '',
    this.countryCode = 'AE',
    this.defaultShipping = false,
    this.defaultBilling = false,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String telephone;
  final String street;
  final String city;
  final String postcode;
  final String region;
  final String countryCode;
  final bool defaultShipping;
  final bool defaultBilling;

  String get fullName => '$firstName $lastName'.trim();

  String get summary => [
    street,
    city,
    postcode,
    countryCode,
  ].where((p) => p.isNotEmpty).join(', ');

  /// Magento `CustomerAddressInput`.
  Map<String, dynamic> toInput() => <String, dynamic>{
    'firstname': firstName,
    'lastname': lastName,
    'telephone': telephone,
    'street': [street],
    'city': city,
    if (postcode.isNotEmpty) 'postcode': postcode,
    'country_code': countryCode,
    if (region.isNotEmpty) 'region': <String, dynamic>{'region': region},
    'default_shipping': defaultShipping,
    'default_billing': defaultBilling,
  };
}
