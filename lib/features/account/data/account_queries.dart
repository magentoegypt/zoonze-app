/// Hand-written Magento 2.4.8 customer account operations (orders, addresses,
/// profile).
abstract final class AccountQueries {
  // scope: WEBSITE unifies orders across both store views (uae-en / uae-ar share
  // one website) — without it `orders` defaults to STORE and each language only
  // sees the orders placed under its own Store header.
  static const String orders = r'''
query CustomerOrders($pageSize: Int!, $currentPage: Int!) {
  customer {
    orders(pageSize: $pageSize, currentPage: $currentPage, scope: WEBSITE) {
      total_count
      page_info { current_page total_pages }
      items {
        number
        order_date
        status
        shipping_method
        carrier
        total {
          subtotal { value currency }
          total_shipping { value currency }
          grand_total { value currency }
        }
        items {
          product_name
          product_sku
          product_url_key
          quantity_ordered
          product_sale_price { value currency }
          product { image { url } }
        }
        payment_methods { name type }
        comments { message timestamp }
        shipping_address {
          firstname
          lastname
          street
          city
          region
          postcode
          telephone
        }
        billing_address {
          firstname
          lastname
          street
          city
          region
          postcode
          telephone
        }
        shipments {
          tracking { title number carrier }
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
      region { region region_code region_id }
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
