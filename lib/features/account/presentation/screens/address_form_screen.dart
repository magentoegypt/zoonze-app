import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/address/regions.dart';
import '../../../../core/widgets/address_form.dart';
import '../../../../l10n/l10n.dart';
import '../../data/account_repository.dart';
import '../../domain/customer_address.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.initial});

  final CustomerAddress? initial;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AddressFormController _address;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _address = AddressFormController(
      fullName: a?.fullName ?? '',
      phone: a?.telephone ?? '',
      area: a?.city ?? '',
      street: a?.street ?? '',
      apartment: a?.apartment ?? '',
      region: a?.region ?? '',
      regionId: a?.regionId,
      isDefault: a?.defaultShipping ?? false,
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final name = _address.splitName();
    final address = CustomerAddress(
      id: widget.initial?.id,
      firstName: name.first,
      lastName: name.last,
      telephone: _address.phone.text.trim(),
      street: _address.street.text.trim(),
      apartment: _address.apartment.text.trim(),
      city: _address.area.text.trim(),
      region: _address.region.text.trim(),
      regionId: _address.regionId.value,
      countryCode: addressCountryCode,
      defaultShipping: _address.isDefault.value,
    );
    try {
      final repo = ref.read(accountRepositoryProvider);
      final id = widget.initial?.id;
      if (id != null) {
        await repo.updateAddress(id, address);
      } else {
        await repo.createAddress(address);
      }
      ref.invalidate(addressesProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? l10n.addressEdit : l10n.addressAdd)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddressForm(controller: _address),
                const SizedBox(height: 16),
                // Set as default address (Figma 64:92) — label + burgundy toggle.
                ValueListenableBuilder<bool>(
                  valueListenable: _address.isDefault,
                  builder: (context, value, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.addressDefaultShipping,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkHeading,
                        ),
                      ),
                      Switch(
                        value: value,
                        onChanged: (v) => _address.isDefault.value = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderDefault,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.addressSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
