import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ДОСТАВКА
// ═══════════════════════════════════════════════════════════════════════════
class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Доставка', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          // HERO
          _HeroBlock(
            icon: Icons.local_shipping_rounded,
            title: 'Быстрая доставка\nпо городу',
            subtitle: 'Оперативно, безопасно и удобно — прямо до согласованного места',
            chips: const ['Ежедневно 12:00–22:00', 'Срочная за 3 часа', 'Оплата при получении'],
            stats: const [
              _Stat('1000', 'рублей доставка'),
              _Stat('3ч', 'срочная доставка'),
              _Stat('7', 'дней в неделю'),
            ],
          ),

          // INTRO
          _TextBlock(text: 'Компания Replatinum предлагает удобную и оперативную доставку техники по городу. '
              'Доставка осуществляется ежедневно с 12:00 до 22:00. '
              'Заказы, оформленные до 18:00, как правило доставляются в день оформления.'),

          // Стандартная доставка
          _InfoCard(
            icon: Icons.inventory_2_outlined,
            title: 'Стандартная доставка',
            lead: 'Доставляем технику в течение дня в любую точку города по фиксированной цене.',
            infoRows: const [
              _InfoRow(icon: Icons.location_on_outlined, label: 'Зона', value: 'По городу'),
              _InfoRow(icon: Icons.currency_ruble, label: 'Цена', value: '1 000 ₽', accent: true),
              _InfoRow(icon: Icons.access_time, label: 'Время', value: '12:00 – 22:00'),
              _InfoRow(icon: Icons.payments_outlined, label: 'Оплата', value: 'Наличными при получении'),
            ],
            note: 'Заказы до 18:00 как правило доставляются в тот же день.',
          ),

          // Срочная доставка
          _InfoCard(
            icon: Icons.bolt,
            title: 'Срочная доставка',
            lead: 'Для клиентов, которым необходимо получить устройство в максимально короткие сроки.',
            bulletPoints: const [
              'Доступна при оформлении заказа до 20:00',
              'Среднее время доставки — до 3 часов с момента подтверждения',
              'Стоимость рассчитывается индивидуально',
            ],
            note: 'Подробные условия и точную стоимость уточняйте у менеджера при оформлении заказа.',
            accentNote: true,
          ),

          // Правила доставки
          _RulesCard(
            title: 'Правила доставки',
            rules: const [
              _Rule('01', 'Место встречи', 'Доставка осуществляется в общественных и публичных местах — перед входом в здание или торговый центр.'),
              _Rule('02', 'Оплата перед передачей', 'Передача товара осуществляется после полной оплаты заказа наличными средствами.'),
              _Rule('03', 'Проверка комплектации', 'Вскрытие упаковки и проверка комплектации производится после оплаты.'),
              _Rule('04', 'Ответственность', 'После передачи товара ответственность за внешние повреждения несёт покупатель.'),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ГАРАНТИЯ
// ═══════════════════════════════════════════════════════════════════════════
class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Гарантия', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          _HeroBlock(
            icon: Icons.security_rounded,
            title: 'Гарантия replatinum',
            subtitle: 'Официальная ответственность за качество каждого проданного устройства',
            stats: const [
              _Stat('36', 'месяцев гарантии'),
              _Stat('100%', 'официальная техника'),
              _Stat('0', 'скрытых платежей'),
            ],
          ),

          _TextBlock(text: 'Компания Replatinum несёт ответственность за качество реализуемой продукции '
              'и обеспечивает гарантийное обслуживание в соответствии с действующим законодательством РФ. '
              'Все гарантийные обязательства регулируются нормами Закона РФ «О защите прав потребителей».'),

          _InfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Стандартная гарантия',
            lead: 'На большинство товаров распространяется стандартная гарантия сроком 12 месяцев.',
            bulletPoints: const [
              'Бесплатное устранение производственных недостатков',
              'Диагностика устройства при обращении',
              'Ремонт или замена комплектующих при подтверждении гарантийного случая',
              'Консультационная поддержка по вопросам эксплуатации',
            ],
            note: 'Гарантийное обслуживание осуществляется при соблюдении правил использования и отсутствии механических повреждений.',
          ),

          _InfoCard(
            icon: Icons.stars_rounded,
            title: 'Расширенная гарантия Replatinum',
            lead: 'Дополнительная услуга для расширенной защиты вашей техники:',
            bulletPoints: const [
              'Увеличивает срок гарантийного обслуживания',
              'Расширяет перечень возможных гарантийных случаев',
              'Минимизирует финансовые риски при эксплуатации',
              'Позволяет получить приоритетное обслуживание',
            ],
            note: 'Расширенная гарантия оформляется при покупке товара.',
            accentNote: true,
          ),

          _InfoCard(
            icon: Icons.handshake_outlined,
            title: 'Прозрачность условий',
            lead: 'Мы придерживаемся принципов прозрачности и открытости:',
            bulletPoints: const [
              'Все условия гарантии фиксируются в документах',
              'Клиент заранее информируется о сроках и порядке обслуживания',
              'Отсутствуют скрытые платежи и дополнительные обязательства',
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// КОНТАКТЫ
// ═══════════════════════════════════════════════════════════════════════════
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  void _call() async {
    final uri = Uri(scheme: 'tel', path: '+79180072333');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _email() async {
    final uri = Uri(scheme: 'mailto', path: 'info@replatinum.ru');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _openMap() async {
    final uri = Uri.parse('https://yandex.com/maps/org/replatinum/186622082456/?indoorLevel=2&ll=39.052631%2C45.034483&z=17');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Контакты', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkAccent, Color(0xFF3D3D4A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_on, color: AppColors.primaryAccent, size: 14),
                    const SizedBox(width: 4),
                    const Text('Наш магазин', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 12),
                const Text('Мы в Краснодаре', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('ТРК «СБС Мегамолл», 2 этаж — зона кинотеатров IMAX',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Адрес
          _ContactCard(
            icon: Icons.location_on_outlined,
            label: 'Адрес',
            value: 'Краснодар, ул. Уральская, 79/1',
            note: 'ТРК «СБС Мегамолл», 2 этаж\nМагазин Replatinum\nОриентир: возле кинокасс, напротив Бумбараш',
            onTap: _openMap,
            actionLabel: 'Открыть в Яндекс.Картах',
          ),

          const SizedBox(height: 12),

          // Телефон
          _ContactCard(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: '+7 918 007 23 33',
            note: 'Ежедневно, с 10:00 до 22:00',
            onTap: _call,
            actionLabel: 'Позвонить',
          ),

          const SizedBox(height: 12),

          // Email
          _ContactCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'info@replatinum.ru',
            note: 'Ответим в течение рабочего дня',
            onTap: _email,
            actionLabel: 'Написать',
          ),

          const SizedBox(height: 12),

          // Рейтинг Яндекс
          GestureDetector(
            onTap: _openMap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0,2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('5,0', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: List.generate(5, (_) => const Icon(Icons.star, color: Color(0xFFFFCC00), size: 16))),
                        const SizedBox(height: 2),
                        const Text('68 отзывов на Яндекс.Картах', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const Text('Яндекс.Карты', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.secondaryText),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Часы работы
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.access_time, color: AppColors.primaryAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text('Режим работы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
                const SizedBox(height: 12),
                _workRow('Понедельник – Воскресенье', '10:00 – 22:00'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// РАССРОЧКА
// ═══════════════════════════════════════════════════════════════════════════
class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});
  @override State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  int _activePanel = 0;

  static const _panels = [
    _Panel('Что такое рассрочка?',
        'Рассрочка — это способ покупки техники с оплатой частями без единовременной полной суммы.\n\n'
        'Вы забираете устройство сразу, а оплачиваете его равными платежами в течение установленного срока.\n\n'
        'Это удобный способ приобрести товар уже сегодня, распределив нагрузку на бюджет.'),
    _Panel('Виды рассрочки в replatinum',
        'В нашем магазине доступна рассрочка от Совкомбанка по карте «Халва».\n\n'
        'Формат: «Купи сейчас — плати потом»\n\n'
        'Преимущества:\n• Быстрое оформление\n• Минимум документов\n• Мгновенное решение\n• Оплата равными платежами\n\n'
        'Подробные условия и срок зависят от предложения банка.'),
    _Panel('Условия рассрочки',
        '• Рассрочка оформляется с подключением дополнительной гарантии replatinum.\n\n'
        '• Дополнительная гарантия защищает устройство от непредвиденных расходов.\n\n'
        '• На товары в рассрочку не распространяется акционная цена интернет-магазина.'),
    _Panel('Почему цена отличается?',
        'Стоимость при рассрочке может отличаться от цены при оплате наличными.\n\n'
        'Это связано с тем, что:\n• К стоимости добавляется цена дополнительной гарантии\n'
        '• Данные услуги незначительно увеличивают ежемесячный платёж\n'
        '• На товары в рассрочку не распространяется акционная цена\n\n'
        'Мы всегда заранее рассчитываем итоговую сумму — без скрытых условий.'),
    _Panel('Кредит',
        'Помимо рассрочки, доступно оформление кредита.\n\n'
        'Условия:\n• Более 16 банков-партнёров\n• Срок от 2 до 60 месяцев\n'
        '• Индивидуальный подбор условий\n• Быстрое рассмотрение заявки\n\n'
        'Наши менеджеры подберут оптимальное предложение с учётом ваших пожеланий.'),
    _Panel('Досрочное погашение',
        'Да, досрочное погашение возможно.\n\n'
        'Условия и порядок досрочного погашения уточняются в банке, одобрившем кредит.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Рассрочка и кредит', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          _HeroBlock(
            icon: Icons.credit_card_rounded,
            title: 'Рассрочка и кредит\nв Replatinum',
            subtitle: 'Забирайте технику сегодня — платите частями',
            stats: const [
              _Stat('16+', 'банков-партнёров'),
              _Stat('5мин', 'одобрение'),
              _Stat('60мес', 'максимальный срок'),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(_panels.length, (i) {
                final isActive = _activePanel == i;
                return GestureDetector(
                  onTap: () => setState(() => _activePanel = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppColors.primaryAccent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(child: Text(_panels[i].title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? AppColors.primaryAccent : AppColors.mainText))),
                              Icon(isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: isActive ? AppColors.primaryAccent : AppColors.secondaryText),
                            ],
                          ),
                        ),
                        if (isActive) Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(_panels[i].content,
                              style: const TextStyle(color: AppColors.mainText, fontSize: 14, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;
  final List<_Stat> stats;

  const _HeroBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.chips = const [],
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkAccent, Color(0xFF3A3A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: chips.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 12)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: stats.map((s) => Expanded(
              child: Column(
                children: [
                  Text(s.value, style: const TextStyle(color: AppColors.primaryAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(s.label, style: const TextStyle(color: Colors.white60, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;
  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(text, style: const TextStyle(color: AppColors.mainText, fontSize: 14, height: 1.6)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String lead;
  final List<_InfoRow> infoRows;
  final List<String> bulletPoints;
  final String? note;
  final bool accentNote;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.lead,
    this.infoRows = const [],
    this.bulletPoints = const [],
    this.note,
    this.accentNote = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentNote ? AppColors.primaryAccent.withValues(alpha: 0.08) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.mainText))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead, style: const TextStyle(color: AppColors.mainText, fontSize: 14, height: 1.5)),

                if (infoRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...infoRows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(row.icon, size: 16, color: row.accent ? AppColors.primaryAccent : AppColors.secondaryText),
                      const SizedBox(width: 8),
                      Text(row.label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      const Spacer(),
                      Text(row.value, style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: row.accent ? AppColors.primaryAccent : AppColors.mainText)),
                    ]),
                  )),
                ],

                if (bulletPoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...bulletPoints.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 6, color: AppColors.primaryAccent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b, style: const TextStyle(fontSize: 14, height: 1.4))),
                      ],
                    ),
                  )),
                ],

                if (note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentNote
                          ? AppColors.primaryAccent.withValues(alpha: 0.1)
                          : const Color(0xFFF0F0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(accentNote ? Icons.check_circle_outline : Icons.info_outline,
                            size: 16, color: accentNote ? AppColors.primaryAccent : AppColors.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note!, style: TextStyle(
                            fontSize: 12,
                            color: accentNote ? AppColors.primaryAccent : AppColors.secondaryText,
                            height: 1.4))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  final String title;
  final List<_Rule> rules;
  const _RulesCard({required this.title, required this.rules});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...rules.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(r.num,
                      style: const TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(r.text, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4)),
                  ],
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String note;
  final VoidCallback onTap;
  final String actionLabel;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(note, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryAccent),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

Widget _workRow(String day, String time) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(children: [
    Expanded(child: Text(day, style: const TextStyle(fontSize: 14, color: AppColors.mainText))),
    Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
  ]),
);

// ─── Данные ────────────────────────────────────────────────────────────────

class _Stat {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  const _InfoRow({required this.icon, required this.label, required this.value, this.accent = false});
}

class _Rule {
  final String num;
  final String title;
  final String text;
  const _Rule(this.num, this.title, this.text);
}

class _Panel {
  final String title;
  final String content;
  const _Panel(this.title, this.content);
}
