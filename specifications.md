

# **Cahier des Charges Technique et Fonctionnel : GoldWen MVP**

Version : 1.1  
Date : 27 août 2025  
Auteur : Votre Product Manager Expert

## **1\. Introduction et Vision du Produit**

### **1.1. Contexte**

Le marché des applications de rencontre est saturé par des modèles axés sur la quantité, engendrant un phénomène de "dating burnout".1 Les utilisateurs, en particulier les 25-40 ans, recherchent des connexions plus profondes et significatives, mais sont épuisés par le "swipe" incessant et la superficialité des interactions.4

### **1.2. Vision de GoldWen**

GoldWen se positionne comme l'antidote à cette fatigue. Notre mission est de valoriser la **qualité des interactions plutôt que la quantité**. En proposant un nombre limité de correspondances hautement compatibles chaque jour, nous encourageons des échanges plus authentiques et intentionnels. Notre slogan, "Conçue pour être désinstallée", incarne notre objectif final : aider nos utilisateurs à trouver une relation durable.

## **2\. Périmètre du Projet (MVP)**

L'objectif de ce MVP est de valider le cœur de notre proposition de valeur : les utilisateurs sont-ils prêts à adopter un modèle de "slow dating" et à payer pour des fonctionnalités qui améliorent cette expérience?

**Inclus dans le MVP :**

* Processus d'inscription et de création de profil complet.  
* Questionnaire de personnalité obligatoire.  
* Algorithme de matching V1 (basé sur le contenu).  
* Présentation d'une sélection quotidienne limitée de profils.  
* Système de match mutuel.  
* Messagerie éphémère (24h).  
* Modèle Freemium avec un niveau d'abonnement (GoldWen Plus).  
* Panneau d'administration basique pour la gestion des utilisateurs et la modération.

**Exclus du MVP (pour la V2) :**

* Profils audio et vidéo.  
* Algorithe de matching V2 (hybride, avec apprentissage machine).  
* Niveaux d'abonnement supérieurs (ex: GoldWen X).  
* Événements communautaires.  
* Vérification de profil par photo/vidéo.

## **3\. Personas Cibles**

* **Sophie, l'Intentionnelle (29 ans) :** Professionnelle urbaine, fatiguée de la superficialité et du "ghosting". Cherche une relation sérieuse et valorise la compatibilité des valeurs.  
* **Marc, le Professionnel Ambitieux (34 ans) :** Carrière exigeante, peu de temps libre. Cherche à optimiser sa recherche en se concentrant sur des profils sérieux pour éviter les pertes de temps.

## **4\. Spécifications Fonctionnelles Détaillées (MVP)**

### **4.1. Module 1 : Onboarding et Création de Profil**

* **User Stories :**  
  * En tant que nouvel utilisateur, je veux m'inscrire facilement via Apple ou Google pour ne pas créer un nouveau mot de passe. 7  
  * En tant que nouvel utilisateur, je veux répondre à un questionnaire de personnalité engageant pour que l'application comprenne mes valeurs.  
  * En tant que nouvel utilisateur, je veux être guidé pour créer un profil complet (photos, prompts) afin de maximiser mes chances.  
* **Critères d'Acceptation :**  
  1. L'écran d'accueil propose les options "S'inscrire avec Google" et "S'inscrire avec Apple".  
  2. L'authentification via un tiers pré-remplit le prénom et l'adresse e-mail.  
  3. L'utilisateur doit obligatoirement répondre aux 10 questions du questionnaire de personnalité pour continuer.  
  4. L'utilisateur doit télécharger un minimum de 3 photos.  
  5. L'utilisateur doit répondre à 3 "prompts" textuels pour finaliser son profil.  
  6. Le profil n'est pas visible par les autres tant que ces conditions ne sont pas remplies.

### **4.2. Module 2 : Le Rituel Quotidien et le Matching**

* **User Stories :**  
  * En tant qu'utilisateur, je veux recevoir une notification par jour à midi m'annonçant que ma sélection est prête.  
  * En tant qu'utilisateur, je veux voir une liste limitée de profils (3 à 5\) pour ne pas être submergé.  
  * En tant qu'utilisateur gratuit, je veux pouvoir choisir un seul profil parmi la sélection pour initier une conversation.  
* **Critères d'Acceptation :**  
  1. Chaque jour à 12h00 (heure locale de l'utilisateur), une notification push est envoyée : "Votre sélection GoldWen du jour est arrivée\!".  
  2. L'écran d'accueil de l'application affiche une liste de 3 à 5 profils, classés par score de compatibilité (V1).  
  3. L'utilisateur peut consulter chaque profil en détail.  
  4. Un utilisateur gratuit peut appuyer sur un bouton "Choisir" sur un seul profil. Une fois le choix fait, un message de confirmation apparaît et les autres profils de la journée disparaissent.  
  5. Si aucun profil n'est choisi, la sélection reste disponible jusqu'à la prochaine actualisation (le lendemain à midi).

### **4.3. Module 3 : Messagerie et Interaction**

* **User Stories :**  
  * En tant qu'utilisateur, je veux pouvoir démarrer une conversation uniquement si l'autre personne m'a aussi choisi (match mutuel).  
  * En tant qu'utilisateur, je veux que la conversation soit limitée à 24 heures pour nous inciter à échanger activement.  
  * En tant qu'utilisateur, je veux voir un compte à rebours visible dans le chat.  
* **Critères d'Acceptation :**  
  1. Une conversation (chat) est créée uniquement lorsque l'Utilisateur A choisit l'Utilisateur B, et que l'Utilisateur B choisit l'Utilisateur A.  
  2. Les deux utilisateurs reçoivent une notification de match : "Félicitations\! Vous avez un match avec \[Prénom\]".  
  3. La fenêtre de chat affiche un minuteur bien visible en haut, démarrant à "24:00:00".  
  4. Le chat permet l'envoi de messages texte et d'emojis.  
  5. À la fin des 24 heures, le chat est archivé et devient inaccessible. Un message système indique "Cette conversation a expiré".

### **4.4. Module 4 : Monétisation (GoldWen Plus)**

* **User Stories :**  
  * En tant qu'utilisateur gratuit, je veux comprendre clairement les avantages d'un abonnement payant.  
  * En tant qu'abonné GoldWen Plus, je veux pouvoir choisir jusqu'à 3 profils dans ma sélection quotidienne.  
* **Critères d'Acceptation :**  
  1. Des bannières non-intrusives dans l'application promeuvent GoldWen Plus avec le message "Passez à GoldWen Plus pour choisir jusqu'à 3 profils par jour".  
  2. Une page d'abonnement claire présente les tarifs (mensuel, trimestriel, semestriel) et gère le paiement via les systèmes natifs d'Apple (App Store) et Google (Play Store).  
  3. Un utilisateur abonné peut "Choisir" jusqu'à 3 profils dans sa sélection quotidienne.  
  4. La gestion de l'abonnement (annulation, modification) est accessible depuis les paramètres du profil.

### **4.5. Module 5 : Panneau d'Administration (Back-Office)**

* **Objectif :** Permettre à l'équipe de GoldWen de gérer la plateforme.  
* **Fonctionnalités :**  
  1. **Gestion des Utilisateurs :** Rechercher, visualiser, suspendre et supprimer des profils utilisateurs.  
  2. **Modération de Contenu :** Un système de "queue" pour examiner les profils et les messages signalés par les utilisateurs. L'administrateur peut décider de supprimer le contenu ou de bannir l'utilisateur.  
  3. **Support Client :** Interface simple pour répondre aux demandes des utilisateurs envoyées via un formulaire de contact dans l'application.

## **5\. Spécifications Non-Fonctionnelles**

* **Performance :** Le temps de chargement de l'application au démarrage doit être inférieur à 3 secondes. La navigation entre les écrans doit être fluide (\< 300ms de latence).  
* **Sécurité :** Toutes les communications entre l'application et les serveurs doivent être chiffrées (HTTPS/TLS). Les données sensibles (mots de passe, messages) doivent être chiffrées au repos. Le respect du RGPD est impératif (voir Annexe A).  
* **Scalabilité :** L'infrastructure doit être conçue pour supporter une croissance rapide du nombre d'utilisateurs, avec un objectif de 100 000 utilisateurs actifs pour la première année.  
* **Disponibilité :** L'application doit viser un taux de disponibilité de 99.5%.

## **6\. Spécifications Techniques (Expertise DevOps, PM, PO)**

### **6.1. Architecture Globale**

Nous adopterons une architecture de **microservices**. Cela permet de découpler les composants clés (authentification, profils, chat, matching), facilitant la maintenance, la scalabilité et le déploiement indépendant de chaque service.

### **6.2. Application Mobile (Front-End)**

* **Technologie :** **Flutter**. C'est une alternative moderne et performante à React Native. Développé par Google, Flutter nous permet de maintenir une **base de code unique** pour iOS et Android, ce qui est idéal pour les objectifs de budget et de rapidité du MVP. Il est particulièrement reconnu pour sa capacité à créer des interfaces utilisateur fluides et expressives, ce qui s'aligne parfaitement avec notre exigence d'un "beau design", tout en offrant des performances quasi-natives.

### **6.3. Services Back-End**

* **API Principale :** **NestJS (Node.js/TypeScript)**. Excellent choix. NestJS offre un cadre structuré et robuste, idéal pour construire une API RESTful/GraphQL scalable. L'écosystème Node.js est performant pour gérer les opérations I/O intensives comme une application de chat.8  
* **Service de Matching :** **Python (avec Flask ou FastAPI)**. Votre suggestion de dédier Python au matching est parfaite. Python est l'écosystème de référence pour la data science et le machine learning.9 Pour le MVP, le service implémentera l'algorithme de filtrage par contenu. Pour la V2, il pourra évoluer vers des modèles plus complexes (filtrage collaboratif, deep learning) sans impacter le reste de l'application.

### **6.4. Bases de Données**

Une approche hybride est recommandée pour optimiser performance et flexibilité :

* **Base de Données Principale :** **PostgreSQL**. Une base de données relationnelle robuste est indispensable pour stocker les données structurées des utilisateurs (profils, réponses au questionnaire, abonnements, relations entre utilisateurs).10 Sa fiabilité et ses fonctionnalités avancées en font un choix sûr.  
* **Base de Données pour le Chat :** **Redis**. Pour la messagerie en temps réel, une base de données en mémoire comme Redis est idéale. Elle offre une latence extrêmement faible, parfaite pour la distribution rapide des messages et la gestion des statuts en ligne.8

### **6.5. Infrastructure et DevOps**

* **Hébergement :** Un fournisseur Cloud majeur comme **AWS, Google Cloud Platform (GCP) ou Azure**. Ils offrent la scalabilité, la sécurité et les services managés dont nous avons besoin.  
* **Conteneurisation :** **Docker**. Tous les microservices (API NestJS, Service Python, etc.) seront conteneurisés avec Docker. Cela garantit la cohérence des environnements de développement, de test et de production.  
* **Orchestration :** **Kubernetes (via un service managé comme GKE, EKS ou AKS)**. Kubernetes automatisera le déploiement, la mise à l'échelle et la gestion de nos conteneurs, ce qui est crucial pour la scalabilité et la haute disponibilité.  
* **CI/CD (Intégration et Déploiement Continus) :** **GitHub Actions** ou **GitLab CI**. Mise en place d'un pipeline automatisé pour les tests et les déploiements afin d'accélérer le cycle de développement et de réduire les erreurs humaines.

### **6.6. Services Tiers**

* **Notifications Push :** Firebase Cloud Messaging (FCM) pour Android et Apple Push Notification Service (APNs) pour iOS.  
* **Paiements :** **RevenueCat**. C'est un excellent choix pour gérer les abonnements in-app. Il abstrait la complexité des API d'Apple et de Google, simplifiant le développement et fournissant des analyses précieuses.  
* **Authentification Sociale :** SDKs officiels de Google et Apple.  
* **Analyse Comportementale :** Mixpanel ou Amplitude pour suivre les KPIs d'engagement et de rétention.

## **7\. Design et Expérience Utilisateur (UX/UI)**

### **7.1. Philosophie de Design : "Calm Technology"**

Le design de GoldWen doit être un différenciateur clé. Il ne doit pas seulement être "beau", il doit être **calme et intentionnel**.12 L'objectif est de réduire l'anxiété et la charge cognitive associées aux applications de rencontre.

* **Minimalisme :** Interfaces épurées, sans éléments superflus. Chaque composant doit avoir un but précis.14  
* **Espace et Respiration :** Utilisation généreuse des espaces blancs pour créer une mise en page aérée et équilibrée.  
* **Interactions Prévisibles et Indulgentes :** L'utilisateur doit toujours savoir ce qu'il se passe. Des micro-interactions subtiles confirmeront les actions. Des messages clairs et rassurants seront utilisés (ex: "Votre choix est fait. Revenez demain pour votre nouvelle sélection.").  
* **Notifications Limitées :** Une seule notification par jour pour la sélection. Pas de notifications pour créer une dépendance.

### **7.2. Identité Visuelle : "Style Or (GoldWen)"**

* **Palette de Couleurs :** Une palette sophistiquée et chaleureuse.  
  * **Primaire :** Un or mat et élégant (ex: \#D4AF37), pas un or brillant ou criard.  
  * **Secondaire :** Des tons crèmes, beiges et blancs cassés pour les fonds.  
  * **Accents :** Un noir ou un gris très foncé pour le texte, assurant une excellente lisibilité.  
* **Typographie :** Une police de caractères Serif élégante pour les titres (ex: Playfair Display) et une police Sans-Serif très lisible pour le corps du texte (ex: Lato, Open Sans).  
* **Iconographie :** Des icônes fines, linéaires et minimalistes.

## **8\. Estimation Budgétaire Indicative (MVP)**

Basé sur les standards du marché pour le développement d'une application de complexité moyenne, voici une estimation des coûts pour le MVP. Les tarifs peuvent varier en fonction de la localisation de l'équipe de développement (les tarifs en Europe de l'Est sont plus bas que ceux en Amérique du Nord).17

| Poste de Dépense | Fourchette de Coût (USD) | Justification |
| :---- | :---- | :---- |
| **Phase 1 : Conception & Stratégie** |  |  |
| Recherche & Planification | 2 000 $ \- 5 000 $ | Analyse de marché, définition du périmètre, spécifications. 17 |
| Design UI/UX | 10 000 $ \- 25 000 $ | Wireframes, prototypes interactifs, design system "Calm Tech". 17 |
| **Phase 2 : Développement** |  |  |
| Développement Front-End (Flutter) | 25 000 $ \- 50 000 $ | Développement des écrans, logique de l'application pour iOS & Android avec une base de code unique. 7 |
| Développement Back-End (NestJS, Python, BDD) | 20 000 $ \- 50 000 $ | API, base de données, logique métier, service de matching V1. 17 |
| Panneau d'Administration | 5 000 $ \- 10 000 $ | Interface web simple pour la gestion interne. |
| **Phase 3 : Qualité & Lancement** |  |  |
| Tests & Assurance Qualité (QA) | 7 000 $ \- 20 000 $ | Tests manuels et automatisés pour garantir une application sans bugs. 17 |
| Déploiement & Infrastructure (DevOps) | 3 000 $ \- 7 000 $ | Configuration des serveurs, CI/CD, publication sur les App Stores. 17 |
| **Total Développement MVP** | **72 000 $ \- 167 000 $** |  |
| **Phase 4 : Post-Lancement (Coûts récurrents)** |  |  |
| Marketing de Lancement | 15 000 $ \- 30 000 $ | Campagnes initiales pour acquérir les premiers utilisateurs. 19 |
| Maintenance Annuelle | 11 000 $ \- 42 000 $ | \~15-25% du coût de développement. Inclut corrections de bugs, mises à jour OS, etc. 20 |
| Modération de Contenu (Annuel) | 10 000 $ \- 50 000 $+ | Coût variable selon le volume. Peut être géré par une équipe interne ou des outils IA. 22 |

**Note :** Le coût total pour lancer et opérer la première année se situerait donc entre **98 000 $ et 239 000 $**.

---

## **Annexe A : Checklist de Conformité RGPD (GDPR)**

La gestion des données personnelles, surtout dans une application de rencontre, est critique. Voici une checklist simplifiée pour le MVP.24

1. **\[ \] Base Légale et Transparence :**  
   * Obtenir un consentement explicite et non ambigu de l'utilisateur lors de l'inscription pour la collecte et le traitement de ses données.  
   * Rédiger une politique de confidentialité claire, accessible et facile à comprendre, expliquant quelles données sont collectées, pourquoi, et comment elles sont utilisées.  
2. **\[ \] Minimisation des Données :**  
   * Ne collecter que les données strictement nécessaires au fonctionnement de l'application. Par exemple, ne pas demander l'accès aux contacts du téléphone.  
3. **\[ \] Droits des Utilisateurs :**  
   * Mettre en place une fonctionnalité dans les paramètres du profil permettant à l'utilisateur de :  
     * **Accéder** à ses données (télécharger une copie de son profil).  
     * **Rectifier** ses informations.  
     * **Supprimer** son compte et toutes les données associées ("droit à l'oubli").  
4. **\[ \] Sécurité par Conception ("Privacy by Design") :**  
   * Chiffrer toutes les données en transit (TLS) et au repos (chiffrement de la base de données).  
   * Anonymiser ou pseudonymiser les données lorsque c'est possible pour les analyses.  
5. **\[ \] Tiers et Sous-traitants :**  
   * S'assurer que tous les services tiers utilisés (hébergeur, analytics, etc.) sont conformes au RGPD et signer des Accords de Traitement des Données (DPA) avec eux.  
6. **\[ \] Notification de Violation de Données :**  
   * Mettre en place un processus interne pour détecter et signaler toute violation de données à l'autorité de contrôle compétente (la CNIL en France) dans les 72 heures.

#### **Sources des citations**

1. Forbes Health Survey: 78% Of All Users Report Dating App Burnout, consulté le août 27, 2025, [https://www.forbes.com/health/dating/dating-app-fatigue/](https://www.forbes.com/health/dating/dating-app-fatigue/)  
2. APPLICATIONS DE RENCONTRES : LE PHÉNOMÈNE DU DATING BURN-OUT, consulté le août 27, 2025, [https://shoelifer.com/lifestyle/reseaux/applications-de-rencontres-phenomene-dating/](https://shoelifer.com/lifestyle/reseaux/applications-de-rencontres-phenomene-dating/)  
3. This is why you're burnt out from using dating apps | CBC News, consulté le août 27, 2025, [https://www.cbc.ca/news/canada/dating-apps-burnout-1.7152917](https://www.cbc.ca/news/canada/dating-apps-burnout-1.7152917)  
4. Rencontres sérieuses : appli, site ou agence matrimoniale ? \- Bonjour Begin, consulté le août 27, 2025, [https://www.bonjour-begin.fr/blog/amour/rencontres-serieuses-appli-site-agence-ou-trouver-lamour-pour-de-vrai/](https://www.bonjour-begin.fr/blog/amour/rencontres-serieuses-appli-site-agence-ou-trouver-lamour-pour-de-vrai/)  
5. Petit guide pour éviter le burn-out des applications de rencontre \- JUST A LITTLE FUN, consulté le août 27, 2025, [https://www.justalittlefun.ca/articles/petit-guide-pour-eviter-le-burn-out-des-applications-de-rencontre](https://www.justalittlefun.ca/articles/petit-guide-pour-eviter-le-burn-out-des-applications-de-rencontre)  
6. "Bienvenue sur Hinge \!", consulté le août 27, 2025, [https://vava.kessel.media/posts/pst\_cfd3a716c2e64cf991c8eeb65b854eea/bienvenue-sur-hinge](https://vava.kessel.media/posts/pst_cfd3a716c2e64cf991c8eeb65b854eea/bienvenue-sur-hinge)  
7. Dating App Development Cost in 2025: Factors and Examples \- Biz4Group, consulté le août 27, 2025, [https://www.biz4group.com/blog/how-much-does-it-cost-to-develop-a-dating-app](https://www.biz4group.com/blog/how-much-does-it-cost-to-develop-a-dating-app)  
8. Real-Time Web Apps in 2025: WebSockets & SSE Guide \- Debut Infotech, consulté le août 27, 2025, [https://www.debutinfotech.com/blog/real-time-web-apps](https://www.debutinfotech.com/blog/real-time-web-apps)  
9. Content-Based vs Collaborative Filtering: Difference \- GeeksforGeeks, consulté le août 27, 2025, [https://www.geeksforgeeks.org/machine-learning/content-based-vs-collaborative-filtering-difference/](https://www.geeksforgeeks.org/machine-learning/content-based-vs-collaborative-filtering-difference/)  
10. How to Create a Dating App From Scratch? Idea to Launch \- Fullestop, consulté le août 27, 2025, [https://www.fullestop.com/blog/how-to-create-a-dating-app-from-scratch](https://www.fullestop.com/blog/how-to-create-a-dating-app-from-scratch)  
11. Build and Deploy a Full Stack Realtime Chat Messaging App with NextJS 13 \- YouTube, consulté le août 27, 2025, [https://www.youtube.com/watch?v=NlXfg5Pxxh8](https://www.youtube.com/watch?v=NlXfg5Pxxh8)  
12. PRINCIPLES \- Calm Tech Institute, consulté le août 27, 2025, [https://www.calmtech.institute/calm-tech-principles](https://www.calmtech.institute/calm-tech-principles)  
13. Designing Calm: UX Principles for Reducing Users' Anxiety \- UXmatters, consulté le août 27, 2025, [https://www.uxmatters.com/mt/archives/2025/05/designing-calm-ux-principles-for-reducing-users-anxiety.php](https://www.uxmatters.com/mt/archives/2025/05/designing-calm-ux-principles-for-reducing-users-anxiety.php)  
14. Harnessing the Calming Power of Design in a Constantly Moving World | by Matthis Rousselle | Bootcamp | Medium, consulté le août 27, 2025, [https://medium.com/design-bootcamp/harnessing-the-calming-power-of-design-in-a-constantly-moving-world-4f7d478931b8](https://medium.com/design-bootcamp/harnessing-the-calming-power-of-design-in-a-constantly-moving-world-4f7d478931b8)  
15. Principles of Calm Technology, consulté le août 27, 2025, [https://principles.design/examples/principles-of-calm-technology](https://principles.design/examples/principles-of-calm-technology)  
16. UX Strategies for Improving Digital Well-Being \- Divami, consulté le août 27, 2025, [https://divami.com/news/ux-strategies-for-improving-digital-well-being/](https://divami.com/news/ux-strategies-for-improving-digital-well-being/)  
17. How Much Does It Cost to Build A Dating App in 2025? \- JPLoft, consulté le août 27, 2025, [https://www.jploft.com/blog/cost-to-build-a-dating-app](https://www.jploft.com/blog/cost-to-build-a-dating-app)  
18. How Much Does It Cost to Maintain an App in 2025? \[+4 Tips\] \- Space-O Technologies, consulté le août 27, 2025, [https://www.spaceotechnologies.com/blog/how-much-does-it-cost-to-maintain-app/](https://www.spaceotechnologies.com/blog/how-much-does-it-cost-to-maintain-app/)  
19. Dating App Development Cost: Know Everything in Detail\! \- Apptunix, consulté le août 27, 2025, [https://www.apptunix.com/blog/how-much-does-it-cost-to-create-a-dating-app/](https://www.apptunix.com/blog/how-much-does-it-cost-to-create-a-dating-app/)  
20. Mobile App Maintenance Costs: What to Expect After Launch \- Closeloop Technologies, consulté le août 27, 2025, [https://closeloop.com/blog/mobile-app-maintenance-cost-after-launch/](https://closeloop.com/blog/mobile-app-maintenance-cost-after-launch/)  
21. How Much Does It Cost To Maintain an App \- DesignRush, consulté le août 27, 2025, [https://www.designrush.com/agency/mobile-app-design-development/trends/how-much-does-it-cost-to-maintain-an-app](https://www.designrush.com/agency/mobile-app-design-development/trends/how-much-does-it-cost-to-maintain-an-app)  
22. Content Moderation Services Pricing Guide August 2025 \- Clutch, consulté le août 27, 2025, [https://clutch.co/content-moderation/pricing](https://clutch.co/content-moderation/pricing)  
23. Pricing \- Moderation API, consulté le août 27, 2025, [https://moderationapi.com/pricing](https://moderationapi.com/pricing)  
24. GDPR Compliance Checklist to follow in a scalable MVP app \- Blog \- You are launched, consulté le août 27, 2025, [https://blog.urlaunched.com/gdpr-compliance-checklist-to-follow-for-scaleable-mvp-app/](https://blog.urlaunched.com/gdpr-compliance-checklist-to-follow-for-scaleable-mvp-app/)  
25. GDPR compliance checklist \- GDPR.eu, consulté le août 27, 2025, [https://gdpr.eu/checklist/](https://gdpr.eu/checklist/)  
26. GDPR Compliance in the US: Checklist and Requirements \- Legit Security, consulté le août 27, 2025, [https://www.legitsecurity.com/aspm-knowledge-base/gdpr-compliance-us-checklist](https://www.legitsecurity.com/aspm-knowledge-base/gdpr-compliance-us-checklist)  
27. GDPR compliance for mobile apps: a developer's guide \- Appwrite, consulté le août 27, 2025, [https://appwrite.io/blog/post/gdpr-compliance-mobile-apps-alternative-firebase](https://appwrite.io/blog/post/gdpr-compliance-mobile-apps-alternative-firebase)