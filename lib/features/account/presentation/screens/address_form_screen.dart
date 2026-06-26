import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validation/validators.dart';
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
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _postcode;
  late final TextEditingController _region;
  late final TextEditingController _country;
  late bool _defaultShipping;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _firstName = TextEditingController(text: a?.firstName ?? '');
    _lastName = TextEditingController(text: a?.lastName ?? '');
    _phone = TextEditingController(text: a?.telephone ?? '');
    _street = TextEditingController(text: a?.street ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postcode = TextEditingController(text: a?.postcode ?? '');
    _region = TextEditingController(text: a?.region ?? '');
    _country = TextEditingController(text: a?.countryCode ?? 'AE');
    _defaultShipping = a?.defaultShipping ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _phone,
      _street,
      _city,
      _postcode,
      _region,
      _country,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final address = CustomerAddress(
      id: widget.initial?.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      telephone: _phone.text.trim(),
      street: _street.text.trim(),
      city: _city.text.trim(),
      postcode: _postcode.text.trim(),
      region: _region.text.trim(),
      countryCode: _country.text.trim().isEmpty
          ? 'AE'
          : _country.text.trim().toUpperCase(),
      defaultShipping: _defaultShipping,
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
              children: [
                _field(
                  _firstName,
                  l10n.fieldFirstName,
                  validator: (v) => Validators.required(context, v),
                ),
                _field(
                  _lastName,
                  l10n.fieldLastName,
                  validator: (v) => Validators.required(context, v),
                ),
                _field(
                  _phone,
                  l10n.fieldPhone,
                  keyboard: TextInputType.phone,
                  validator: (v) => Validators.required(context, v),
                ),
                _field(
                  _street,
                  l10n.fieldStreet,
                  validator: (v) => Validators.required(context, v),
                ),
                _field(
                  _city,
                  l10n.fieldCity,
                  validator: (v) => Validators.required(context, v),
                ),
                _field(_region, l10n.fieldRegion),
                _field(_postcode, l10n.fieldPostcode),
                _field(_country, l10n.fieldCountry),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _defaultShipping,
                  onChanged: (v) => setState(() => _defaultShipping = v),
                  title: Text(l10n.addressDefaultShipping),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.actionSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );
}
