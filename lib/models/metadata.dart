class Metadata {
  final String source;
  final String approach;
  final String lastUpdated;

  Metadata({
    required this.source,
    required this.approach,
    required this.lastUpdated,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      source: json['source'] as String,
      approach: json['approach'] as String,
      lastUpdated: json['last_updated'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'approach': approach,
      'last_updated': lastUpdated,
    };
  }
}

