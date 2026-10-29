import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

enum AppErrorKind { offline, timeout, client, server, invalidResponse, unknown }

class AppException implements Exception {
  const AppException(this.kind, this.message, {this.statusCode});

  final AppErrorKind kind;
  final String message;
  final int? statusCode;

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is FormatException ||
        error is TypeError ||
        error is CheckedFromJsonException) {
      return const AppException(
        AppErrorKind.invalidResponse,
        'Сервер вернул данные в неожиданном формате.',
      );
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const AppException(
          AppErrorKind.timeout,
          'Сервер долго не отвечает. Попробуйте ещё раз.',
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          (error.type == DioExceptionType.unknown && error.response == null)) {
        return const AppException(
          AppErrorKind.offline,
          'Нет соединения с интернетом. Проверьте сеть и повторите попытку.',
        );
      }
      final status = error.response?.statusCode;
      if (status != null && status >= 500) {
        return AppException(
          AppErrorKind.server,
          'На сервере произошла ошибка ($status). Попробуйте позже.',
          statusCode: status,
        );
      }
      if (status != null && status >= 400) {
        return AppException(
          AppErrorKind.client,
          'Запрос отклонён сервером ($status). Проверьте данные.',
          statusCode: status,
        );
      }
    }
    return const AppException(
      AppErrorKind.unknown,
      'Не удалось выполнить запрос. Попробуйте ещё раз.',
    );
  }

  @override
  String toString() => message;
}
