import 'account_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/saved_products_provider.dart';
import '../data/account_saved_products.dart';
import 'account_sections.dart';
import 'account_menu_tile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../ui/widgets/saved_products_shortcuts.dart';
import '../../../ui/screens/webview_screen.dart';
import '../data/account_gateway.dart';
import 'account_controller.dart';
import 'russian_phone_formatter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.controller});
  final AccountController? controller;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountController account;
  SiteAccountGateway? site;
  bool challenge = false, consent = false;
  AccountSession? sharedSession;
  SavedProductsProvider? savedProducts;
  String? savedSession;
  final phone = TextEditingController(text: RussianPhoneFormatter.prefix),
      code = TextEditingController();
  final name = TextEditingController(), lastName = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      account = widget.controller!;
    } else {
      final gateway = WebViewPlatform.instance == null
          ? UnavailableAccountGateway()
          : site = SiteAccountGateway(onChallenge: (value) {
              if (mounted) setState(() => challenge = value);
            });
      account = AccountController(gateway);
      account.initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<AccountSession?>();
    if (sharedSession != session) {
      sharedSession = session;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSession();
      });
    }
    final saved = context.read<SavedProductsProvider?>();
    if (savedProducts == saved && saved != null) return;
    savedProducts?.removeListener(_syncSession);
    account.removeListener(_syncSession);
    savedProducts = saved;
    saved?.addListener(_syncSession);
    account.addListener(_syncSession);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSession();
    });
  }

  void _syncSession() {
    sharedSession?.update(account.step == AccountStep.account);
    final saved = savedProducts;
    if (saved == null || !saved.ready) return;
    final session = account.step == AccountStep.account
        ? (account.profile?['id'])?.toString()
        : null;
    if (session == savedSession) return;
    savedSession = session;
    if (session == null) {
      saved.disconnect();
    } else {
      saved.connect(AccountSavedProducts(account.gateway));
    }
  }

  @override
  void dispose() {
    account.removeListener(_syncSession);
    savedProducts?.removeListener(_syncSession);
    if (savedSession != null) savedProducts?.disconnect(notify: false);
    if (widget.controller == null) account.dispose();
    phone.dispose();
    code.dispose();
    name.dispose();
    lastName.dispose();
    super.dispose();
  }

  Widget _button(String title, VoidCallback? action) => SizedBox(
      width: double.infinity,
      child: FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          child: Text(title)));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final children = account.step == AccountStep.account
            ? _dashboard(context)
            : _login(context);
        return Scaffold(
          appBar: AppBar(
              title: const Text('Кабинет'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.mainText,
              centerTitle: true),
          body: Stack(children: [
            ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...children,
                                if (account.error.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Text(account.error,
                                          style: const TextStyle(
                                              color: AppColors.installment))),
                                if (!account.connected && !account.busy)
                                  TextButton(
                                      onPressed: () =>
                                          account.initialize(reconnect: true),
                                      child:
                                          const Text('Повторить подключение')),
                                if (account.busy && !challenge)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                          child: CircularProgressIndicator())),
                                if (account.step != AccountStep.account) ...[
                                  const SizedBox(height: 24),
                                  Row(children: [
                                    Expanded(
                                        child: TextButton(
                                            onPressed: () =>
                                                openSavedProducts(context),
                                            child: const Text('Избранное'))),
                                    Expanded(
                                        child: TextButton(
                                            onPressed: () => openSavedProducts(
                                                context,
                                                compare: true),
                                            child: const Text('Сравнение')))
                                  ]),
                                ],
                              ]))),
                ]),
            if (site != null)
              Positioned(
                left: 0,
                right: 0,
                top: challenge ? 0 : null,
                bottom: 0,
                height: challenge ? null : 1,
                child: IgnorePointer(
                    ignoring: !challenge,
                    child: Opacity(
                        opacity: challenge ? 1 : 0,
                        child: ColoredBox(
                            color: Colors.white,
                            child: Column(children: [
                              if (challenge)
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                        onPressed: account.cancelChallenge,
                                        icon: const Icon(Icons.close),
                                        label: const Text('Отмена'))),
                              Expanded(
                                  child:
                                      WebViewWidget(controller: site!.browser)),
                            ])))),
              ),
          ]),
        );
      });
  List<Widget> _login(BuildContext context) {
    switch (account.step) {
      case AccountStep.phone:
        return [
          const Text('Вход по номеру телефона',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text(
              'Войдите, чтобы видеть свои заказы и управлять профилем. Аккаунт общий с сайтом Replatinum.',
              style: TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.secondaryText)),
          const SizedBox(height: 28),
          AutofillGroup(
              child: TextField(
                  controller: phone,
                  enabled: !account.busy,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: const [RussianPhoneFormatter()],
                  decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+7 (999) 123-45-67',
                      border: OutlineInputBorder()),
                  onSubmitted: (_) =>
                      account.connected ? account.sendCode(phone.text) : null)),
          const SizedBox(height: 16),
          _button(
              account.resendSeconds > 0
                  ? 'Повторно через ${account.resendSeconds} с'
                  : 'Получить код',
              account.busy || !account.connected || account.resendSeconds > 0
                  ? null
                  : () {
                      code.clear();
                      account.sendCode(phone.text);
                    }),
          const SizedBox(height: 12),
          const Text('Отправим SMS с кодом подтверждения. Пароль не нужен.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        ];
      case AccountStep.code:
        return [
          const Text('Введите код из SMS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Код отправлен на +${account.phone}',
              style: const TextStyle(height: 1.5)),
          TextButton(
              onPressed: account.busy ? null : account.changePhone,
              child: const Text('Изменить номер')),
          const SizedBox(height: 16),
          Center(
              child: SizedBox(
                  width: 220,
                  child: TextField(
                      controller: code,
                      enabled: !account.busy,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 6),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4)
                      ],
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          labelText: 'Код из SMS',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => account.verifyCode(code.text)))),
          const SizedBox(height: 16),
          _button('Войти',
              account.busy ? null : () => account.verifyCode(code.text)),
          TextButton(
              onPressed: account.busy || account.resendSeconds > 0
                  ? null
                  : () => account.sendCode(account.phone),
              child: Text(account.resendSeconds > 0
                  ? 'Отправить повторно через ${account.resendSeconds} с'
                  : 'Отправить код повторно')),
        ];
      case AccountStep.registration:
        return [
          const Text('Завершим знакомство',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Номер подтверждён. Укажите имя и фамилию для аккаунта.'),
          const SizedBox(height: 24),
          TextField(
              controller: name,
              enabled: !account.busy,
              autofillHints: const [AutofillHints.givenName],
              maxLength: 100,
              decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                  counterText: '')),
          const SizedBox(height: 16),
          TextField(
              controller: lastName,
              enabled: !account.busy,
              autofillHints: const [AutofillHints.familyName],
              maxLength: 100,
              decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                  counterText: '')),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: consent,
              onChanged: account.busy
                  ? null
                  : (value) => setState(() => consent = value ?? false),
              title: const Text('Согласен на обработку персональных данных',
                  style: TextStyle(fontSize: 13))),
          TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const WebViewScreen(
                          title: 'Политика конфиденциальности',
                          url: 'https://replatinum.ru/privacy-policy/'))),
              child: const Text('Политика конфиденциальности')),
          _button(
              'Создать аккаунт',
              account.busy
                  ? null
                  : () => account.register(name.text, lastName.text, consent)),
        ];
      case AccountStep.account:
        return [];
    }
  }

  void _openAccountPage(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Widget _menuTile(BuildContext context, IconData icon, String title,
          VoidCallback onTap) =>
      AccountMenuTile(
          icon: icon, title: title, onTap: account.busy ? null : onTap);

  List<Widget> _dashboard(BuildContext context) {
    final profile = account.profile ?? {};
    final fullName =
        '${profile['name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
    final initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    final phoneNumber = const RussianPhoneFormatter()
        .formatEditUpdate(TextEditingValue.empty,
            TextEditingValue(text: '${profile['phone'] ?? ''}'))
        .text;
    final summary = account.summary;
    final count = summary?['orders_count'] as int? ?? 0;
    final total = summary?['orders_total'] as num? ?? 0;
    return [
      Row(children: [
        DecoratedBox(
            decoration: BoxDecoration(
                color: const Color(0xFFE9F0DF),
                borderRadius: BorderRadius.circular(16)),
            child: SizedBox.square(
                dimension: 56,
                child: Center(
                    child: Text(initials.isEmpty ? 'RP' : initials,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText))))),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fullName.isEmpty ? 'Мой аккаунт' : fullName,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 6),
          Text(phoneNumber,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.secondaryText)),
        ])),
      ]),
      const SizedBox(height: 24),
      if (summary != null)
        Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border)),
            child: InkWell(
                onTap: account.busy
                    ? null
                    : () => _openAccountPage(
                        context, AccountOrdersScreen(account: account)),
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Expanded(
                                child: Text('Ваши покупки',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600))),
                            const Icon(Icons.chevron_right_rounded,
                                size: 20, color: AppColors.secondaryText)
                          ]),
                          const SizedBox(height: 12),
                          if (count == 0)
                            const Text('Заказов пока нет',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryText))
                          else ...[
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Text('Заказов: $count',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 16),
                                  Flexible(
                                      child: Text(formatPrice(total),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700))),
                                ]),
                            const SizedBox(height: 8),
                            const Text('Включая отменённые заказы',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText)),
                          ],
                        ])))),
      const SizedBox(height: 16),
      if (account.profile == null)
        TextButton(
            onPressed: account.busy ? null : () => account.initialize(),
            child: const Text('Обновить кабинет')),
      Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border)),
          child: Column(children: [
            _menuTile(
                context,
                Icons.person_outline_rounded,
                'Личные данные',
                () => _openAccountPage(
                    context, AccountProfileEditor(account: account))),
            const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.border),
            _menuTile(
                context,
                Icons.receipt_long_outlined,
                'Мои заказы',
                () => _openAccountPage(
                    context, AccountOrdersScreen(account: account))),
            const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.border),
            _menuTile(
                context,
                Icons.location_on_outlined,
                'Адрес доставки',
                () => _openAccountPage(
                    context, AccountAddressScreen(account: account))),
            const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.border),
            _menuTile(context, Icons.favorite_border_rounded, 'Избранное',
                () => openSavedProducts(context)),
            const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.border),
            _menuTile(context, Icons.bar_chart_rounded, 'Сравнение',
                () => openSavedProducts(context, compare: true)),
            const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.border),
            _menuTile(context, Icons.headset_mic_outlined, 'Помощь',
                () => _openAccountPage(context, const AccountHelpScreen())),
          ])),
      const SizedBox(height: 24),
      Align(
          alignment: Alignment.center,
          child: TextButton.icon(
              onPressed: account.busy ? null : account.logout,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryText),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Выйти из аккаунта'))),
    ];
  }
}

class AccountProfileEditor extends StatefulWidget {
  const AccountProfileEditor({super.key, required this.account});
  final AccountController account;
  @override
  State<AccountProfileEditor> createState() => _AccountProfileEditorState();
}

class _AccountProfileEditorState extends State<AccountProfileEditor> {
  late final TextEditingController name, lastName, email;
  bool saved = false;
  @override
  void initState() {
    super.initState();
    final profile = widget.account.profile ?? {};
    name = TextEditingController(text: '${profile['name'] ?? ''}');
    lastName = TextEditingController(text: '${profile['last_name'] ?? ''}');
    email = TextEditingController(text: '${profile['email'] ?? ''}');
  }

  @override
  void dispose() {
    name.dispose();
    lastName.dispose();
    email.dispose();
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
                title: const Text('Личные данные')),
            body: account.step != AccountStep.account
                ? const Center(
                    child: Text('Сессия истекла. Вернитесь и войдите снова.'))
                : ListView(padding: const EdgeInsets.all(20), children: [
                    AccountSectionCard(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                      controller: name,
                                      enabled: !account.busy,
                                      maxLength: 100,
                                      decoration:
                                          accountFieldDecoration('Имя')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: lastName,
                                      enabled: !account.busy,
                                      maxLength: 100,
                                      decoration:
                                          accountFieldDecoration('Фамилия')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: email,
                                      enabled: !account.busy,
                                      keyboardType: TextInputType.emailAddress,
                                      maxLength: 254,
                                      decoration: accountFieldDecoration(
                                          'Электронная почта')),
                                  const SizedBox(height: 16),
                                  Text(
                                      'Телефон: ${account.profile?['phone'] ?? ''}'),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Для смены номера обратитесь в магазин.',
                                      style: TextStyle(
                                          color: AppColors.secondaryText)),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                      onPressed: account.busy
                                          ? null
                                          : () async {
                                              setState(() => saved = false);
                                              await account.saveProfile(
                                                  name.text,
                                                  lastName.text,
                                                  email.text);
                                              if (mounted &&
                                                  account.error.isEmpty &&
                                                  account.step ==
                                                      AccountStep.account) {
                                                setState(() => saved = true);
                                              }
                                            },
                                      child: Text(account.busy
                                          ? 'Сохраняем…'
                                          : 'Сохранить')),
                                ]))),
                    if (saved)
                      const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text('Данные сохранены')),
                    if (account.error.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(account.error)),
                  ]));
      });
}

class AccountOrdersScreen extends StatefulWidget {
  const AccountOrdersScreen({super.key, required this.account});
  final AccountController account;
  @override
  State<AccountOrdersScreen> createState() => _AccountOrdersScreenState();
}

class _AccountOrdersScreenState extends State<AccountOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.account.loadOrders();
    });
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
                title: const Text('Мои заказы')),
            body: account.step != AccountStep.account
                ? const Center(
                    child: Text('Сессия истекла. Вернитесь и войдите снова.'))
                : RefreshIndicator(
                    onRefresh: account.loadOrders,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (account.busy && account.orders.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(32),
                                child:
                                    Center(child: CircularProgressIndicator())),
                          if (!account.busy &&
                              account.error.isEmpty &&
                              account.orders.isEmpty)
                            const AccountEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'Заказов пока нет',
                                message:
                                    'Выберите что-нибудь для себя. Здесь появятся ваши покупки и их статусы.'),
                          for (final order in account.orders)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AccountSectionCard(
                                    child: InkWell(
                                        onTap: account.busy
                                            ? null
                                            : () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        AccountOrderDetailScreen(
                                                            account: account,
                                                            id:
                                                                '${order['id']}'))),
                                        child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Заказ № ${order['number']}',
                                                      style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  const SizedBox(height: 8),
                                                  Text('${order['date']}',
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .secondaryText)),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xFFF0F4EA),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8)),
                                                      child: Text(
                                                          '${order['status']}',
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              color: AppColors
                                                                  .primaryText))),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                      order['currency'] == 'RUB'
                                                          ? formatPrice(
                                                              order['price']
                                                                  as num)
                                                          : '${order['price']} ${order['currency']}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 18)),
                                                  const SizedBox(height: 12),
                                                  const Text('Подробнее',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .primaryAccent)),
                                                ]))))),
                          if (account.error.isNotEmpty) ...[
                            Text(account.error),
                            TextButton(
                                onPressed: account.busy
                                    ? null
                                    : () => account.loadOrders(),
                                child: const Text('Повторить'))
                          ],
                          if (account.hasMoreOrders)
                            TextButton(
                                onPressed: account.busy
                                    ? null
                                    : () => account.loadOrders(more: true),
                                child: Text(account.busy
                                    ? 'Загружаем…'
                                    : 'Показать ещё')),
                        ])));
      });
}
