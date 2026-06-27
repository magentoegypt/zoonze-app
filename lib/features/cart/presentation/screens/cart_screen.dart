import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/shell/marketing_footer.dart';
import '../../../../app/shell/zoonze_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/l10n.dart';
import '../../../checkout/payments/tabby_promo.dart';
import '../../domain/cart.dart';
import '../cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  CartController get _controller => ref.read(cartControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cartControllerProvider);

    return ZoonzeScaffold(
      currentTab: AppTab.cart,
      showSearch: false,
      body: _body(l10n, state),
    );
  }

  Widget _body(AppLocalizations l10n, CartState state) {
    if (state.isLoading && state.cart.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.cart.isEmpty) {
      final error = state.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is Failure
                    ? failureMessage(context, error)
                    : l10n.errorGeneric,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.refresh,
                child: Text(l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (state.cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceTint,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.cartEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.cartEmptyBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.cartContinueShopping),
              ),
            ],
          ),
        ),
      );
    }

    final cart = state.cart;
    final itemCount = cart.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cartHeading,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.cartItemCount(itemCount),
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        for (final item in cart.items)
          _CartItemTile(
            item: item,
            busy: state.isMutating,
            onChangeQty: (q) => _controller.setQuantity(item.uid, q),
            onRemove: () => _controller.removeItem(item.uid),
          ),
        const SizedBox(height: 8),
        _CouponSection(
          controller: _coupon,
          appliedCoupon: cart.totals.appliedCoupon,
          busy: state.isMutating,
          onApply: () async {
            if (_coupon.text.trim().isEmpty) return;
            try {
              await _controller.applyCoupon(_coupon.text.trim());
              _coupon.clear();
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.cartCouponError)));
              }
            }
          },
          onRemoveCoupon: _controller.removeCoupon,
        ),
        const Divider(height: 32),
        _TotalRow(
          label: l10n.cartSubtotal,
          value: cart.totals.subtotal?.formatted(),
        ),
        if (cart.totals.discount != null)
          _TotalRow(
            label: l10n.cartDiscount,
            value: '-${cart.totals.discount!.formatted()}',
          ),
        _TotalRow(
          label: l10n.cartTotal,
          value: cart.totals.grandTotal?.formatted(),
          emphasize: true,
        ),
        if (cart.totals.grandTotal != null)
          TabbyPromo(
            price: cart.totals.grandTotal!,
            padding: const EdgeInsets.only(top: 8),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.push(AppRoutes.checkout),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Text(
                cart.totals.grandTotal != null
                    ? '${l10n.cartSecureCheckout} · ${cart.totals.grandTotal!.formatted()}'
                    : l10n.cartSecureCheckout,
              ),
            ],
          ),
        ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const MarketingFooter(),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.busy,
    required this.onChangeQty,
    required this.onRemove,
  });

  final CartItem item;
  final bool busy;
  final ValueChanged<int> onChangeQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.imageUrl == null
                  ? Container(color: AppColors.surfaceTint)
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      // 72pt thumbnail — decode at display size, not full res.
                      memCacheWidth:
                          (72 * MediaQuery.devicePixelRatioOf(context)).round(),
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceTint),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceTint),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                for (final option in item.options)
                  Text(
                    option,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: busy ? null : () => onChangeQty(item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}'),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: busy ? null : () => onChangeQty(item.quantity + 1),
                    ),
                    const Spacer(),
                    if (item.rowTotal != null)
                      Text(
                        item.rowTotal!.formatted(),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.inkMuted),
            onPressed: busy ? null : onRemove,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkMuted.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16),
    ),
  );
}

class _CouponSection extends StatelessWidget {
  const _CouponSection({
    required this.controller,
    required this.appliedCoupon,
    required this.busy,
    required this.onApply,
    required this.onRemoveCoupon,
  });

  final TextEditingController controller;
  final String? appliedCoupon;
  final bool busy;
  final VoidCallback onApply;
  final VoidCallback onRemoveCoupon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (appliedCoupon != null) {
      return Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: AppColors.accentGold),
          const SizedBox(width: 8),
          Expanded(child: Text(appliedCoupon!)),
          TextButton(
            onPressed: busy ? null : onRemoveCoupon,
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.cartCouponHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: busy ? null : onApply,
          child: Text(l10n.cartApply),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, this.value, this.emphasize = false});

  final String label;
  final String? value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : const TextStyle(color: AppColors.inkMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value ?? '—', textDirection: TextDirection.ltr, style: style),
        ],
      ),
    );
  }
}
