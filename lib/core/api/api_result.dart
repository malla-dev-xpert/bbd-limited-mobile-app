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
  final bool? success;
  final String? errorCode;

  ApiResponse({
    this.data,
    this.message,
    this.errors,
    this.success,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? dataParser,
  }) {
    final rawData = json['data'];
    return ApiResponse(
      data: rawData != null
          ? (dataParser != null ? dataParser(rawData) : rawData as T?)
          : null,
      message: json['message'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      success: json['success'] as bool?,
      errorCode: json['errorCode']?.toString(),
    );
  }
}
