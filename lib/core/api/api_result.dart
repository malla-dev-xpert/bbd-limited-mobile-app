class ApiResult<T> {
  final T? data;
  final String? errorMessage;
  final int? errorCode;
  final List<String>? errors;
  final bool isSuccess;

  ApiResult._({
    this.data,
    this.errorMessage,
    this.errorCode,
    this.errors,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResult.failure({
    String? errorMessage,
    int? errorCode,
    List<String>? errors,
  }) {
    return ApiResult._(
      errorMessage: errorMessage,
      errorCode: errorCode,
      errors: errors,
      isSuccess: false,
    );
  }
}

class ApiResponse<T> {
  final T? data;
  final String? message;
  final List<String>? errors;

  ApiResponse({
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: json['data'] as T?,
      message: json['message'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }
}
