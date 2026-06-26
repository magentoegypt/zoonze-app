/// Hand-written Magento 2.4.8 customer account operations (orders, addresses,
/// profile).
abstract final class AccountQueries {
  static const String orders = r'''
query CustomerOrders {
  customer {
    orders(pageSize: 20, currentPage: 1) {
      items {
        number
        order_date
        status
        total {
          grand_total { value currency }
        }
        items {
          product_name
          quantity_ordered
          product_sale_price { value currency }
        }
      }
    }
  }
}
''';

  static const String addresses = r'''
query CustomerAddresses {
  customer {
    addresses {
      id
      firstname
      lastname
      telephone
      street
      city
      postcode
      region { region region_code }
      country_code
      default_shipping
      default_billing
    }
  }
}
''';

  static const String createAddress = r'''
mutation CreateAddress($input: CustomerAddressInput!) {
  createCustomerAddress(input: $input) { id }
}
''';

  static const String updateAddress = r'''
mutation UpdateAddress($id: Int!, $input: CustomerAddressInput!) {
  updateCustomerAddress(id: $id, input: $input) { id }
}
''';

  static const String deleteAddress = r'''
mutation DeleteAddress($id: Int!) {
  deleteCustomerAddress(id: $id)
}
''';

  static const String updateProfile = r'''
mutation UpdateProfile($input: CustomerUpdateInput!) {
  updateCustomerV2(input: $input) {
    customer { firstname lastname email }
  }
}
''';

  static const String changePassword = r'''
mutation ChangePassword($currentPassword: String!, $newPassword: String!) {
  changeCustomerPassword(
    currentPassword: $currentPassword
    newPassword: $newPassword
  ) {
    email
  }
}
''';
}
