import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

/// Gère la paire de clés X25519 de l'appareil pour le chiffrement de bout en
/// bout du chat (AV-15 / V106).
///
/// La clé privée est générée une seule fois par appareil, stockée dans le
/// trousseau sécurisé de l'OS (Keychain iOS / Keystore Android, via
/// flutter_secure_storage) et ne le quitte JAMAIS — ni vers le serveur, ni
/// vers les logs. Seule la clé publique (base64) est envoyée au backend via
/// `PUT /users/me/public-key`, pour être distribuée aux autres participants
/// d'une conversation par les réponses API existantes (le champ
/// `User.publicKey`, non filtré côté serveur car ce n'est pas une donnée
/// secrète — voir user.entity.ts côté backend).
///
/// Limite assumée : une seule paire de clés par appareil, pas de gestion
/// multi-appareils (se connecter sur un second appareil génère une seconde
/// paire de clés, qui n'a pas accès aux messages déchiffrables avec la
/// première tant qu'aucune synchronisation de clés n'est mise en place —
/// hors périmètre de ce correctif).
class E2eKeyService {
  E2eKeyService._();

  static final E2eKeyService instance = E2eKeyService._();

  static const _privateKeyStorageKey = 'e2e_x25519_private_key_v1';
  static const _publicKeyStorageKey = 'e2e_x25519_public_key_v1';
  static const _uploadedPublicKeyStorageKey =
      'e2e_x25519_public_key_uploaded_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final X25519 _algorithm = X25519();

  SimpleKeyPair? _cachedKeyPair;
  String? _cachedPublicKeyBase64;

  /// Retourne la paire de clés de l'appareil, en la générant au premier
  /// appel si elle n'existe pas encore (nouvelle installation, ou appareil
  /// n'ayant jamais utilisé le chat chiffré).
  Future<SimpleKeyPair> getOrCreateKeyPair() async {
    final cachedKeyPair = _cachedKeyPair;
    if (cachedKeyPair != null) {
      return cachedKeyPair;
    }

    final storedPrivateB64 =
        await _secureStorage.read(key: _privateKeyStorageKey);
    final storedPublicB64 =
        await _secureStorage.read(key: _publicKeyStorageKey);

    if (storedPrivateB64 != null && storedPublicB64 != null) {
      final privateBytes = base64Decode(storedPrivateB64);
      final publicBytes = base64Decode(storedPublicB64);
      final keyPair = SimpleKeyPairData(
        privateBytes,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      _cachedKeyPair = keyPair;
      _cachedPublicKeyBase64 = storedPublicB64;
      return keyPair;
    }

    final keyPair = await _algorithm.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicB64 = base64Encode(publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyStorageKey,
      value: base64Encode(privateBytes),
    );
    await _secureStorage.write(
      key: _publicKeyStorageKey,
      value: publicB64,
    );

    _cachedKeyPair = keyPair;
    _cachedPublicKeyBase64 = publicB64;
    return keyPair;
  }

  /// Clé publique (base64) de cet appareil.
  Future<String> getPublicKeyBase64() async {
    final cached = _cachedPublicKeyBase64;
    if (cached != null) {
      return cached;
    }
    final keyPair = await getOrCreateKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final publicB64 = base64Encode(publicKey.bytes);
    _cachedPublicKeyBase64 = publicB64;
    return publicB64;
  }

  /// À appeler après connexion / au démarrage de l'app pour s'assurer que le
  /// serveur a bien la clé publique courante de cet appareil. N'envoie une
  /// requête réseau que si la clé n'a encore jamais été confirmée envoyée
  /// (évite un appel réseau à chaque démarrage). Les échecs réseau sont
  /// avalés : ce n'est pas bloquant pour l'utilisation de l'app, seulement
  /// pour la capacité des AUTRES à lui envoyer des messages chiffrés tant
  /// que ce n'est pas retenté avec succès.
  Future<void> ensurePublicKeyUploaded() async {
    final publicKeyB64 = await getPublicKeyBase64();
    final alreadyUploadedFor =
        await _secureStorage.read(key: _uploadedPublicKeyStorageKey);
    if (alreadyUploadedFor == publicKeyB64) {
      return;
    }
    try {
      await ApiService.updatePublicKey(publicKey: publicKeyB64);
      await _secureStorage.write(
        key: _uploadedPublicKeyStorageKey,
        value: publicKeyB64,
      );
    } catch (_) {
      // Best-effort : on retentera au prochain appel (prochain démarrage,
      // ou après reconnexion réseau). Ne jamais bloquer l'app là-dessus.
    }
  }

  /// Supprime la paire de clés de cet appareil. Volontairement PAS appelé
  /// sur une simple déconnexion (`logout`) : une déconnexion classique ne
  /// doit pas faire perdre l'accès aux conversations en cours à la
  /// reconnexion sur le même appareil. À réserver à la suppression de
  /// compte / réinitialisation complète de l'appareil.
  Future<void> deleteKeyPair() async {
    await _secureStorage.delete(key: _privateKeyStorageKey);
    await _secureStorage.delete(key: _publicKeyStorageKey);
    await _secureStorage.delete(key: _uploadedPublicKeyStorageKey);
    _cachedKeyPair = null;
    _cachedPublicKeyBase64 = null;
  }
}
