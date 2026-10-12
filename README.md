# Dokan Client — Application Mobile E-Commerce (Flutter)

Application mobile e-commerce Android développée avec le framework **Flutter**, utilisant **Riverpod** pour la gestion d'état, **GoRouter** pour la navigation déclarative, et un thème **Material 3** entièrement isolé.

Ce projet correspond aux **Étapes 1 à 5** du cahier des charges client (Fondations, Catalogue, Recherche & Filtres, Authentification & Visiteur/Client, Favoris & Panier Réactif).

---

## 📚 Documentation Technique Complète

Une documentation complète et pédagogique a été rédigée spécialement pour les étudiants et développeurs dans le dossier [`docs/`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/) :

1. [`docs/01_vue_ensemble.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/01_vue_ensemble.md) — Présentation du projet, architecture en couches ASCII et cycle de vie d'une action.
2. [`docs/02_arborescence_et_fichiers.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/02_arborescence_et_fichiers.md) — Inventaire détaillé des 48 fichiers source de `lib/`.
3. [`docs/03_ecrans_et_navigation.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/03_ecrans_et_navigation.md) — Fonctionnement de GoRouter, StatefulShellRoute et flux Visiteur vs Client.
4. [`docs/04_etat_et_donnees.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/04_etat_et_donnees.md) — Riverpod, modèles de données, Repository pattern et transition vers une vraie API.
5. [`docs/05_theme_et_interface.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/05_theme_et_interface.md) — Thème isolé (aucune couleur hors de `app_colors.dart`), composants UI et accessibilité.
6. [`docs/06_glossaire.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/06_glossaire.md) — Définitions simples de tous les mots techniques Flutter avec exemples du projet.
7. [`docs/07_questions_et_reponses.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/07_questions_et_reponses.md) — FAQ complète répondant aux questions d'architecture et de conception.
8. [`docs/08_comment_lancer_et_tester.md`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/docs/08_comment_lancer_et_tester.md) — Guide de lancement, commandes terminal et scénarios de démonstration orale.

---

## 🚀 Démarrage Rapide

### Prérequis
* Flutter SDK (3.47+) & Dart SDK (3.0+)
* Un émulateur Android ou appareil physique connecté

### Commandes
```powershell
# 1. Télécharger les packages
flutter pub get

# 2. Vérifier la qualité du code (0 erreur, 0 warning)
flutter analyze

# 3. Lancer les tests
flutter test

# 4. Exécuter l'application
flutter run
```

---

## 🔑 Identifiants & Codes de Test

* **Compte Démo Valide** : `demo@Dokan.com` / `Demo1234`
* **Compte de Test d'Échec** : `fail@Dokan.com` / `n'importe_quoi`
* **Code Promo Panier (-10 %)** : `Dokan10`
* **Mots-clés de test dans la recherche** :
  * `#error` : Simule une panne réseau avec bouton Réessayer
  * `#empty` : Simule une recherche sans résultat
