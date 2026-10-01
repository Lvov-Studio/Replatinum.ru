import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/api/api_service.dart';

Future<void> showProductInformation(
        BuildContext context, String title, Widget content) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      content
                    ]))));

Future<void> callStore() async => launchUrl(Uri.parse('tel:+78612070304'));

class InstallmentCalculator extends StatefulWidget {
  final num price;
  const InstallmentCalculator({super.key, required this.price});
  @override
  State<InstallmentCalculator> createState() => _InstallmentCalculatorState();
}

class _InstallmentCalculatorState extends State<InstallmentCalculator> {
  int _months = 24;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(formatPrice(widget.price),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Срок рассрочки'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final term in const [3, 6, 9, 12, 18, 24])
            ChoiceChip(
                label: Text('$term мес.'),
                selected: _months == term,
                onSelected: (_) => setState(() => _months = term))
        ]),
        const SizedBox(height: 20),
        Text('${formatPrice((widget.price / _months).ceil())}/мес.',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text(
            'Рассрочка оформляется только в магазине Replatinum. Дистанционная подача заявки недоступна. Расчёт предварительный; условия уточните у менеджера.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
            onPressed: callStore,
            icon: const Icon(Icons.phone_outlined),
            label: const Text('Позвонить в магазин'))
      ]);
}

class ProductInquiryForm extends StatefulWidget {
  final String productId, productName;
  const ProductInquiryForm(
      {super.key, required this.productId, required this.productName});
  @override
  State<ProductInquiryForm> createState() => _ProductInquiryFormState();
}

class _ProductInquiryFormState extends State<ProductInquiryForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _comment = TextEditingController();
  bool _consent = false, _sending = false, _sent = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  String get _digits => _phone.text
      .replaceAll(RegExp(r'\D'), '')
      .replaceFirst(RegExp(r'^[78](?=\d{10}$)'), '');
  Future<void> _send() async {
    if (!_consent || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ApiService().submitProductInquiry(
          productId: widget.productId,
          productName: widget.productName,
          name: _name.text.trim(),
          phone: _digits,
          comment: _comment.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Заявка не отправлена. Попробуйте ещё раз или позвоните в магазин.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
              'Заявка отправлена. Менеджер свяжется с вами для уточнения цены и срока поставки.'));
    }
    return Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.productName),
          const SizedBox(height: 16),
          TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Имя'),
              textCapitalization: TextCapitalization.words,
              enabled: !_sending),
          const SizedBox(height: 12),
          TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                  labelText: 'Телефон', hintText: '+7 (___) ___-__-__'),
              keyboardType: TextInputType.phone,
              enabled: !_sending,
              validator: (_) => _digits.length == 10
                  ? null
                  : 'Введите 10 цифр номера после +7'),
          const SizedBox(height: 12),
          TextFormField(
              controller: _comment,
              decoration: const InputDecoration(labelText: 'Комментарий'),
              maxLines: 2,
              enabled: !_sending),
          const SizedBox(height: 8),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: _sending
                  ? null
                  : (v) => setState(() => _consent = v ?? false),
              title: const Text('Согласен на обработку персональных данных',
                  style: TextStyle(fontSize: 13))),
          TextButton(
              onPressed: () => launchUrl(
                  Uri.parse('https://replatinum.ru/privacy-policy/'),
                  mode: LaunchMode.externalApplication),
              child: const Text('Политика конфиденциальности')),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _sending || !_consent ? null : _send,
                  child: Text(_sending ? 'Отправляем…' : 'Отправить заявку'))),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: callStore,
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Позвонить в магазин'))
        ]));
  }
}
