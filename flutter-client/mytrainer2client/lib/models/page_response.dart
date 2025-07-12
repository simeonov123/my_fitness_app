class PageResponse<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  PageResponse({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    final content = (json['content'] as List)
        .cast<Map<String, dynamic>>()
        .map(fromJsonT)
        .toList();
    return PageResponse(
      items: content,
      page: json['number'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
