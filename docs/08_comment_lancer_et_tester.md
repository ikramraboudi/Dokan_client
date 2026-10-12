# 08 — Comment Lancer, Tester et Démontrer l'Application

Ce guide pratique récapitule toutes les commandes en ligne de commande pour compiler, analyser et tester l'application Dokan Client, ainsi que la checklist complète pour une démonstration orale sans accroc.

---

## 1. Prérequis Système

* **Flutter SDK** : Version 3.47+ installée et configurée dans la variable d'environnement `PATH`.
* **Dart SDK** : Version 3.0+ avec Null-Safety activée par défaut.
* **Cible** : Émulateur Android (AVD) ou smartphone physique connecté en mode débogage USB, ou navigateur Chrome pour le test rapide.

---

## 2. Commandes Utiles en Terminal

Placez-vous dans le répertoire du projet :
```powershell
cd "c:\3 eme\proj_flutter\e-commerce\client\Dokan_client"
```

### 1. Télécharger les dépendances
```powershell
flutter pub get
```

### 2. Lancer l'analyse statique du code (Qualité & Normes)
Cette commande inspecte l'intégralité du code source pour s'assurer qu'il n'y a aucun avertissement, aucune importation inutile et aucun non-respect des règles Dart :
```powershell
flutter analyze
```
*Résultat attendu* : `No issues found!`

### 3. Exécuter les tests automatisés
Lance la suite de tests d'intégration et de fumée :
```powershell
flutter test
```
*Résultat attendu* : `All tests passed!`

### 4. Lancer l'application sur un appareil connecté
```powershell
flutter run
```

---

## 3. Données de Démonstration à Connaître par Cœur

Pour faire une démonstration fluide devant un enseignant ou un jury, mémorisez ces valeurs clés :

| Élément | Valeur à utiliser | Comportement attendu |
| :--- | :--- | :--- |
| **Compte Démo Valide** | `demo@Dokan.com` / `Demo1234` | Connexion instantanée avec le profil client "Amine Ben Salem". |
| **Compte Test d'Échec** | `fail@Dokan.com` / n'importe quel mot de passe | Affichage d'un message d'erreur d'identifiants incorrects. |
| **Code Promotionnel Panier** | `Dokan10` | Applique immédiatement **10 % de réduction** sur le montant du panier. |
| **Test d'Erreur Réseau** | Taper `#error` dans la recherche | Déclenche l'écran d'erreur avec bouton « Réessayer ». |
| **Test de Recherche Vide** | Taper `#empty` dans la recherche | Déclenche l'écran « Aucun résultat trouvé ». |
| **Boutons hors périmètre** | Tout bouton de commande finale, avis, profil | Déclenche le SnackBar officiel : *« Cette fonctionnalité sera disponible prochainement. »* |

---

## 4. Checklist de Démonstration en 2 Parcours

### Parcours A : L'expérience du Visiteur Anonyme (Découverte)
1. **Démarrage** : Ouvrir l'application. Observer le Splash Screen pendant 3 secondes, puis l'arrivée automatique sur l'Accueil.
2. **Consultation** :
   * Parcourir les bannières dégradées et les faire glisser horizontalement.
   * Faire défiler toute la page d'accueil de haut en bas pour montrer que le dernier produit est parfaitement visible.
3. **Catégories & Catalogue** :
   * Cliquer sur une catégorie (ex: « Vêtements ») pour ouvrir le catalogue pré-filtré.
   * Ouvrir la feuille de filtres (`Filtrer`), ajuster la fourchette de prix avec le double curseur, valider.
   * Constater l'apparition des puces amovibles (`InputChip`) en haut de liste.
   * Cliquer sur la croix d'une puce pour retirer le filtre.
4. **Fiche Produit** :
   * Toucher un article pour ouvrir sa fiche détaillée.
   * Faire glisser la galerie photos.
   * Sélectionner une taille via les puces `ChoiceChip`.
   * Ajuster la quantité avec le sélecteur `[+]`.
   * Toucher le cœur des favoris : **Observer la boîte de dialogue d'invitation à la connexion**. Cliquer sur Annuler.
   * Toucher « Ajouter au panier » : Constater le SnackBar de confirmation et l'apparition du badge numérique sur l'onglet Panier !
5. **Onglet Favoris** :
   * Cliquer sur l'onglet Favoris dans la barre de navigation.
   * Vérifier que la page affiche bien le cadenas « Connexion requise » sans aucun favori exposé.

### Parcours B : L'expérience du Client Connecté (Achat & Profil)
1. **Connexion avec action mémorisée (*Pending Action*)** :
   * Revenir sur la fiche produit et retoucher le cœur des favoris.
   * Dans le dialogue qui s'ouvre, choisir « Se connecter ».
   * Utiliser les identifiants pré-remplis (`demo@Dokan.com` / `Demo1234`) et valider.
   * Observer le retour automatique sur la fiche produit : l'icône cœur est devenue rouge corail toute seule !
2. **Vérification des Favoris** :
   * Aller dans l'onglet Favoris : le produit est bien présent dans la grille.
   * Toucher à nouveau le cœur pour le retirer : l'article disparaît immédiatement de la liste.
3. **Panier d'achat** :
   * Aller dans l'onglet Panier.
   * Vérifier que l'article ajouté en mode visiteur est toujours présent !
   * Augmenter sa quantité de 1 à 2 : observer le recalcul immédiat du sous-total et du total.
   * Saisir le code promo `Dokan10` et cliquer sur « Appliquer » : observer l'apparition de la ligne de remise verte et la baisse du total TTC.
   * Faire glisser l'article vers la gauche ou cliquer sur la corbeille pour le supprimer : un SnackBar avec bouton « Annuler » apparaît. Cliquer sur « Annuler » : l'article réapparaît instantanément à sa place.
   * Cliquer sur « Continuer la commande » : le SnackBar *« Cette fonctionnalité sera disponible prochainement »* s'affiche sans planter.
4. **Profil Client** :
   * Aller dans l'onglet Profil : observer l'avatar avec les initiales "AB" et le nom "Amine Ben Salem".
   * Tester l'outil de simulation de session expirée.
   * Cliquer sur « Se déconnecter » : valider la boîte de dialogue de confirmation.
   * Observer le retour immédiat en mode visiteur sur tous les onglets !
