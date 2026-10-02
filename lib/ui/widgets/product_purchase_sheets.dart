import 'package:flutter/material.dart';

import '../../data/api/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

Future<void> showProductOrderSheet(
  BuildContext context, {
  required String productId,
  required String productName,
  required String productImage,
  ApiService? apiService,
}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Под заказ',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close, color: AppColors.secondaryText))
              ]),
              const SizedBox(height: 8),
              const Text('Менеджер сообщит сроки поставки и актуальную цену.',
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.secondaryText)),
              const SizedBox(height: 20),
              ProductInquiryForm(
                  productId: productId,
                  productName: productName,
                  productImage: productImage,
                  apiService: apiService),
            ]),
      )),
    );

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

class ProductInquiryForm extends StatefulWidget {
  final String productId, productName;
  final String productImage;
  final ApiService? apiService;
  const ProductInquiryForm(
      {super.key,
      required this.productId,
      required this.productName,
      this.productImage = '',
      this.apiService});
  @override
  State<ProductInquiryForm> createState() => _ProductInquiryFormState();
}

class _ProductInquiryFormState extends State<ProductInquiryForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _comment = TextEditingController();
  bool _sending = false, _sent = false;
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
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await (widget.apiService ?? ApiService()).submitProductInquiry(
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
          DecoratedBox(
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  SizedBox(
                      width: 48,
                      height: 56,
                      child: widget.productImage.isEmpty
                          ? const Icon(Icons.image_outlined,
                              color: AppColors.secondaryText)
                          : CachedNetworkImage(
                              imageUrl: widget.productImage,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.image_outlined))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(widget.productName,
                          style: const TextStyle(fontSize: 14, height: 1.3))),
                ])),
          ),
          const SizedBox(height: 20),
          TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Ваше имя'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (_) =>
                  _name.text.trim().isEmpty ? 'Введите имя' : null,
              enabled: !_sending),
          const SizedBox(height: 12),
          TextFormField(
              controller: _phone,
              decoration: const InputDecoration(hintText: '+7 (___) ___-__-__'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              enabled: !_sending,
              validator: (_) => _digits.length == 10
                  ? null
                  : 'Введите 10 цифр номера после +7'),
          const SizedBox(height: 12),
          TextFormField(
              controller: _comment,
              decoration: const InputDecoration(
                  hintText: 'Комментарий (необязательно)'),
              maxLines: 3,
              enabled: !_sending),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text(_sending ? 'Отправляем…' : 'Заказать товар'))),
        ]));
  }
}
