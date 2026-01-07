class MarketPrice {
  final int id;
  final String productName;
  final String region;
  final double pricePerKg;
  final String currency;
  final DateTime priceDate;
  final String? source;

  MarketPrice({
    required this.id,
    required this.productName,
    required this.region,
    required this.pricePerKg,
    required this.currency,
    required this.priceDate,
    this.source,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      region: json['region'] as String,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      currency: json['currency'] as String,
      priceDate: DateTime.parse(json['price_date'] as String),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'region': region,
      'price_per_kg': pricePerKg,
      'currency': currency,
      'price_date': priceDate.toIso8601String(),
      'source': source,
    };
  }
}

class Advice {
  final String title;
  final String advice;
  final List<String> tips;
  final List<String>? warnings;

  Advice({
    required this.title,
    required this.advice,
    required this.tips,
    this.warnings,
  });

  factory Advice.fromJson(Map<String, dynamic> json) {
    return Advice(
      title: json['title'] as String,
      advice: json['advice'] as String,
      tips: List<String>.from(json['tips'] as List),
      warnings: json['warnings'] != null 
          ? List<String>.from(json['warnings'] as List)
          : null,
    );
  }
}
