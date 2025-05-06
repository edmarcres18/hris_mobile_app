class ApiResponse<T> {
  bool success;
  String? message;
  T? data;
  int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJson(json['data']) : null,
      statusCode: json['status_code'],
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.success(T? data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }
} 