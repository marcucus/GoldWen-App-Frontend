import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
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
              'Politique de confidentialité de GoldWen',
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
              '1. Introduction',
              'Chez GoldWen, nous prenons votre vie privée au sérieux. Cette politique de confidentialité explique comment nous collectons, utilisons, partageons et protégeons vos informations personnelles lorsque vous utilisez notre application.',
            ),
            
            _buildSection(
              context,
              '2. Informations que nous collectons',
              'Nous collectons les informations suivantes :\n\n'
              '• Informations de profil : nom, âge, photos, bio, réponses aux questions\n'
              '• Informations de compte : adresse e-mail, mot de passe (chiffré)\n'
              '• Données d\'utilisation : interactions avec l\'app, préférences\n'
              '• Informations techniques : type d\'appareil, système d\'exploitation\n'
              '• Données de localisation : si vous nous donnez l\'autorisation',
            ),
            
            _buildSection(
              context,
              '3. Comment nous utilisons vos informations',
              'Nous utilisons vos informations pour :\n\n'
              '• Fournir et améliorer notre service de matching\n'
              '• Personnaliser votre expérience\n'
              '• Communiquer avec vous\n'
              '• Assurer la sécurité de la plateforme\n'
              '• Respecter nos obligations légales\n'
              '• Développer de nouvelles fonctionnalités',
            ),
            
            _buildSection(
              context,
              '4. Partage des informations',
              'Nous ne vendons jamais vos données personnelles. Nous pouvons partager vos informations uniquement dans les cas suivants :\n\n'
              '• Avec d\'autres utilisateurs : selon vos paramètres de confidentialité\n'
              '• Avec des prestataires de services : sous contrat de confidentialité\n'
              '• Pour des raisons légales : si requis par la loi\n'
              '• En cas de transfert d\'entreprise : avec anonymisation si possible',
            ),
            
            _buildSection(
              context,
              '5. Sécurité des données',
              'Nous mettons en place des mesures de sécurité robustes :\n\n'
              '• Chiffrement des données en transit (TLS)\n'
              '• Chiffrement des données sensibles au repos\n'
              '• Authentification à deux facteurs\n'
              '• Surveillance continue des accès\n'
              '• Audits de sécurité réguliers\n'
              '• Formation du personnel sur la sécurité',
            ),
            
            _buildSection(
              context,
              '6. Vos droits (RGPD)',
              'Conformément au Règlement général sur la protection des données (RGPD), vous avez le droit de :\n\n'
              '• Accéder à vos données personnelles\n'
              '• Rectifier vos informations\n'
              '• Effacer vos données (droit à l\'oubli)\n'
              '• Limiter le traitement\n'
              '• Portabilité des données\n'
              '• Vous opposer au traitement\n'
              '• Retirer votre consentement',
            ),
            
            _buildSection(
              context,
              '7. Conservation des données',
              'Nous conservons vos données personnelles aussi longtemps que nécessaire pour fournir nos services ou tel que requis par la loi. Les données des comptes inactifs sont automatiquement supprimées après 12 mois d\'inactivité.',
            ),
            
            _buildSection(
              context,
              '8. Transferts internationaux',
              'Vos données peuvent être transférées et traitées dans des pays autres que votre pays de résidence. Nous nous assurons que ces transferts respectent les normes de protection applicables.',
            ),
            
            _buildSection(
              context,
              '9. Cookies et technologies similaires',
              'Nous utilisons des cookies et technologies similaires pour améliorer votre expérience, analyser l\'utilisation de l\'app et personnaliser le contenu. Vous pouvez gérer vos préférences de cookies dans les paramètres.',
            ),
            
            _buildSection(
              context,
              '10. Mineurs',
              'Notre service n\'est pas destiné aux personnes de moins de 18 ans. Nous ne collectons pas sciemment d\'informations personnelles auprès de mineurs.',
            ),
            
            _buildSection(
              context,
              '11. Modifications de cette politique',
              'Nous pouvons mettre à jour cette politique de confidentialité. Les modifications importantes vous seront notifiées par e-mail ou via l\'application avant leur entrée en vigueur.',
            ),
            
            _buildSection(
              context,
              '12. Contact',
              'Pour toute question concernant cette politique de confidentialité ou pour exercer vos droits, contactez-nous :\n\n'
              '• E-mail : privacy@goldwen.com\n'
              '• Délégué à la protection des données : dpo@goldwen.com\n'
              '• Adresse postale : GoldWen SAS, 123 Rue de la Tech, 75001 Paris, France',
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