/// ============================================================================
/// RÔLE DU FICHIER :
/// Point d'entrée exécutable principal de l'application mobile Dokan.
/// Il initialise les liaisons Flutter et démarre l'arbre de widgets en
/// l'enveloppant dans le conteneur global de gestion d'état Riverpod.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche Racine (Démarrage / Bootstrap).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : Le moteur Flutter au lancement de l'application.
/// - Dépend de :
///   * package:flutter_riverpod pour ProviderScope.
///   * app.dart pour le widget racine DokanApp.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Fonction principale (point d'entrée Dart).
///
/// MOT TECHNIQUE - WidgetsFlutterBinding.ensureInitialized() :
/// Vérifie que le moteur graphique et les canaux de communication natifs
/// (plugins, affichage) sont opérationnels avant de lancer des opérations.
///
/// MOT TECHNIQUE - ProviderScope :
/// Widget racine obligatoire de Riverpod qui stocke tous les états
/// de l'application (session, panier, favoris, repositories). Sans lui,
/// aucun provider ne peut fonctionner.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: DokanApp(),
    ),
  );
}