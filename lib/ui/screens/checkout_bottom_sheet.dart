import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/cart_provider.dart';
import '../widgets/cart_price_summary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../features/account/ui/russian_phone_formatter.dart';
import '../../features/account/ui/account_screen.dart';
import '../../features/account/ui/account_session.dart';
import '../../features/account/ui/account_controller.dart';
import '../../features/checkout/data/checkout_gateway.dart';
import '../../features/checkout/ui/checkout_controller.dart';

/// The original class name is retained; checkout now opens as a full page.
class CheckoutBottomSheet extends StatefulWidget {
  const CheckoutBottomSheet({super.key, this.gateway, this.loginController});
  final CheckoutGateway? gateway;
  final AccountController? loginController;
  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'first_name',
      'last_name',
      'phone',
      'email',
      'delivery_address',
      'apartment',
      'floor',
      'comment'
    ])
      key: TextEditingController()
  };
  late final CheckoutController _checkout;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _checkout = CheckoutController(
        context.read<CartProvider>(), widget.gateway ?? SiteCheckoutGateway());
    _initialize();
  }

  Future<void> _initialize({bool keepConsent = false}) async {
    await _checkout.initialize();
    if (!mounted) return;
    if (!keepConsent) _consent = _checkout.awaitingConfirmation;
    for (final entry in _fields.entries) {
      if (entry.value.text.isEmpty ||
          (entry.key == 'phone' &&
              entry.value.text.replaceAll(RegExp(r'\D'), '') == '7')) {
        entry.value.text = '${_checkout.profile[entry.key] ?? ''}';
      }
    }
    final phone = _fields['phone']!;
    phone.value = const RussianPhoneFormatter()
        .formatEditUpdate(TextEditingValue.empty, phone.value);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final session = context.read<AccountSession?>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) {
      final screen = AccountScreen(
          returnAfterLogin: true, controller: widget.loginController);
      return session == null
          ? screen
          : ChangeNotifierProvider.value(value: session, child: screen);
    }));
    if (mounted) await _initialize(keepConsent: true);
  }

  @override
  void dispose() {
    _checkout.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_checkout.awaitingConfirmation) {
      final invalid = _formKey.currentState!.validateGranularly();
      if (invalid.isNotEmpty) {
        await Scrollable.ensureVisible(invalid.first.context,
            duration: const Duration(milliseconds: 200), alignment: .2);
        return;
      }
    }
    final success = await _checkout.submit(
        {for (final entry in _fields.entries) entry.key: entry.value.text},
        consent: _consent);
    if (!mounted || !success) return;
    Navigator.of(context).pop(_checkout.orderId);
  }

  Widget _heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText)));

  Widget _section(List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border)),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children))));

  Widget _field(String name, String label,
          {int limit = 100,
          TextInputType? keyboard,
          String? Function(String?)? validator,
          int lines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            key: ValueKey('checkout-$name'),
            controller: _fields[name],
            enabled: !_checkout.submitting && !_checkout.awaitingConfirmation,
            keyboardType: keyboard,
            maxLength: limit,
            maxLines: lines,
            inputFormatters:
                name == 'phone' ? [const RussianPhoneFormatter()] : null,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.mainText),
            decoration: InputDecoration(
                labelText: label,
                counterText: '',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText),
                fillColor: AppColors.surfaceMuted),
            validator: validator,
            textInputAction:
                lines == 1 ? TextInputAction.next : TextInputAction.newline,
            autofillHints: switch (name) {
              'first_name' => [AutofillHints.givenName],
              'last_name' => [AutofillHints.familyName],
              'phone' => [AutofillHints.telephoneNumber],
              'email' => [AutofillHints.email],
              'delivery_address' => [AutofillHints.fullStreetAddress],
              _ => null,
            },
          ));

  Widget _stores(bool locked) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Выберите магазин самовывоза *'),
        for (final store in _checkout.stores)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
                color: _checkout.pickupStore == store['id']
                    ? AppColors.primaryAccent.withValues(alpha: .12)
                    : AppColors.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: _checkout.pickupStore == store['id']
                            ? AppColors.primaryAccent
                            : AppColors.border)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: locked || store['available'] != true
                      ? null
                      : () => _checkout.chooseStore('${store['id']}'),
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                _checkout.pickupStore == store['id']
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: store['available'] == true
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${store['name']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('${store['address']}'),
                                  if ('${store['notice'] ?? ''}'.isNotEmpty)
                                    Text('${store['notice']}',
                                        style: const TextStyle(
                                            color: AppColors.secondaryText)),
                                ])),
                          ])),
                )),
          ),
      ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_checkout, context.watch<CartProvider>()]),
        builder: (context, _) {
          final checkout = _checkout;
          final locked = checkout.submitting || checkout.awaitingConfirmation;
          return PopScope(
              canPop: !locked,
              child: Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                    title: const Text('Оформление заказа',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    centerTitle: true,
                    foregroundColor: AppColors.mainText,
                    backgroundColor: AppColors.surface,
                    automaticallyImplyLeading: !locked),
                body: SafeArea(
                    child: checkout.loading
                        ? const Center(child: CircularProgressIndicator())
                        : !checkout.ready
                            ? Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(checkout.error,
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 16),
                                          FilledButton(
                                              onPressed: _initialize,
                                              child: const Text('Повторить')),
                                        ])))
                            : Form(
                                key: _formKey,
                                child: AutofillGroup(
                                    child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 12, 12, 24),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (!checkout.authorized)
                                                _section([
                                                  _heading(
                                                      'Вход или регистрация'),
                                                  const Text(
                                                      'Войдите, чтобы отслеживать заказы в личном кабинете.',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .secondaryText)),
                                                  const SizedBox(height: 16),
                                                  ElevatedButton.icon(
                                                      onPressed: locked
                                                          ? null
                                                          : _login,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  AppColors
                                                                      .darkAccent,
                                                              foregroundColor:
                                                                  Colors.white),
                                                      icon: const Icon(
                                                          Icons.login,
                                                          size: 20),
                                                      label:
                                                          const Text('Войти')),
                                                ]),
                                              _section([
                                                _heading('Получатель'),
                                                _field('first_name', 'Имя *',
                                                    validator:
                                                        CheckoutController
                                                            .validateName),
                                                _field('last_name', 'Фамилия'),
                                                _field('phone', 'Телефон *',
                                                    limit: 18,
                                                    keyboard:
                                                        TextInputType.phone,
                                                    validator:
                                                        CheckoutController
                                                            .validatePhone),
                                                _field('email',
                                                    'Email (необязательно)',
                                                    limit: 254,
                                                    keyboard: TextInputType
                                                        .emailAddress,
                                                    validator:
                                                        CheckoutController
                                                            .validateEmail),
                                              ]),
                                              _section([
                                                _heading('Способ получения'),
                                                Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      for (final option in [
                                                        ('pickup', 'Самовывоз'),
                                                        (
                                                          'delivery',
                                                          'Доставка'
                                                        ),
                                                        ('express', 'Экспресс')
                                                      ])
                                                        ChoiceChip(
                                                            backgroundColor:
                                                                AppColors
                                                                    .surface,
                                                            side: BorderSide(
                                                                color: checkout.deliveryType == option.$1
                                                                    ? AppColors
                                                                        .darkAccent
                                                                    : AppColors
                                                                        .border),
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8),
                                                            label:
                                                                Text(option.$2),
                                                            selectedColor:
                                                                AppColors
                                                                    .darkAccent,
                                                            checkmarkColor:
                                                                Colors.white,
                                                            labelStyle: TextStyle(
                                                                color: checkout.deliveryType ==
                                                                        option.$1
                                                                    ? Colors.white
                                                                    : AppColors.mainText,
                                                                fontWeight: FontWeight.w400),
                                                            selected: checkout.deliveryType == option.$1,
                                                            onSelected: locked ? null : (_) => checkout.chooseDelivery(option.$1)),
                                                    ]),
                                                const SizedBox(height: 16),
                                                if (checkout.deliveryType ==
                                                    'pickup')
                                                  _stores(locked)
                                                else ...[
                                                  Text(checkout.deliveryType ==
                                                          'delivery'
                                                      ? 'Доставка по городу — ${formatPrice(checkout.cityDeliveryMinor / 100)}. Сумма добавлена к заказу.'
                                                      : 'Стоимость экспресс-доставки рассчитывается менеджером отдельно и пока не включена в итог.'),
                                                  const SizedBox(height: 16),
                                                  _field('delivery_address',
                                                      'Адрес доставки *',
                                                      limit: 500,
                                                      validator: (value) =>
                                                          (value ?? '')
                                                                  .trim()
                                                                  .isEmpty
                                                              ? 'Введите адрес доставки'
                                                              : null),
                                                  _field('apartment',
                                                      'Квартира / офис',
                                                      limit: 50),
                                                  _field('floor', 'Этаж',
                                                      limit: 50),
                                                ],
                                              ]),
                                              _section([
                                                _heading('Способ оплаты'),
                                                const ListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    leading: Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: AppColors
                                                            .primaryText),
                                                    title: Text(
                                                        'Наличными / При получении')),
                                                const Text(
                                                    'Оплата бонусами пока недоступна.',
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .secondaryText)),
                                              ]),
                                              _section([
                                                _heading(
                                                    'Комментарий к заказу'),
                                                _field('comment',
                                                    'Пожелания к заказу',
                                                    limit: 2000, lines: 3),
                                              ]),
                                              _section([
                                                _heading('Ваш заказ'),
                                                for (final item in checkout
                                                    .cart.selectedItems)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 12),
                                                      child: Text(
                                                          '${item.product.name}${item.variantLabel.isEmpty ? '' : '\n${item.variantLabel}'}\n${item.quantity} шт. · ${formatPrice(checkout.cart.lineTotalFor(item))}')),
                                                CartPriceSummary(
                                                    cart: checkout.cart),
                                                if (checkout.deliveryMinor > 0)
                                                  Text(
                                                      'Доставка: ${formatPrice(checkout.deliveryMinor / 100)}'),
                                                const SizedBox(height: 12),
                                                Text(
                                                    'Итого: ${formatPrice(checkout.totalMinor / 100)}',
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 16),
                                                CheckboxListTile(
                                                    dense: true,
                                                    visualDensity:
                                                        const VisualDensity(
                                                            horizontal: -4,
                                                            vertical: -4),
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    controlAffinity:
                                                        ListTileControlAffinity
                                                            .leading,
                                                    value: _consent,
                                                    onChanged: locked
                                                        ? null
                                                        : (value) => setState(
                                                            () => _consent =
                                                                value == true),
                                                    title: const Text(
                                                        'Согласен на обработку персональных данных для оформления заказа',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            height: 1.35,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w400))),
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton(
                                                        onPressed: () async {
                                                          final messenger =
                                                              ScaffoldMessenger
                                                                  .of(context);
                                                          try {
                                                            if (!await launchUrl(
                                                                Uri.parse(
                                                                    'https://replatinum.ru/privacy-policy/'),
                                                                mode: LaunchMode
                                                                    .externalApplication)) {
                                                              throw StateError(
                                                                  'Privacy policy unavailable');
                                                            }
                                                          } catch (_) {
                                                            if (mounted) {
                                                              messenger.showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'Не удалось открыть политику. Попробуйте позже.')));
                                                            }
                                                          }
                                                        },
                                                        child: const Text(
                                                            'Политика конфиденциальности',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .primaryText)))),
                                                if (checkout.error.isNotEmpty)
                                                  Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      child: Semantics(
                                                          liveRegion: true,
                                                          child: Text(
                                                              checkout.error,
                                                              style: const TextStyle(
                                                                  color: AppColors
                                                                      .error)))),
                                                ElevatedButton(
                                                    onPressed:
                                                        checkout.submitting
                                                            ? null
                                                            : _submit,
                                                    style: ElevatedButton.styleFrom(
                                                        minimumSize:
                                                            const Size.fromHeight(
                                                                48),
                                                        foregroundColor:
                                                            Colors.white,
                                                        backgroundColor:
                                                            AppColors
                                                                .darkAccent),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                vertical: 12),
                                                        child: checkout.submitting
                                                            ? const SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2))
                                                            : Text(checkout.awaitingConfirmation ? 'Проверить заказ' : 'Подтвердить заказ'))),
                                              ]),
                                            ]))))),
              ));
        },
      );
}
