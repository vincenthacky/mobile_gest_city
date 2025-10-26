import 'contribution_model.dart';

class ContributionResponse {
  final bool success;
  final int statusCode;
  final String message;
  final ContributionModel data;

  ContributionResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory ContributionResponse.fromJson(Map<String, dynamic> json) {
    return ContributionResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: ContributionModel.fromJson(json['data']),
    );
  }
}

class ContributionListResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<ContributionModel> data;
  final PaginationModel? pagination;

  ContributionListResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory ContributionListResponse.fromJson(Map<String, dynamic> json) {
    return ContributionListResponse(
      success: json['success'],
      statusCode: json['status_code'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => ContributionModel.fromJson(item))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaginationModel {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  PaginationModel({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      from: json['from'],
      to: json['to'],
    );
  }
}