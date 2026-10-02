import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../ui/screens/info_screens.dart';
import 'account_controller.dart';
import 'account_menu_tile.dart';

class AccountAddressScreen extends StatefulWidget {
  const AccountAddressScreen({super.key, required this.account});
  final AccountController account;
  @override
  State<AccountAddressScreen> createState() => _AccountAddressScreenState();
}

class _AccountAddressScreenState extends State<AccountAddressScreen> {
  final city = TextEditingController(), street = TextEditingController();
  bool loaded = false, saved = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    await widget.account.loadAddress();
    if (!mounted ||
        widget.account.address == null ||
        widget.account.error.isNotEmpty) {
      return;
    }
    city.text = '${widget.account.address!['city'] ?? ''}';
    street.text = '${widget.account.address!['street'] ?? ''}';
    setState(() => loaded = true);
  }

  @override
  void dispose() {
    city.dispose();
    street.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.account,
      builder: (context, _) {
        final account = widget.account;
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                backgroundColor: Colors.white,
                title: const Text('Адрес доставки')),
            body: account.step != AccountStep.account
                ? const AccountSessionExpired()
                : ListView(padding: const EdgeInsets.all(20), children: [
                    const Text(
                        'Сохранённый адрес общий с сайтом. При оформлении заказа проверьте способ и адрес доставки.',
                        style: TextStyle(
                            color: AppColors.secondaryText, height: 1.5)),
                    const SizedBox(height: 24),
                    AccountSectionCard(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                      controller: city,
                                      enabled: loaded && !account.busy,
                                      maxLength: 100,
                                      decoration:
                                          accountFieldDecoration('Город')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: street,
                                      enabled: loaded && !account.busy,
                                      maxLength: 500,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: accountFieldDecoration(
                                          'Улица, дом, квартира')),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                      onPressed: !loaded || account.busy
                                          ? null
                                          : () async {
                                              setState(() => saved = false);
                                              await account.saveAddress(
                                                  city.text, street.text);
                                              if (mounted &&
                                                  account.error.isEmpty &&
                                                  account.step ==
                                                      AccountStep.account) {
                                                setState(() => saved = true);
                                              }
                                            },
                                      child: Text(account.busy
                                          ? 'Сохраняем…'
                                          : 'Сохранить адрес')),
                                ]))),
                    if (saved)
                      const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text('Адрес сохранён')),
                    if (account.busy && !loaded)
                      const Center(child: CircularProgressIndicator()),
                    if (account.error.isNotEmpty) ...[
                      Text(account.error),
                      if (!loaded)
                        TextButton(
                            onPressed: account.busy ? null : _load,
                            child: const Text('Повторить'))
                    ],
                  ]));
      });
}

class AccountSessionExpired extends StatelessWidget {
  const AccountSessionExpired({super.key});
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Сессия истекла. Вернитесь и войдите снова.')));
}

class AccountOrderDetailScreen extends StatefulWidget {
  const AccountOrderDetailScreen(
      {super.key, required this.account, required this.id});
  final AccountController account;
  final String id;
  @override
  State<AccountOrderDetailScreen> createState() =>
      _AccountOrderDetailScreenState();
}

class _AccountOrderDetailScreenState extends State<AccountOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.account.loadOrderDetail(widget.id);
    });
  }

  String _money(dynamic value, dynamic currency) =>
      currency == 'RUB' ? formatPrice(value as num) : '$value $currency';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.account,
      builder: (context, _) {
        final account = widget.account, order = widget.account.orderDetail;
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                backgroundColor: Colors.white,
                title: const Text('Детали заказа')),
            body: account.step != AccountStep.account
                ? const AccountSessionExpired()
                : RefreshIndicator(
                    onRefresh: () => account.loadOrderDetail(widget.id),
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (account.busy)
                            const Center(child: CircularProgressIndicator()),
                          if (account.error.isNotEmpty) ...[
                            Text(account.error),
                            TextButton(
                                onPressed: account.busy
                                    ? null
                                    : () => account.loadOrderDetail(widget.id),
                                child: const Text('Повторить'))
                          ],
                          if (order != null && order['id'] == widget.id) ...[
                            Text('Заказ № ${order['number']}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('${order['date']}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText)),
                            const SizedBox(height: 16),
                            Text('${order['status']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(order['paid'] == true
                                ? 'Оплачен'
                                : 'Ожидает оплаты'),
                            const SizedBox(height: 24),
                            const Text('Товары',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            for (final item in order['items'] as List? ?? [])
                              Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: AccountSectionCard(
                                      child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('${item['name']}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    '${item['quantity']} шт. × ${_money(item['price'], item['currency'])}',
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .secondaryText)),
                                              ])))),
                            const SizedBox(height: 16),
                            Text(
                                'Доставка: ${_money(order['delivery_price'], order['currency'])}'),
                            for (final field
                                in order['delivery'] as List? ?? [])
                              Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                      '${field['name']}: ${field['value']}')),
                            if ('${order['comment'] ?? ''}'.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child:
                                      Text('Комментарий: ${order['comment']}')),
                            const SizedBox(height: 24),
                            Text(
                                'Итого: ${_money(order['price'], order['currency'])}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccountHelpScreen())),
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Вопрос по заказу')),
                            const Text(
                                'Для изменения, отмены или уточнения оплаты сообщите поддержке номер заказа.',
                                style: TextStyle(
                                    color: AppColors.secondaryText,
                                    height: 1.5)),
                          ],
                        ])));
      });
}

class AccountHelpScreen extends StatelessWidget {
  const AccountHelpScreen({super.key});
  Future<void> _contact(BuildContext context, String url) async {
    final success =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Не удалось открыть. Попробуйте другой способ связи.')));
    }
  }

  static const _questions = [
    (
      'Как отследить заказ?',
      'Откройте «Мои заказы» и выберите покупку. В деталях показан текущий статус. Дополнительную информацию уточните у сотрудников магазина.'
    ),
    (
      'Как вернуть или обменять товар?',
      'Свяжитесь с поддержкой и сообщите номер заказа. Сотрудник уточнит условия для вашего товара.'
    ),
    (
      'Каковы сроки доставки?',
      'Срок зависит от товара и адреса. Уточните его у сотрудников магазина.'
    ),
    (
      'Как изменить или отменить заказ?',
      'Свяжитесь с нами и сообщите номер заказа. Сотрудник проверит статус и подскажет доступные действия.'
    ),
    (
      'Как оформить заказ для организации?',
      'Обратитесь в поддержку, чтобы уточнить условия и необходимые документы.'
    ),
  ];
  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Помощь'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.mainText),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            const Text('Поддержка Replatinum',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Ежедневно с 10:00 до 22:00. При обращении по покупке укажите номер заказа.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.secondaryText, height: 1.5)),
            const SizedBox(height: 20),
            AccountSectionCard(
                child: Column(children: [
              AccountMenuTile(
                  icon: Icons.phone_outlined,
                  title: '+7 (861) 207-03-04',
                  onTap: () => _contact(context, 'tel:+78612070304')),
              const AccountMenuDivider(),
              AccountMenuTile(
                  icon: Icons.send_outlined,
                  title: 'Написать в Telegram',
                  subtitle: '@replatinum',
                  onTap: () => _contact(context, 'https://t.me/replatinum')),
              const AccountMenuDivider(),
              AccountMenuTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Написать в Max',
                  onTap: () => _contact(context,
                      'https://max.ru/u/f9LHodD0cOKi40DNGf61_IA7YT964RuOFjJme10GlahfqYvGoz26WtdBpTs')),
              const AccountMenuDivider(),
              AccountMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Контакты магазинов',
                  onTap: () => _open(context, const ContactsScreen())),
            ])),
            const SizedBox(height: 28),
            const Text('Частые вопросы',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AccountSectionCard(
                child: Column(children: [
              for (var i = 0; i < _questions.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border),
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: AppColors.primaryText,
                  collapsedIconColor: AppColors.secondaryText,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  title: Text(_questions[i].$1,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_questions[i].$2,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                                height: 1.5)))
                  ],
                ),
              ],
            ])),
            const SizedBox(height: 20),
            AccountSectionCard(
                child: Column(children: [
              AccountMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Доставка и условия',
                  onTap: () => _open(context, const DeliveryScreen())),
              const AccountMenuDivider(),
              AccountMenuTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Гарантия',
                  onTap: () => _open(context, const WarrantyScreen())),
            ])),
          ]));
}
