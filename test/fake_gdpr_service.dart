import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';
class FakeGdprService extends GdprService {
  @override
  PrivacySettings? currentPrivacySettings;
  @override
  bool isLoading = false;
  @override
  DataExportRequest? currentExportRequest;
  @override
  AccountDeletionStatus? accountDeletionStatus;
  @override
  Future<bool> getAccountDeletionStatus() async => true;
}
