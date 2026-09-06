class NewsItem {
  final String id;
  final String title;
  final String code;
  final String preview;
  final String image;
  final String date;
  final String category;
  final String url;

  const NewsItem({
    required this.id,
    required this.title,
    required this.code,
    required this.preview,
    required this.image,
    required this.date,
    required this.category,
    required this.url,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        preview: json['preview']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        category: json['category']?.toString() ?? 'СТАТЬЯ',
        url: json['url']?.toString() ?? '',
      );
}
