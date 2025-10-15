import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PrivacyPolicy } from '../../database/entities/privacy-policy.entity';

@Injectable()
export class LegalService {
  constructor(
    @InjectRepository(PrivacyPolicy)
    private privacyPolicyRepository: Repository<PrivacyPolicy>,
  ) {}

  /**
   * Get privacy policy by version or latest active version
   * @param version - Version string or 'latest'
   * @returns PrivacyPolicy entity
   */
  async getPrivacyPolicy(version: string = 'latest'): Promise<PrivacyPolicy> {
    let policy: PrivacyPolicy | null;

    if (version === 'latest') {
      policy = await this.privacyPolicyRepository.findOne({
        where: { isActive: true },
        order: { effectiveDate: 'DESC' },
      });
    } else {
      policy = await this.privacyPolicyRepository.findOne({
        where: { version },
      });
    }

    if (!policy) {
      // If no policy exists, create a default one
      policy = await this.createDefaultPrivacyPolicy();
    }

    return policy;
  }

  /**
   * Create a default privacy policy if none exists
   * @returns Created PrivacyPolicy entity
   */
  private async createDefaultPrivacyPolicy(): Promise<PrivacyPolicy> {
    const defaultPolicy = this.privacyPolicyRepository.create({
      version: '1.0.0',
      isActive: true,
      effectiveDate: new Date(),
      content: this.getDefaultPrivacyPolicyContent(),
      htmlContent: this.getDefaultPrivacyPolicyHtml(),
    });

    return this.privacyPolicyRepository.save(defaultPolicy);
  }

  /**
   * Get default privacy policy content in JSON format
   */
  private getDefaultPrivacyPolicyContent(): string {
    return JSON.stringify({
      sections: [
        {
          title: 'Collecte des Données',
          content:
            "Nous collectons les données personnelles que vous nous fournissez lors de l'inscription et de l'utilisation de notre application de rencontres.",
        },
        {
          title: 'Utilisation des Données',
          content:
            'Vos données sont utilisées pour améliorer votre expérience de matching, vous proposer des profils compatibles et vous envoyer des notifications pertinentes.',
        },
        {
          title: 'Traitement des Données (RGPD Art. 6)',
          content:
            "Le traitement de vos données personnelles est basé sur votre consentement explicite (Art. 6(1)(a) RGPD) et sur la nécessité d'exécuter le contrat de service (Art. 6(1)(b) RGPD).",
        },
        {
          title: 'Vos Droits',
          content:
            "Conformément au RGPD, vous disposez du droit d'accès, de rectification, de suppression, de limitation du traitement, de portabilité et d'opposition concernant vos données personnelles.",
        },
        {
          title: 'Sécurité',
          content:
            'Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles appropriées pour protéger vos données contre tout accès, modification, divulgation ou destruction non autorisés.',
        },
        {
          title: 'Conservation des Données',
          content:
            "Vos données sont conservées tant que votre compte est actif. En cas de suppression de compte, vos données sont anonymisées conformément à l'Art. 17 RGPD (droit à l'oubli).",
        },
        {
          title: 'Consentement',
          content:
            'Vous pouvez retirer votre consentement à tout moment depuis les paramètres de votre compte. Le retrait du consentement ne compromet pas la licéité du traitement effectué avant ce retrait.',
        },
        {
          title: 'Contact',
          content:
            'Pour toute question concernant vos données personnelles ou cette politique de confidentialité, veuillez nous contacter à privacy@goldwen.app',
        },
      ],
    });
  }

  /**
   * Get default privacy policy content in HTML format
   */
  private getDefaultPrivacyPolicyHtml(): string {
    return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Politique de Confidentialité - GoldWen</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #4CAF50; margin-top: 30px; }
        p { color: #666; }
        .update-date { color: #999; font-style: italic; }
    </style>
</head>
<body>
    <h1>Politique de Confidentialité</h1>
    <p class="update-date">Dernière mise à jour : ${new Date().toLocaleDateString('fr-FR')}</p>
    
    <h2>1. Collecte des Données</h2>
    <p>Nous collectons les données personnelles que vous nous fournissez lors de l'inscription et de l'utilisation de notre application de rencontres. Ces données incluent votre nom, email, photos, préférences de matching et informations de profil.</p>
    
    <h2>2. Utilisation des Données</h2>
    <p>Vos données sont utilisées pour améliorer votre expérience de matching, vous proposer des profils compatibles et vous envoyer des notifications pertinentes. Nous n'utilisons jamais vos données à des fins non déclarées.</p>
    
    <h2>3. Traitement des Données (RGPD Art. 6)</h2>
    <p>Le traitement de vos données personnelles est basé sur votre consentement explicite (Art. 6(1)(a) RGPD) et sur la nécessité d'exécuter le contrat de service (Art. 6(1)(b) RGPD). Vous conservez le contrôle total de vos données.</p>
    
    <h2>4. Vos Droits</h2>
    <p>Conformément au RGPD, vous disposez des droits suivants :</p>
    <ul>
        <li><strong>Droit d'accès</strong> : obtenir une copie de vos données personnelles</li>
        <li><strong>Droit de rectification</strong> : corriger vos données inexactes</li>
        <li><strong>Droit à l'oubli</strong> : demander la suppression de vos données (Art. 17 RGPD)</li>
        <li><strong>Droit à la portabilité</strong> : exporter vos données (Art. 20 RGPD)</li>
        <li><strong>Droit d'opposition</strong> : vous opposer au traitement de vos données</li>
        <li><strong>Droit à la limitation</strong> : limiter le traitement de vos données</li>
    </ul>
    
    <h2>5. Sécurité</h2>
    <p>Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles appropriées pour protéger vos données :</p>
    <ul>
        <li>Chiffrement de bout en bout (TLS/HTTPS)</li>
        <li>Chiffrement au repos des données sensibles</li>
        <li>Authentification sécurisée</li>
        <li>Audits de sécurité réguliers</li>
    </ul>
    
    <h2>6. Conservation des Données</h2>
    <p>Vos données sont conservées tant que votre compte est actif. En cas de suppression de compte, vos données sont anonymisées conformément à l'Art. 17 RGPD (droit à l'oubli). Les données de matching sont conservées 30 jours après la suppression pour des raisons de sécurité et de prévention de fraude.</p>
    
    <h2>7. Consentement</h2>
    <p>Vous pouvez retirer votre consentement à tout moment depuis les paramètres de votre compte. Le retrait du consentement ne compromet pas la licéité du traitement effectué avant ce retrait (Art. 7(3) RGPD).</p>
    
    <h2>8. Partage des Données</h2>
    <p>Nous ne partageons vos données avec aucun tiers à des fins commerciales. Les seuls partages effectués concernent :</p>
    <ul>
        <li>Les services techniques nécessaires au fonctionnement de l'application (hébergement, base de données)</li>
        <li>Les autorités compétentes en cas d'obligation légale</li>
    </ul>
    
    <h2>9. Cookies et Tracking</h2>
    <p>Nous utilisons des cookies strictement nécessaires au fonctionnement de l'application. L'utilisation de cookies analytics requiert votre consentement explicite que vous pouvez gérer dans les paramètres.</p>
    
    <h2>10. Contact</h2>
    <p>Pour toute question concernant vos données personnelles ou cette politique de confidentialité, veuillez nous contacter :</p>
    <ul>
        <li>Email : <a href="mailto:privacy@goldwen.app">privacy@goldwen.app</a></li>
        <li>Délégué à la protection des données (DPO) : <a href="mailto:dpo@goldwen.app">dpo@goldwen.app</a></li>
    </ul>
    
    <h2>11. Modifications</h2>
    <p>Cette politique de confidentialité peut être mise à jour. Nous vous notifierons de toute modification importante par email et dans l'application. La version en vigueur est toujours accessible dans l'application.</p>
</body>
</html>
    `.trim();
  }
}
