import 'package:mockito/annotations.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/matching/providers/report_provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';

// This will generate mocks for these classes
@GenerateMocks([MatchingProvider, SubscriptionProvider, ApiService, ReportProvider])
void main() {}