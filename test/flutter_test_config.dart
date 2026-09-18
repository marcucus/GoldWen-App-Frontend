import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'support/api_adapter.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Unit/widget tests never contact a live backend. Tests expecting successful
  // responses must install their own explicit fixture adapter.
  ApiService.configureTestAdapter(() => ApiAdapter((_) => (503, {'message': 'No API fixture installed'})));
  await testMain();
}
