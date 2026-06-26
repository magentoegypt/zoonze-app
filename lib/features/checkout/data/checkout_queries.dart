/// Hand-written Magento 2.4.8 checkout operations.
abstract final class CheckoutQueries {
  static const String setGuestEmail = r'''
mutation SetGuestEmail($cartId: String!, $email: String!) {
  setGuestEmailOnCart(input: { cart_id: $cartId, email: $email }) {
    cart { email }
  }
}
''';

  static const String setShippingAddress = r'''
mutation SetShippingAddress($cartId: String!, $address: CartAddressInput!) {
  setShippingAddressesOnCart(
    input: { cart_id: $cartId, shipping_addresses: [{ address: $address }] }
  ) {
    cart {
      shipping_addresses {
        available_shipping_methods {
          carrier_code
          method_code
          carrier_title
          method_title
          available
          error_message
          amount { value currency }
        }
      }
    }
  }
}
''';

  static const String setShippingMethod = r'''
mutation SetShippingMethod(
  $cartId: String!
  $carrier: String!
  $method: String!
) {
  setShippingMethodsOnCart(
    input: {
      cart_id: $cartId
      shipping_methods: [{ carrier_code: $carrier, method_code: $method }]
    }
  ) {
    cart {
      available_payment_methods { code title }
      prices {
        grand_total { value currency }
        subtotal_including_tax { value currency }
      }
    }
  }
}
''';

  static const String setBillingSameAsShipping = r'''
mutation SetBilling($cartId: String!) {
  setBillingAddressOnCart(
    input: {
      cart_id: $cartId
      billing_address: { same_as_shipping: true }
    }
  ) {
    cart {
      available_payment_methods { code title }
    }
  }
}
''';

  static const String setPaymentMethod = r'''
mutation SetPayment($cartId: String!, $code: String!) {
  setPaymentMethodOnCart(
    input: { cart_id: $cartId, payment_method: { code: $code } }
  ) {
    cart { selected_payment_method { code title } }
  }
}
''';

  static const String placeOrder = r'''
mutation PlaceOrder($cartId: String!) {
  placeOrder(input: { cart_id: $cartId }) {
    order { order_number }
  }
}
''';
}
