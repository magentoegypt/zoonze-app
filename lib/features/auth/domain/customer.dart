/// The signed-in customer's profile basics.
class Customer {
  const Customer({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    firstName: (json['firstname'] as String?) ?? '',
    lastName: (json['lastname'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
  );
}
