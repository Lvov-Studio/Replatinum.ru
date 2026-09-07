import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// СЕРВИСНЫЙ ЦЕНТР
// ═══════════════════════════════════════════════════════════════════════════
class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});
  @override State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelCtrl   = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _modelCtrl.dispose(); _problemCtrl.dispose();
    _nameCtrl.dispose();  _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'action': 'service_request',
        'model':   _modelCtrl.text.trim(),
        'problem': _problemCtrl.text.trim(),
        'name':    _nameCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim(),
      });
      final res = await dio.post('https://replatinum.ru/local/ajax/service_request.php', data: formData);
      if (res.data != null && res.data['success'] == true) {
        setState(() => _success = true);
      } else {
        _showError(res.data?['message'] ?? 'Ошибка отправки');
      }
    } catch (_) {
      _showError('Ошибка сети. Попробуйте позже.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Сервисный центр', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HERO
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.build_rounded, color: AppColors.primaryAccent, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Сервисный центр', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Оставьте заявку на ремонт, и наши специалисты свяжутся с вами.',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(children: [
                  _heroFeature(Icons.bolt, 'Быстрый ремонт', 'Большинство поломок чиним при вас'),
                  const SizedBox(width: 12),
                  _heroFeature(Icons.shield_outlined, 'Гарантия на работу', 'Отвечаем за качество'),
                  const SizedBox(width: 12),
                  _heroFeature(Icons.memory, 'Оригинальные\nзапчасти', 'Надёжность'),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_success)
            _SuccessCard(
              icon: Icons.check_circle_outline,
              title: 'Заявка отправлена!',
              subtitle: 'Спасибо за ваше обращение! Наши менеджеры свяжутся с вами в ближайшее время.',
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.build_circle_outlined, color: AppColors.primaryAccent),
                      SizedBox(width: 8),
                      Text('Заявка на ремонт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Заполните форму, чтобы мы могли подготовиться к ремонту вашего устройства:',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    const SizedBox(height: 20),

                    _FormField(controller: _modelCtrl, label: 'Модель телефона *',
                        hint: 'Например: iPhone 14 Pro Max',
                        validator: (v) => v!.isEmpty ? 'Укажите модель' : null),
                    const SizedBox(height: 12),
                    _FormField(controller: _problemCtrl, label: 'Предполагаемый ремонт *',
                        hint: 'Опишите проблему: не включается, сломан экран, не заряжается...',
                        maxLines: 4,
                        validator: (v) => v!.isEmpty ? 'Опишите проблему' : null),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _FormField(controller: _nameCtrl, label: 'Ваше имя *',
                          hint: 'Как к вам обращаться?',
                          validator: (v) => v!.isEmpty ? 'Укажите имя' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _FormField(controller: _phoneCtrl, label: 'Телефон *',
                          hint: '+7 (___) ___-__-__',
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? 'Укажите телефон' : null)),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_loading ? 'Отправка...' : 'Отправить заявку',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: AppColors.secondaryText),
                        SizedBox(width: 4),
                        Text('Ваши данные защищены', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRADE-IN
// ═══════════════════════════════════════════════════════════════════════════
class TradeInScreen extends StatefulWidget {
  const TradeInScreen({super.key});
  @override State<TradeInScreen> createState() => _TradeInScreenState();
}

class _TradeInScreenState extends State<TradeInScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _typeCtrl  = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedType;
  bool _loading = false;
  bool _success = false;

  static const _deviceTypes = ['Смартфон', 'Планшет', 'Ноутбук', 'Моноблок', 'Умные часы'];

  @override
  void dispose() {
    _typeCtrl.dispose(); _modelCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final data = FormData.fromMap({
        'action': 'tradein_estimate',
        'type':   _selectedType ?? '',
        'brand':  'Apple',
        'model':  _modelCtrl.text.trim(),
        'name':   _nameCtrl.text.trim(),
        'phone':  _phoneCtrl.text.trim(),
      });
      final res = await dio.post('https://replatinum.ru/local/ajax/tradein_estimate.php', data: data);
      if (res.data != null && res.data['success'] == true) {
        setState(() => _success = true);
      } else {
        _showError(res.data?['message'] ?? 'Ошибка отправки');
      }
    } catch (_) {
      _showError('Ошибка сети. Попробуйте позже.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: const Text('Trade-in', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HERO
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryAccent, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Trade-in в Replatinum', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Сдайте старое устройство Apple — получите скидку на новое',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(children: [
                    Icon(Icons.apple, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text('Trade-in работает только с техникой Apple',
                        style: TextStyle(color: Colors.white, fontSize: 13))),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Шаги
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Как это работает?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStep('1', 'Оценка устройства', 'Приносите свой гаджет, и мы проведём честную оценку за ~10 минут.'),
                _buildStep('2', 'Получите стоимость', 'Мы озвучиваем финальную стоимость выкупа вашего устройства.'),
                _buildStep('3', 'Выберите новое устройство', 'Оформляем покупку, вы оплачиваете только разницу. Сделка в один день.'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Что учитывается
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Что учитывается при оценке?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Вся процедура ~10 минут', style: TextStyle(color: AppColors.primaryAccent, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: const [
                    'Модель устройства', 'Объём памяти',
                    'Состояние корпуса и дисплея', 'Состояние аккумулятора',
                    'Работоспособность всех функций', 'Отсутствие блокировок (iCloud)',
                    'Следы вскрытия или ремонта',
                  ].map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check, size: 12, color: AppColors.primaryAccent),
                      const SizedBox(width: 4),
                      Text(t, style: const TextStyle(fontSize: 12)),
                    ]),
                  )).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Почему выгоднее
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Почему выгоднее сдать нам?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...const [
                  'Не нужно ждать покупателя',
                  'Без рисков и встреч с незнакомыми людьми',
                  'Без торга и снижения цены',
                  'Без размещения объявлений',
                  'Сделка проходит в один день',
                  'Сразу получаете скидку на новое устройство',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: const TextStyle(fontSize: 14))),
                  ]),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ФОРМА
          if (_success)
            _SuccessCard(
              icon: Icons.calculate_outlined,
              title: 'Заявка отправлена!',
              subtitle: 'Наш менеджер свяжется с вами и назовёт примерную стоимость устройства.',
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.calculate_outlined, color: AppColors.primaryAccent),
                      SizedBox(width: 8),
                      Text('Рассчитать примерную стоимость', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Заполните форму, и мы рассчитаем стоимость вашего устройства.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    const SizedBox(height: 20),

                    // Тип устройства
                    const Text('Тип устройства *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.secondaryText)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: _inputDecoration('Выберите тип'),
                      items: _deviceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      validator: (v) => v == null ? 'Выберите тип устройства' : null,
                    ),
                    const SizedBox(height: 12),

                    _FormField(controller: _modelCtrl, label: 'Модель *',
                        hint: 'Например: iPhone 13 Pro, 256 GB',
                        validator: (v) => v!.isEmpty ? 'Укажите модель' : null),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _FormField(controller: _nameCtrl, label: 'Ваше имя *',
                          hint: 'Имя',
                          validator: (v) => v!.isEmpty ? 'Укажите имя' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _FormField(controller: _phoneCtrl, label: 'Телефон *',
                          hint: '+7 (___) ___-__-__',
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? 'Укажите телефон' : null)),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_loading ? 'Отправка...' : 'Рассчитать стоимость',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
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

Widget _heroFeature(IconData icon, String title, String sub) => Expanded(
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 20),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
      ],
    ),
  ),
);

Widget _buildStep(String num, String title, String desc) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(color: AppColors.primaryAccent, shape: BoxShape.circle),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4)),
        ],
      )),
    ],
  ),
);

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.secondaryText)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
  filled: true,
  fillColor: const Color(0xFFF2F2F7),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

class _SuccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SuccessCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.primaryAccent, size: 48),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.mainText)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5)),
      ]),
    );
  }
}
