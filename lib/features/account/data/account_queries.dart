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
          discounts { amount { value currency } label }
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
      custom_attributesV2(attributeCodes: ["address_label"]) {
        code
        ... on AttributeSelectedOptions {
          selected_options { label value }
        }
      }
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

  /// Sets the `mobile_number` custom attribute. Guarded app-side by the WhatsApp
  /// OTP flow (the module has no dedicated change-mobile OTP endpoint; the number
  /// is verified via the registration OTP before this runs).
  static const String updateMobile = r'''
mutation UpdateMobile($value: String!) {
  updateCustomerV2(
    input: { custom_attributes: [{ attribute_code: "mobile_number", value: $value }] }
  ) {
    customer { firstname }
  }
}
''';

  /// Uploads/replaces the signed-in customer's avatar (base64 jpg/png/webp).
  /// MagentoEgypt_PaymentGraphQl; requires the customer bearer token.
  static const String uploadAvatar = r'''
mutation UploadAvatar($file: String!) {
  uploadCustomerAvatar(input: { base64_encoded_file: $file }) { url }
}
''';

  static const String deleteAvatar = r'''
mutation DeleteAvatar {
  deleteCustomerAvatar { url }
}
''';

  /// Discovers the `address_label` select options (Home/Office/Other → their
  /// option ids) so the "Save as" chips map to ids without hardcoding. Labels
  /// are store-scoped.
  static const String addressLabelMetadata = r'''
query AddressLabelMeta {
  customAttributeMetadataV2(
    attributes: [{ attribute_code: "address_label", entity_type: "customer_address" }]
  ) {
    items {
      code
      options { label value }
    }
  }
}
''';
}
