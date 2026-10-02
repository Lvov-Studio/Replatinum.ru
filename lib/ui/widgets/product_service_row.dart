import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ProductServiceIcon { pickup, delivery, warranty, tradeIn }

class ProductServiceRow extends StatelessWidget {
  const ProductServiceRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle});
  final ProductServiceIcon icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              DecoratedBox(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F4EA),
                      borderRadius: BorderRadius.circular(12)),
                  child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                          child: CustomPaint(
                              size: const Size(22, 22),
                              painter: _ServicePainter(icon))))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              height: 1.4)),
                    ],
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.secondaryText),
            ])),
      );
}

class _ServicePainter extends CustomPainter {
  const _ServicePainter(this.icon);
  final ProductServiceIcon icon;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = AppColors.primaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x, double y, double endX, double endY) =>
        canvas.drawLine(Offset(x, y), Offset(endX, endY), pen);
    switch (icon) {
      case ProductServiceIcon.pickup:
        canvas.drawPath(
            Path()
              ..moveTo(3, 9)
              ..lineTo(5, 4)
              ..lineTo(19, 4)
              ..lineTo(21, 9)
              ..close(),
            pen);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTRB(4, 9, 20, 21), const Radius.circular(1)),
            pen);
        line(9, 4, 8, 9);
        line(15, 4, 16, 9);
        line(4, 13, 20, 13);
        canvas.drawRect(const Rect.fromLTRB(9, 15, 15, 21), pen);
      case ProductServiceIcon.delivery:
        canvas.translate(0, -0.7);
        canvas.drawPath(
            Path()
              ..moveTo(3, 17)
              ..lineTo(2, 17)
              ..lineTo(2, 6)
              ..lineTo(14, 6)
              ..lineTo(14, 17)
              ..lineTo(9, 17),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(14, 9)
              ..lineTo(18, 9)
              ..lineTo(22, 13)
              ..lineTo(22, 17)
              ..lineTo(21, 17),
            pen);
        line(14, 17, 16, 17);
        line(17, 10, 17, 13);
        line(17, 13, 21, 13);
        canvas.drawCircle(const Offset(6, 17), 2.5, pen);
        canvas.drawCircle(const Offset(18.5, 17), 2.5, pen);
      case ProductServiceIcon.warranty:
        // The pointed base has less visual weight than the shield's top.
        canvas.translate(0, 0.5);
        canvas.drawPath(
            Path()
              ..moveTo(12, 3)
              ..lineTo(21, 7)
              ..lineTo(21, 12)
              ..quadraticBezierTo(21, 17, 12, 21)
              ..quadraticBezierTo(3, 17, 3, 12)
              ..lineTo(3, 7)
              ..close(),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(8, 12)
              ..lineTo(11, 15)
              ..lineTo(16, 9),
            pen);
      case ProductServiceIcon.tradeIn:
        canvas.drawPath(
            Path()
              ..moveTo(3, 8)
              ..lineTo(21, 8)
              ..moveTo(17, 4)
              ..lineTo(21, 8)
              ..lineTo(17, 12),
            pen);
        canvas.drawPath(
            Path()
              ..moveTo(21, 16)
              ..lineTo(3, 16)
              ..moveTo(7, 12)
              ..lineTo(3, 16)
              ..lineTo(7, 20),
            pen);
    }
  }

  @override
  bool shouldRepaint(_ServicePainter oldDelegate) => oldDelegate.icon != icon;
}
