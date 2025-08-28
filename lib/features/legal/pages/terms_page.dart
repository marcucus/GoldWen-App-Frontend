import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conditions d\'utilisation de GoldWen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryGold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            _buildSection(
              context,
              '1. Acceptation des conditions',
              'En utilisant l\'application GoldWen, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre service.',
            ),
            
            _buildSection(
              context,
              '2. Description du service',
              'GoldWen est une application de rencontre qui privilégie la qualité à la quantité. Notre service vous propose une sélection quotidienne de profils compatibles basée sur vos affinités et vos réponses au questionnaire de personnalité.',
            ),
            
            _buildSection(
              context,
              '3. Éligibilité',
              'Vous devez être âgé d\'au moins 18 ans pour utiliser GoldWen. En créant un compte, vous confirmez que vous avez l\'âge légal pour former un contrat contraignant.',
            ),
            
            _buildSection(
              context,
              '4. Compte utilisateur',
              'Vous êtes responsable de maintenir la confidentialité de vos informations de compte et de toutes les activités qui se produisent sous votre compte. Vous devez nous notifier immédiatement de toute utilisation non autorisée de votre compte.',
            ),
            
            _buildSection(
              context,
              '5. Conduite des utilisateurs',
              'Vous acceptez de ne pas utiliser le service pour :\n'
              '• Harceler, abuser ou nuire à autrui\n'
              '• Publier du contenu faux, trompeur ou illégal\n'
              '• Usurper l\'identité d\'une autre personne\n'
              '• Solliciter des informations personnelles d\'autres utilisateurs\n'
              '• Promouvoir des services commerciaux non autorisés',
            ),
            
            _buildSection(
              context,
              '6. Contenu utilisateur',
              'Vous conservez la propriété de tout contenu que vous soumettez à GoldWen. Cependant, en soumettant du contenu, vous accordez à GoldWen une licence non exclusive pour utiliser, afficher et distribuer ce contenu dans le cadre du service.',
            ),
            
            _buildSection(
              context,
              '7. Abonnement GoldWen Plus',
              'Certaines fonctionnalités avancées nécessitent un abonnement payant. Les abonnements se renouvellent automatiquement sauf annulation. Vous pouvez annuler votre abonnement à tout moment dans les paramètres de votre compte.',
            ),
            
            _buildSection(
              context,
              '8. Résiliation',
              'Nous nous réservons le droit de suspendre ou de résilier votre compte à tout moment si vous violez ces conditions d\'utilisation ou si nous estimons que votre comportement est préjudiciable à notre communauté.',
            ),
            
            _buildSection(
              context,
              '9. Limitation de responsabilité',
              'GoldWen est fourni "en l\'état" sans garantie d\'aucune sorte. Nous ne sommes pas responsables des dommages directs, indirects ou consécutifs résultant de l\'utilisation de notre service.',
            ),
            
            _buildSection(
              context,
              '10. Modifications',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications seront effectives dès leur publication. Votre utilisation continue du service après les modifications constitue votre acceptation des nouvelles conditions.',
            ),
            
            _buildSection(
              context,
              '11. Contact',
              'Pour toute question concernant ces conditions d\'utilisation, veuillez nous contacter à l\'adresse : legal@goldwen.com',
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}