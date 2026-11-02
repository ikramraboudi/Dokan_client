# Dokan Client — Application Mobile E-Commerce (Flutter & Firebase)

Application mobile e-commerce Android développée avec le framework **Flutter**, utilisant **Riverpod** pour la gestion d'état réactive, **GoRouter** pour la navigation déclarative à 5 onglets persistants, **Google Firebase** (Auth & Cloud Firestore temps réel) pour le backend, et un thème **Material 3** entièrement isolé sans aucune couleur en dur.

Ce projet couvre l'intégralité du cycle e-commerce : Découverte du catalogue, recherche & filtres multicritères, authentification sécurisée & mode visiteur/client, gestion réactive du panier, passage de commande atomique avec relecture des prix, et suivi de livraison en temps réel avec chronologie d'étapes.

---

## 📚 Documentation Technique Complète

Une documentation complète, structurée et pédagogique a été rédigée spécialement pour la soutenance et la présentation devant le professeur dans le dossier [`docs/`](docs/) :

### Guides Fondamentaux d'Architecture
1. [`docs/01_vue_ensemble.md`](docs/01_vue_ensemble.md) — Présentation générale du projet, architecture en couches ASCII et cycle de vie d'une action.
2. [`docs/02_arborescence_et_fichiers.md`](docs/02_arborescence_et_fichiers.md) — Inventaire détaillé de l'ensemble des fichiers source de `lib/`.
3. [`docs/03_ecrans_et_navigation.md`](docs/03_ecrans_et_navigation.md) — Fonctionnement de GoRouter, StatefulShellRoute, animations du Splash et flux Visiteur vs Client.
4. [`docs/04_etat_et_donnees.md`](docs/04_etat_et_donnees.md) — Riverpod, modèles de données, Repository pattern et transition vers une vraie API.
5. [`docs/05_theme_et_interface.md`](docs/05_theme_et_interface.md) — Thème isolé (aucune couleur hors de `app_colors.dart`), composants UI et accessibilité.
6. [`docs/06_glossaire.md`](docs/06_glossaire.md) — Définitions simples de tous les mots techniques Flutter avec exemples du projet.
7. [`docs/07_questions_et_reponses.md`](docs/07_questions_et_reponses.md) — FAQ générale répondant aux questions d'architecture et de conception.
8. [`docs/08_comment_lancer_et_tester.md`](docs/08_comment_lancer_et_tester.md) — Guide de lancement, commandes terminal et scénarios de démonstration orale.

### Guides de Soutenance Approfondis (Flux de Commande & Firebase)
9. [`docs/09_flux_de_commande_firebase.md`](docs/09_flux_de_commande_firebase.md) — **LE DOCUMENT PRINCIPAL DE SOUTENANCE** : Schéma de séquence ASCII, 13 étapes détaillées du panier à la livraison, schéma Firestore `orders/{orderId}` officiel, règles de sécurité expliquées ligne par ligne, index composite et répartition des rôles Admin/Livreur.
10. [`docs/10_firebase_dans_lapp.md`](docs/10_firebase_dans_lapp.md) — Vue d'ensemble de Firebase (Auth, Firestore produits, commandes, adresses, initialisation native, tableau action → méthode Firebase, et état des futures migrations).
11. [`docs/11_elements_ui_et_composants.md`](docs/11_elements_ui_et_composants.md) — **« Avec quoi est fait chaque élément ? »** : Tableaux exhaustifs pour chaque écran et pour `core/ui/` avec widgets Flutter utilisés, lignes de code, justification et phrase simple pour le prof.
12. [`docs/12_recapitulatif_par_page.md`](docs/12_recapitulatif_par_page.md) — Fiches d'identité par écran (~20 écrans) avec rôles, visuels, actions, flux de navigation, données, et question probable du prof avec réponse immédiate.
13. [`docs/13_questions_du_prof.md`](docs/13_questions_du_prof.md) — **FICHE DE RÉVISION INTENSIVE** : Pitch oral de 2 minutes chrono, lexique des 15 mots indispensables, et plus de 40 questions d'examen avec réponses de 30 secondes citant fichiers et fonctions.
14. [`docs/POINTS_A_SURVEILLER.md`](docs/POINTS_A_SURVEILLER.md) — Analyse honnête et constructive des limites actuelles, incohérences mineures et axes d'amélioration pour la production.

### Spécifications d'Interopérabilité
15. [`docs/FIREBASE_COMMANDES_SCHEMA.md`](docs/FIREBASE_COMMANDES_SCHEMA.md) — Spécification du contrat d'échange partagé entre Client, Admin et Livreur.
16. [`docs/FIREBASE_ETAPES.md`](docs/FIREBASE_ETAPES.md) — Guide de configuration de la console Firebase (règles de sécurité et index).

---

## 🚀 Démarrage Rapide

### Prérequis
* Flutter SDK (3.24+) & Dart SDK (3.5+)
* Un émulateur Android ou appareil physique connecté

### Commandes
```powershell
# 1. Télécharger les dépendances
flutter pub get

# 2. Vérifier la qualité du code (0 erreur, 0 warning)
flutter analyze

# 3. Lancer les tests unitaires et fonctionnels
flutter test

# 4. Exécuter l'application
flutter run
```

---

## 🔑 Identifiants & Données de Test

* **Compte Démo Valide** : `demo@Dokan.com` / `Demo1234`
* **Compte de Test d'Échec** : `fail@Dokan.com` / `n'importe_quoi`
* **Promotions & Remises** : Gérées directement par l'application Admin (le Client n'écrit jamais de code promo).
* **Mots-clés de test dans la recherche** :
  * `#error` : Simule une panne réseau avec bouton Réessayer
  * `#empty` : Simule une recherche sans résultat
