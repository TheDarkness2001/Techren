class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class PageMeta {
  const PageMeta({this.page = 1, this.limit = 20, this.search, this.status, this.branchId});

  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? branchId;

  PageMeta copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? branchId,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return PageMeta(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      branchId: branchId ?? this.branchId,
    );
  }

  Map<String, dynamic> toQuery() => {
        'page': page,
        'limit': limit,
        if (search != null && search!.isNotEmpty) 'search': search,
        if (status != null && status!.isNotEmpty) 'status': status,
        if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
      };
}
