import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class ApiAdapter implements HttpClientAdapter {
  ApiAdapter(this.respond);
  final (int, Object) Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final (status, body) = respond(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}
