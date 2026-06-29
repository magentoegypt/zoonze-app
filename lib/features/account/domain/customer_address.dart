class CustomerAddress {
  const CustomerAddress({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.telephone,
    required this.street,
    required this.city,
    this.apartment = '',
    this.postcode = '',
    this.region = '',
    this.regionId,
    this.countryCode = 'AE',
    this.defaultShipping = false,
    this.defaultBilling = false,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String telephone;

  /// Street line — Magento `street[0]`.
  final String street;

  /// Apartment / floor — optional Magento `street[1]`.
  final String apartment;

  /// Locality / district (Magento `city`), shown as "Area" in the form.
  final String city;
  final String postcode;

  /// Free-text region label (fallback / display).
  final String region;

  /// Magento system region id (a UAE emirate). Required for AE addresses.
  final int? regionId;
  final String countryCode;
  final bool defaultShipping;
  final bool defaultBilling;

  String get fullName => '$firstName $lastName'.trim();

  String get summary => [
    street,
    apartment,
    city,
    region,
    countryCode,
  ].where((p) => p.isNotEmpty).join(', ');

  /// Magento `CustomerAddressInput`. AE has system regions, so a valid
  /// `region_id` is sent (nested under `region`) rather than free-text.
  Map<String, dynamic> toInput() => <String, dynamic>{
    'firstname': firstName,
    'lastname': lastName,
    'telephone': telephone,
    'street': [street, if (apartment.isNotEmpty) apartment],
    'city': city,
    if (postcode.isNotEmpty) 'postcode': postcode,
    'country_code': countryCode,
    if (regionId != null)
      'region': <String, dynamic>{'region_id': regionId}
    else if (region.isNotEmpty)
      'region': <String, dynamic>{'region': region},
    'default_shipping': defaultShipping,
    'default_billing': defaultBilling,
  };
}
