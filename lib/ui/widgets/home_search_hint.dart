import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomeSearchHint extends StatefulWidget {
  const HomeSearchHint({super.key});
  static const phrases = [
    'Samsung Galaxy Z Fold 8',
    'Apple iPhone 18 Pro Max',
    'Apple iPhone Duo',
    'Apple AirPods 5',
    'Apple AirPods Max',
    'Apple Watch Ultra 4',
    'Apple Watch Series 12',
    'Sony PlayStation 5',
    'Marshall',
    'JBL',
  ];
  @override
  State<HomeSearchHint> createState() => _HomeSearchHintState();
}

class _HomeSearchHintState extends State<HomeSearchHint>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _phrase = 0, _length = 0;
  bool _deleting = false, _enabled = false, _started = false;
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _update();
  void _update() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final enabled = _visible &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed);
    if (enabled == _enabled) return;
    _enabled = enabled;
    _timer?.cancel();
    if (_enabled) _schedule(const Duration(milliseconds: 80));
  }

  void _schedule(Duration duration) => _timer = Timer(duration, _tick);
  void _tick() {
    if (!mounted || !_enabled) return;
    var delay = Duration(milliseconds: _deleting ? 40 : 80);
    setState(() {
      _started = true;
      if (_deleting) {
        _length--;
        if (_length == 0) {
          _deleting = false;
          _phrase = (_phrase + 1) % HomeSearchHint.phrases.length;
          delay = const Duration(milliseconds: 400);
        }
      } else {
        _length++;
        if (_length == HomeSearchHint.phrases[_phrase].length) {
          _deleting = true;
          delay = const Duration(seconds: 2);
        }
      }
    });
    _schedule(delay);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Text(
          !_enabled || !_started
              ? 'Поиск товаров'
              : HomeSearchHint.phrases[_phrase].substring(0, _length),
          key: const ValueKey('home-search-hint'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: AppColors.secondaryText, fontSize: 15)));
}
