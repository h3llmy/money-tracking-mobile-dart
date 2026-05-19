class ApiResponse<T> {
  final T data;

  ApiResponse({required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse(
      data: fromJsonT(json['data'] as Map<String, dynamic>),
    );
  }
}

class PaginationResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int totalData;
  final int totalPage;

  PaginationResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.totalData,
    required this.totalPage,
  });

  factory PaginationResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginationResponse(
      data: (json['data'] as List).map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalData: json['total_data'] as int,
      totalPage: json['total_page'] as int,
    );
  }
}
