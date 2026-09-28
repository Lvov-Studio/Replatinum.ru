class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String mobileImage;
  final String bgImage;
  final String link;
  final String badge;

  String get displayImage => mobileImage.isNotEmpty
      ? mobileImage
      : image.isNotEmpty
          ? image
          : bgImage;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.mobileImage,
    required this.bgImage,
    required this.link,
    required this.badge,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      mobileImage: json['mobile_image']?.toString() ?? '',
      bgImage: json['bg_image']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
    );
  }
}
