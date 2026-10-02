import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/api/api_service.dart';
import '../../providers/credit_inquiry_controller.dart';

Future<void> showProductCreditSheet(
  BuildContext context, {
  required String productId,
  required String productName,
  required String productUrl,
  required num price,
  ApiService? apiService,
}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 560),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ProductCreditSheet(
          productId: productId,
          productName: productName,
          productUrl: productUrl,
          price: price,
          apiService: apiService),
    );

class ProductCreditSheet extends StatefulWidget {
  const ProductCreditSheet(
      {super.key,
      required this.productId,
      required this.productName,
      required this.productUrl,
      required this.price,
      this.apiService});
  final String productId, productName, productUrl;
  final num price;
  final ApiService? apiService;
  @override
  State<ProductCreditSheet> createState() => _ProductCreditSheetState();
}

class _ProductCreditSheetState extends State<ProductCreditSheet> {
  late final CreditInquiryController _controller = CreditInquiryController(
      productId: widget.productId,
      productName: widget.productName,
      productUrl: widget.productUrl,
      price: widget.price,
      api: widget.apiService);
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  bool _details = false;
  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Widget _button(String text, VoidCallback? onPressed) => SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primaryAccent,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: Text(text, textAlign: TextAlign.center),
      ));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        return PopScope(
            canPop: !c.sending,
            child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ColoredBox(
                          color: AppColors.darkAccent,
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 12, 20),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Expanded(
                                          child: Text('Рассрочка и кредит',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      IconButton(
                                          tooltip: 'Закрыть',
                                          onPressed: c.sending
                                              ? null
                                              : () =>
                                                  Navigator.of(context).pop(),
                                          icon: const Icon(Icons.close,
                                              color: Colors.white)),
                                    ]),
                                    Text(widget.productName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            height: 1.3,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 12),
                                    Text(formatPrice(widget.price),
                                        style: const TextStyle(
                                            color: AppColors.primaryAccent,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800)),
                                  ]))),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: c.sent
                              ? _success()
                              : _details
                                  ? _application(c)
                                  : _calculator(c)),
                    ])));
      });

  Widget _calculator(CreditInquiryController c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Выберите срок рассрочки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 310 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3
              ? 2
              : 3;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final term in CreditInquiryController.terms)
              SizedBox(
                  width: width,
                  child: Semantics(
                      selected: c.months == term,
                      child: OutlinedButton(
                          onPressed: () => c.select(term),
                          style: OutlinedButton.styleFrom(
                              backgroundColor: c.months == term
                                  ? const Color(0xFFF0F9E8)
                                  : Colors.white,
                              foregroundColor: AppColors.mainText,
                              side: BorderSide(
                                  color: c.months == term
                                      ? AppColors.primaryText
                                      : AppColors.border,
                                  width: c.months == term ? 2 : 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Column(children: [
                            Text('$term мес.',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('от ${formatPrice(c.payment(term))}/мес.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText)),
                          ])))),
          ]);
        }),
        if (c.months != null) ...[
          const SizedBox(height: 20),
          const Text('Ежемесячный платёж', style: TextStyle(fontSize: 13)),
          Text('${formatPrice(c.payment(c.months!))}/мес.',
              style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
        ],
        const SizedBox(height: 20),
        const Text(
            'Расчёт предварительный, по цене магазина. Точные условия определяет банк.',
            style: TextStyle(
                fontSize: 12, height: 1.5, color: AppColors.secondaryText)),
        const SizedBox(height: 16),
        const Text(
            'Рассрочка оформляется только в магазине Replatinum. Кредит можно оформить дистанционно. После заявки менеджер свяжется с вами и поможет с оформлением.',
            style: TextStyle(fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        _button('Оформить заявку',
            c.months == null ? null : () => setState(() => _details = true)),
      ]);

  Widget _application(CreditInquiryController c) => Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed:
                    c.sending ? null : () => setState(() => _details = false),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Изменить срок'))),
        const Text('Ваши данные',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${c.months} мес. · от ${formatPrice(c.payment(c.months!))}/мес.',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text(
            'Данные нужны кредитному специалисту для предварительной заявки. Менеджер Replatinum уточнит условия и дальнейшие шаги.',
            style: TextStyle(fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        TextFormField(
            controller: _name,
            enabled: !c.sending,
            decoration: const InputDecoration(
                labelText: 'Имя', hintText: 'Как к вам обращаться'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName]),
        const SizedBox(height: 12),
        TextFormField(
            controller: _phone,
            enabled: !c.sending,
            decoration: const InputDecoration(
                labelText: 'Телефон', hintText: '+7 (___) ___-__-__'),
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (value) =>
                CreditInquiryController.normalizePhone(value ?? '').length == 10
                    ? null
                    : 'Введите российский номер телефона'),
        if (c.error != null) ...[
          const SizedBox(height: 16),
          Text(c.error!,
              style: const TextStyle(color: AppColors.error, height: 1.4)),
        ],
        const SizedBox(height: 24),
        _button(
            c.sending ? 'Отправляем…' : 'Отправить заявку',
            c.sending
                ? null
                : () {
                    if (!_form.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    c.submit(name: _name.text, phone: _phone.text);
                  }),
      ]));

  Widget _success() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.check_circle_outline,
            size: 48, color: AppColors.primaryText),
        const SizedBox(height: 16),
        const Text('Заявка принята',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text(
            'Менеджер свяжется с вами для уточнения условий и дальнейшего оформления.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5)),
        const SizedBox(height: 24),
        _button('Готово', () => Navigator.of(context).pop()),
      ]);
}
