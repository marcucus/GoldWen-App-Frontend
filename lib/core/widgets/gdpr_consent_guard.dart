import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gdpr_service.dart';
import '../../features/legal/widgets/gdpr_consent_modal.dart';

class GdprConsentGuard extends StatefulWidget {
  final Widget child;

  const GdprConsentGuard({
    super.key,
    required this.child,
  });

  @override
  State<GdprConsentGuard> createState() => _GdprConsentGuardState();
}

class _GdprConsentGuardState extends State<GdprConsentGuard> {
  bool _hasCheckedConsent = false;
  bool _needsConsent = false;

  @override
  void initState() {
    super.initState();
    _checkConsentStatus();
  }

  Future<void> _checkConsentStatus() async {
    final gdprService = Provider.of<GdprService>(context, listen: false);
    final hasConsent = await gdprService.checkConsentStatus();
    
    setState(() {
      _hasCheckedConsent = true;
      _needsConsent = !hasConsent || gdprService.needsConsentRenewal();
    });

    // Show consent modal if needed
    if (_needsConsent && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConsentModal();
      });
    }
  }

  void _showConsentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GdprConsentModal(
          canDismiss: false,
          onConsentGiven: () {
            setState(() {
              _needsConsent = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking consent status
    if (!_hasCheckedConsent) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}