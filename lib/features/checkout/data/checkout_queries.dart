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
    orderV2 { number token }
  }
}
''';

  /// `MagentoEgypt_PaymentGraphQl` resolver — create/return the gateway session
  /// for an already-placed order (docs/backend/payment-contract.md). One resolver
  /// serves both gateways. Until deployed this errors and the repository degrades
  /// to null (checkout shows "awaiting payment").
  static const String paymentSession = r'''
query PaymentSession(
  $orderNumber: String!
  $email: String
  $lastname: String
  $guestToken: String
) {
  paymentSession(
    order_number: $orderNumber
    email: $email
    lastname: $lastname
    guest_token: $guestToken
  ) {
    order_number
    method_code
    gateway
    status
    payment_id
    web_url
    publishable_key
    additional_data { key value }
  }
}
''';

  /// Switches the payment method on an already-placed order and returns a fresh
  /// session, so a guest/customer can retry payment with a different method
  /// without rebuilding the (consumed) cart. Same guest auth as `paymentSession`.
  /// docs/backend/payment-contract.md §①.
  static const String setOrderPaymentMethod = r'''
mutation SetOrderPaymentMethod(
  $orderNumber: String!
  $methodCode: String!
  $email: String
  $lastname: String
  $guestToken: String
) {
  setOrderPaymentMethod(
    input: {
      order_number: $orderNumber
      method_code: $methodCode
      email: $email
      lastname: $lastname
      guest_token: $guestToken
    }
  ) {
    order_number
    method_code
    gateway
    status
    payment_id
    web_url
    publishable_key
    additional_data { key value }
  }
}
''';

  /// Tabby eligibility + promo metadata (`tabbyConfig`), read from Magento config
  /// (enable flags + thresholds — never hardcoded). Eligibility/promo only;
  /// checkout availability still comes from cart available_payment_methods. Until
  /// deployed this errors and the repository degrades to null (promo hidden).
  static const String tabbyConfig = r'''
query TabbyConfig {
  tabbyConfig {
    enabled
    publishable_key
    merchant_code
    currency
    products {
      type
      method_code
      enabled
      min_amount
      max_amount
      promo_enabled
    }
  }
}
''';
}
