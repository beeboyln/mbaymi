class NewsArticle {
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime pubDate;
  final String? category;
  final String? source;
  final String? link;

  NewsArticle({
    required this.title,
    required this.description,
    this.imageUrl,
    required this.pubDate,
    this.category,
    this.source,
    this.link,
  });

  // Convertir DateTime en texte relatif
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(pubDate);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Il y a ${(difference.inDays / 7).floor()}s';
    }
  }
}
