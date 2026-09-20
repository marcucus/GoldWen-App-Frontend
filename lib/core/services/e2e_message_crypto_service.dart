import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'e2e_key_service.dart';

/// Chiffrement / déchiffrement de bout en bout des messages du chat
/// (AV-15 / V106).
///
/// Protocole : X25519 (ECDH) entre la clé privée de cet appareil et la clé
/// publique de l'interlocuteur pour dériver (via HKDF-SHA256) un secret
/// partagé par paire, puis AES-256-GCM avec un nonce aléatoire par message.
/// Le blob envoyé au serveur (et stocké dans `SendMessageDto.content`) est
/// `base64(nonce(12) + ciphertext + tag(16))` — le serveur ne voit et ne
/// stocke jamais que cette valeur opaque, jamais le texte en clair.
///
/// Limite assumée, à ne jamais présenter comme plus que ce qu'elle est :
/// ceci est un chiffrement STATIQUE par paire, pas un ratchet façon
/// Signal/WhatsApp. Il n'y a ni forward secrecy ni sécurité
/// post-compromission : si la clé privée d'un appareil fuit un jour, tous
/// les messages passés ET futurs de ses conversations redeviennent
/// déchiffrables avec elle. C'est un compromis délibéré (complexité
/// d'implémentation contre garanties cryptographiques les plus fortes
/// possibles), pas un oubli. Voir PLAN_FINALISATION.md, AV-15 : une revue de
/// sécurité externe est recommandée avant toute communication publique
/// présentant ce chiffrement comme "audité".
class E2eMessageCryptoService {
  E2eMessageCryptoService._();

  static final E2eMessageCryptoService instance =
      E2eMessageCryptoService._();

  static const int _nonceLength = 12; // standard AES-GCM
  static const int _macLength = 16; // tag AES-256-GCM
  static const String _hkdfInfo = 'goldwen-chat-e2e-v1';

  final X25519 _x25519 = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Map<String, SecretKey> _sharedKeyCache = <String, SecretKey>{};

  /// Dérive (avec mise en cache mémoire, jamais persistée) le secret
  /// partagé AES-256 pour un interlocuteur donné, à partir de la clé privée
  /// de cet appareil et de la clé publique (base64) de l'interlocuteur —
  /// telle que renvoyée par l'API dans son profil (`User.publicKey`). Le
  /// résultat est identique quel que soit le sens de la conversation :
  /// ECDH(a_priv, b_pub) == ECDH(b_priv, a_pub).
  Future<SecretKey> _sharedKeyFor(String peerPublicKeyBase64) async {
    final cached = _sharedKeyCache[peerPublicKeyBase64];
    if (cached != null) {
      return cached;
    }

    final myKeyPair = await E2eKeyService.instance.getOrCreateKeyPair();
    final peerPublicKey = SimplePublicKey(
      base64Decode(peerPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    final rawSharedSecret = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: peerPublicKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: rawSharedSecret,
      nonce: const <int>[],
      info: utf8.encode(_hkdfInfo),
    );

    _sharedKeyCache[peerPublicKeyBase64] = derivedKey;
    return derivedKey;
  }

  /// Chiffre [plainText] pour l'interlocuteur dont la clé publique est
  /// [peerPublicKeyBase64]. Retourne un blob base64 prêt à être envoyé tel
  /// quel dans `SendMessageDto.content`.
  Future<String> encryptMessage({
    required String plainText,
    required String peerPublicKeyBase64,
  }) async {
    final secretKey = await _sharedKeyFor(peerPublicKeyBase64);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    return base64Encode(secretBox.concatenation());
  }

  /// Déchiffre un `content` reçu du serveur pour l'interlocuteur
  /// [peerPublicKeyBase64]. Retourne `null` — jamais une exception, jamais
  /// un contenu partiel ou du binaire brut affiché tel quel — si le blob
  /// n'est pas déchiffrable pour cette paire : message envoyé avant
  /// l'activation du chiffrement (contenu en clair pré-existant), clé
  /// publique de l'interlocuteur qui a changé depuis, ou corruption.
  /// L'appelant doit afficher un état explicite ("message illisible")
  /// plutôt que de faire confiance à une valeur de repli.
  Future<String?> decryptMessage({
    required String content,
    required String peerPublicKeyBase64,
  }) async {
    try {
      final secretKey = await _sharedKeyFor(peerPublicKeyBase64);
      final bytes = base64Decode(content);
      final secretBox = SecretBox.fromConcatenation(
        bytes,
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final clearBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(clearBytes);
    } catch (_) {
      return null;
    }
  }
}
