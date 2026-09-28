import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/models/banner_model.dart';

void main() {
  group('BannerModel', () {
    test('should prefer the mobile image supplied by the slider API', () {
      final banner = BannerModel.fromJson({
        'id': '1',
        'title': 'AirPods Max',
        'image': 'https://replatinum.ru/preview.png',
        'bg_image': 'https://replatinum.ru/desktop.png',
        'mobile_image': 'https://replatinum.ru/mobile.png',
      });

      expect(banner.displayImage, 'https://replatinum.ru/mobile.png');
    });

    test('should fall back when the older API omits mobile_image', () {
      final withPreview = BannerModel.fromJson({
        'id': '2',
        'image': 'https://replatinum.ru/preview.png',
        'bg_image': 'https://replatinum.ru/desktop.png',
      });
      final withBackgroundOnly = BannerModel.fromJson({
        'id': '3',
        'image': '',
        'bg_image': 'https://replatinum.ru/desktop.png',
      });

      expect(withPreview.displayImage, 'https://replatinum.ru/preview.png');
      expect(
        withBackgroundOnly.displayImage,
        'https://replatinum.ru/desktop.png',
      );
    });
  });
}
