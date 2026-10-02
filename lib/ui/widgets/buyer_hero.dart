import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum BuyerHeroKind { service, tradeIn, credit, delivery, warranty, contacts }

const _content = [
  (
    Icons.build_rounded,
    'Сервисный центр',
    'Оставьте заявку на ремонт, и наши специалисты свяжутся с вами.'
  ),
  (
    Icons.swap_horiz_rounded,
    'Trade-in в Replatinum',
    'Сдайте старое устройство Apple — получите скидку на новое'
  ),
  (
    Icons.credit_card_rounded,
    'Рассрочка и кредит\nв Replatinum',
    'Забирайте технику сегодня — платите частями'
  ),
  (
    Icons.local_shipping_rounded,
    'Быстрая доставка\nпо городу',
    'Оперативно, безопасно и удобно — прямо до согласованного места'
  ),
  (
    Icons.security_rounded,
    'Гарантия replatinum',
    'Официальная ответственность за качество каждого проданного устройства'
  ),
  (
    Icons.location_on_outlined,
    'Мы в Краснодаре',
    'ТРК «СБС Мегамолл», 2 этаж — зона кинотеатров IMAX'
  ),
];

/// All buyer banners share measured text slots, including at larger text sizes.
class BuyerHero extends StatelessWidget {
  const BuyerHero({super.key, required this.kind});
  final BuyerHeroKind kind;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final titleStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25);
        final subtitleStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: const Color(0xFFDDDEE3), fontSize: 13, height: 1.5);
        final width = math.max(1.0, constraints.maxWidth - 40);
        double height(String text, TextStyle style) {
          final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context));
          painter.layout(maxWidth: width);
          final result = painter.height;
          painter.dispose();
          return result;
        }

        final titleHeight = _content
            .map((item) => height(item.$2, titleStyle))
            .reduce(math.max);
        final subtitleHeight = _content
            .map((item) => height(item.$3, subtitleStyle))
            .reduce(math.max);
        final item = _content[kind.index];
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [AppColors.darkAccent, Color(0xFF3D3D4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(item.$1, color: AppColors.primaryAccent, size: 24)),
              const SizedBox(height: 14),
              SizedBox(
                  height: titleHeight,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item.$2, style: titleStyle))),
              const SizedBox(height: 8),
              SizedBox(
                  height: subtitleHeight,
                  child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(item.$3, style: subtitleStyle))),
            ]));
      });
}
