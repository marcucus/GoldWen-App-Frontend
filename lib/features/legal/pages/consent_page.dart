import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gdpr_service.dart';
import '../widgets/gdpr_consent_modal.dart';

/// Standalone consent page that displays the GDPR consent modal
/// 
/// This page is used when users need to give or update their consent.
/// It can be accessed directly via routing or shown during onboarding.
class ConsentPage extends StatefulWidget {
  /// Whether the page can be dismissed (back button)
  final bool canDismiss;
  
  /// Callback when consent is successfully given
  final VoidCallback? onConsentGiven;

  const ConsentPage({
    super.key,
    this.canDismiss = true,
    this.onConsentGiven,
  });

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.canDismiss,
      child: Scaffold(
        appBar: widget.canDismiss
            ? AppBar(
                title: const Text('Consentement RGPD'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: GdprConsentModal(
                    canDismiss: widget.canDismiss,
                    onConsentGiven: () {
                      widget.onConsentGiven?.call();
                      if (widget.canDismiss) {
                        context.pop();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
