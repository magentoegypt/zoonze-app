import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/auth/data/auth_repository.dart';
import 'package:zoonze_app/features/auth/presentation/auth_controller.dart';
import 'package:zoonze_app/features/cart/data/cart_repository.dart';
import 'package:zoonze_app/features/cart/presentation/cart_controller.dart';
import 'package:zoonze_app/features/checkout/data/checkout_repository.dart';
import 'package:zoonze_app/features/checkout/presentation/checkout_controller.dart';

import '../../support/fakes.dart';

ProviderContainer _container(FakeCheckoutRepository repo) {
  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore()),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
      checkoutRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  container.listen(cartControllerProvider, (_, __) {});
  container.listen(authControllerProvider, (_, __) {});
  container.listen(checkoutControllerProvider, (_, __) {});
  return container;
}

/// Seeds a guest cart so the checkout controller has a non-empty cart id.
Future<ProviderContainer> _seededContainer(FakeCheckoutRepository repo) async {
  final container = _container(repo);
  await container.read(cartControllerProvider.notifier).addToCart(sku: 'SKU1');
  return container;
}

const _address = <String, dynamic>{
  'firstname': 'Layla',
  'lastname': 'Hassan',
  'telephone': '0500000000',
  'street': ['1 Marina Walk'],
  'city': 'Dubai',
  'country_code': 'AE',
};

void main() {
  group('CheckoutController', () {
    test('walks address → shipping → payment → place order', () async {
      final repo = FakeCheckoutRepository();
      final container = await _seededContainer(repo);
      final checkout = container.read(checkoutControllerProvider.notifier);

      final addressOk = await checkout.submitAddress(
        email: 'guest@example.com',
        address: _address,
        isGuest: true,
      );
      expect(addressOk, isTrue);
      var state = container.read(checkoutControllerProvider);
      expect(state.addressDone, isTrue);
      expect(state.shippingMethods, hasLength(1));
      expect(repo.guestEmail, 'guest@example.com');

      final shippingOk = await checkout.selectShipping(
        state.shippingMethods.first,
      );
      expect(shippingOk, isTrue);
      state = container.read(checkoutControllerProvider);
      expect(state.shippingDone, isTrue);
      expect(state.grandTotal?.amount, 219);
      expect(state.paymentMethods, hasLength(2));
      expect(repo.selectedShippingMethod, 'flatrate|flatrate');

      final paymentOk = await checkout.selectPayment(state.paymentMethods.last);
      expect(paymentOk, isTrue);
      state = container.read(checkoutControllerProvider);
      expect(state.paymentDone, isTrue);
      expect(repo.selectedPaymentCode, 'tabby');

      final result = await checkout.placeOrder();
      expect(result, isNotNull);
      expect(result!.orderNumber, '000000123');
      expect(container.read(checkoutControllerProvider).isBusy, isFalse);
    });

    test(
      'resetPayment clears the selection but keeps the shipping step',
      () async {
        final repo = FakeCheckoutRepository();
        final container = await _seededContainer(repo);
        final checkout = container.read(checkoutControllerProvider.notifier);

        await checkout.submitAddress(
          email: 'guest@example.com',
          address: _address,
          isGuest: true,
        );
        var state = container.read(checkoutControllerProvider);
        await checkout.selectShipping(state.shippingMethods.first);
        state = container.read(checkoutControllerProvider);
        await checkout.selectPayment(state.paymentMethods.first);
        expect(container.read(checkoutControllerProvider).paymentDone, isTrue);

        // A redirect reject/cancel bounces the user back to method selection.
        checkout.resetPayment();
        state = container.read(checkoutControllerProvider);
        expect(state.paymentDone, isFalse);
        expect(state.selectedPayment, isNull);
        expect(state.shippingDone, isTrue);
        expect(state.paymentMethods, hasLength(2));
      },
    );

    test(
      'does not set the guest email for an authenticated customer',
      () async {
        final repo = FakeCheckoutRepository();
        final container = await _seededContainer(repo);
        final checkout = container.read(checkoutControllerProvider.notifier);

        await checkout.submitAddress(
          email: 'layla@example.com',
          address: _address,
          isGuest: false,
        );

        expect(repo.guestEmail, isNull);
        expect(repo.lastAddress, _address);
      },
    );

    test('returns false and records the error when a step fails', () async {
      final repo = FakeCheckoutRepository(fail: true);
      final container = await _seededContainer(repo);
      final checkout = container.read(checkoutControllerProvider.notifier);

      final ok = await checkout.submitAddress(
        email: 'guest@example.com',
        address: _address,
        isGuest: true,
      );

      expect(ok, isFalse);
      final state = container.read(checkoutControllerProvider);
      expect(state.error, isNotNull);
      expect(state.isBusy, isFalse);
      expect(state.addressDone, isFalse);
    });

    test('submitAddress is a no-op without a cart', () async {
      // No addToCart → cart id stays empty → checkout cannot proceed.
      final repo = FakeCheckoutRepository();
      final container = _container(repo);
      final checkout = container.read(checkoutControllerProvider.notifier);

      final ok = await checkout.submitAddress(
        email: 'guest@example.com',
        address: _address,
        isGuest: true,
      );

      expect(ok, isFalse);
      expect(repo.lastAddress, isNull);
    });
  });
}
