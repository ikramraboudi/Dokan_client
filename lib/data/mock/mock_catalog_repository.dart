/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation simulée du catalogue de produits et des catégories (`MockCatalogRepository`).
///
/// CONTENU DU JEU D'ESSAI :
/// - 7 catégories thématiques avec icônes distinctes.
/// - 35 fiches produits complètes avec photos réelles Picsum, descriptions,
///   variantes, prix en dinars tunisiens et notes d'évaluation.
///
/// FONCTIONNALITÉS DE SIMULATION & TEST :
/// - Mots-clés de recherche spéciaux :
///   * `#error` : Déclenche volontairement une panne réseau simulée.
///   * `#empty` : Renvoie une liste vide de résultats.
/// - Moteur de recherche local filtrant par mot-clé, prix, catégorie, stock et tri.
/// - Pagination simulée (lot de 6 à 10 articles par page).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/mock/` (Source de Données Catalogue Simulée).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `catalogRepositoryProvider`.
/// - Consommé par : `HomeScreen`, `CatalogScreen`, `SearchScreen`, `ProductDetailScreen`.
/// - Dépend de : `data/repositories/catalog_repository.dart`, `category_ui_model.dart`, `product_ui_model.dart`.
/// ============================================================================
// DONNÉES FICTIVES
// TODO API : Brancher sur les endpoints GET /api/categories et GET /api/products de l'API réelle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_ui_model.dart';
import '../models/product_ui_model.dart';
import '../repositories/catalog_repository.dart';

/// Implémentation simulée du catalogue de produits Dokan.
class MockCatalogRepository implements CatalogRepository {
  /// Latence réseau simulée (500 ms) pour tester les indicateurs de chargement (shimmer).
  final Duration latency;

  MockCatalogRepository({this.latency = const Duration(milliseconds: 500)});

  // --- 7 Catégories de base ---
  static const List<CategoryUiModel> _baseCategories = [
    CategoryUiModel(
      id: 'cat-1',
      name: 'Vêtements et mode',
      icon: Icons.checkroom_rounded,
    ),
    CategoryUiModel(
      id: 'cat-2',
      name: 'Chaussures et accessoires',
      icon: Icons.watch_rounded,
    ),
    CategoryUiModel(
      id: 'cat-3',
      name: 'Beauté et soins',
      icon: Icons.spa_rounded,
    ),
    CategoryUiModel(
      id: 'cat-4',
      name: 'Électronique et technologie',
      icon: Icons.devices_rounded,
    ),
    CategoryUiModel(
      id: 'cat-5',
      name: 'Maison et décoration',
      icon: Icons.chair_rounded,
    ),
    CategoryUiModel(
      id: 'cat-6',
      name: 'Sport et loisirs',
      icon: Icons.fitness_center_rounded,
    ),
    CategoryUiModel(
      id: 'cat-7',
      name: 'Enfants et bébé',
      icon: Icons.child_care_rounded,
    ),
  ];

  // --- Catalogue de 35 produits réalistes ---
  static const List<ProductUiModel> _mockProducts = [
    // --- 1. Vêtements et mode (5 produits) ---
    ProductUiModel(
      id: 'prod-101',
      name: 'Chemise en lin premium à manches retroussables',
      description: 'Chemise en pur lin naturel respirant. Coupe droite moderne idéale pour les journées ensoleillées avec finition col italien.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p101-1/600/600',
        'https://picsum.photos/seed/Dokan-p101-2/600/600',
        'https://picsum.photos/seed/Dokan-p101-3/600/600',
      ],
      price: 89.900,
      oldPrice: 119.900,
      discountLabel: '-25%',
      availability: ProductAvailability.inStock,
      categoryName: 'Vêtements et mode',
      rating: 4.8,
      reviewCount: 42,
      variants: ['S', 'M', 'L', 'XL'],
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-102',
      name: 'Robe longue bohème imprimée motifs floraux',
      description: 'Robe fluide et légère en voile de coton avec ceinture nouable à la taille et manches ballon délicates.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p102-1/600/600',
        'https://picsum.photos/seed/Dokan-p102-2/600/600',
      ],
      price: 135.000,
      oldPrice: 165.000,
      discountLabel: '-18%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Vêtements et mode',
      rating: 4.6,
      reviewCount: 29,
      variants: ['36', '38', '40', '42'],
      isNew: true,
      isPopular: false,
    ),
    ProductUiModel(
      id: 'prod-103',
      name: 'Veste blazer casual coupe cintrée en sergé de laine',
      description: 'Veste intemporelle pour le bureau ou les sorties décontractées. Poches passepoilées et doublure satinée contrastante.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p103-1/600/600',
        'https://picsum.photos/seed/Dokan-p103-2/600/600',
      ],
      price: 185.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Vêtements et mode',
      rating: 4.9,
      reviewCount: 54,
      variants: ['48', '50', '52'],
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-104',
      name: 'Pantalon chino stretch confort coupe ajustée',
      description: 'Chino en coton peigné sergé avec élasthanne pour une totale liberté de mouvement toute la journée.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p104-1/600/600',
        'https://picsum.photos/seed/Dokan-p104-2/600/600',
      ],
      price: 79.500,
      availability: ProductAvailability.inStock,
      categoryName: 'Vêtements et mode',
      rating: 4.4,
      reviewCount: 18,
      variants: ['Beige', 'Bleu marine', 'Kaki'],
    ),
    ProductUiModel(
      id: 'prod-105',
      name: 'Manteau en drap de laine col tailleur élégant',
      description: 'Pièce maîtresse d\'hiver confectionnée dans un tissu lourd et chaud, fermeture double boutonnage.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p105-1/600/600',
        'https://picsum.photos/seed/Dokan-p105-2/600/600',
      ],
      price: 249.000,
      oldPrice: 320.000,
      discountLabel: '-22%',
      availability: ProductAvailability.outOfStock,
      categoryName: 'Vêtements et mode',
      rating: 4.7,
      reviewCount: 31,
      variants: ['Noir', 'Camel'],
    ),

    // --- 2. Chaussures et accessoires (5 produits) ---
    ProductUiModel(
      id: 'prod-201',
      name: 'Sneakers urbaines en cuir suédé beige et blanc',
      description: 'Baskets légères avec semelle ergonomique en caoutchouc naturel amortissant, doublure textile respirante.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p201-1/600/600',
        'https://picsum.photos/seed/Dokan-p201-2/600/600',
        'https://picsum.photos/seed/Dokan-p201-3/600/600',
      ],
      price: 159.000,
      oldPrice: 199.000,
      discountLabel: '-20%',
      availability: ProductAvailability.inStock,
      categoryName: 'Chaussures et accessoires',
      rating: 4.7,
      reviewCount: 65,
      variants: ['40', '41', '42', '43', '44'],
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-202',
      name: 'Sac cabas en cuir véritable grainé avec bandoulière',
      description: 'Sac à main spacieux avec compartiment matelassé pour tablette et fermoir magnétique doré.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p202-1/600/600',
        'https://picsum.photos/seed/Dokan-p202-2/600/600',
      ],
      price: 219.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Chaussures et accessoires',
      rating: 4.9,
      reviewCount: 88,
      variants: ['Cognac', 'Noir ébène', 'Bordeaux'],
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-203',
      name: 'Montre analogique classique cadran minimaliste et bracelet cuir',
      description: 'Mouvement à quartz japonais de précision, boîtier en acier inoxydable et verre minéral résistant.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p203-1/600/600',
        'https://picsum.photos/seed/Dokan-p203-2/600/600',
      ],
      price: 129.900,
      oldPrice: 169.900,
      discountLabel: '-24%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Chaussures et accessoires',
      rating: 4.5,
      reviewCount: 22,
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-204',
      name: 'Mocassins souples en cuir d\'agneau cousu main',
      description: 'Chaussures citadines ultra confortables avec picots antidérapants et semelle intérieure à mémoire de forme.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p204-1/600/600',
      ],
      price: 110.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Chaussures et accessoires',
      rating: 4.3,
      reviewCount: 14,
      variants: ['41', '42', '43'],
    ),
    ProductUiModel(
      id: 'prod-205',
      name: 'Ceinture reversible en cuir pleine fleur avec boucle argentée',
      description: 'Double face noir/marron pour s\'adapter à toutes les tenues. Cuir traité façon tannage végétal.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p205-1/600/600',
      ],
      price: 49.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Chaussures et accessoires',
      rating: 4.6,
      reviewCount: 39,
      variants: ['90 cm', '100 cm', '110 cm'],
    ),

    // --- 3. Beauté et soins (5 produits) ---
    ProductUiModel(
      id: 'prod-301',
      name: 'Sérum visage hydratant à l\'acide hyaluronique pur',
      description: 'Formule concentrée repulpante aux extraits botaniques bio pour un teint lumineux dès la première semaine.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p301-1/600/600',
        'https://picsum.photos/seed/Dokan-p301-2/600/600',
      ],
      price: 45.000,
      oldPrice: 58.000,
      discountLabel: '-22%',
      availability: ProductAvailability.inStock,
      categoryName: 'Beauté et soins',
      rating: 4.8,
      reviewCount: 110,
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-302',
      name: 'Huile précieuse d\'argan vierge bio pressée à froid (100 ml)',
      description: 'Soin nourrissant multi-usages pour le visage, le corps et les pointes de cheveux abîmées.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p302-1/600/600',
      ],
      price: 36.500,
      availability: ProductAvailability.inStock,
      categoryName: 'Beauté et soins',
      rating: 4.9,
      reviewCount: 95,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-303',
      name: 'Crème régénérante de nuit aux actifs anti-âge naturels',
      description: 'Nutrition intense et stimulation du collagène pendant le sommeil pour une peau reposée au réveil.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p303-1/600/600',
      ],
      price: 68.000,
      oldPrice: 85.000,
      discountLabel: '-20%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Beauté et soins',
      rating: 4.4,
      reviewCount: 19,
    ),
    ProductUiModel(
      id: 'prod-304',
      name: 'Coffret rituel parfum d\'ambre et de jasmin oriental',
      description: 'Eau de parfum 50ml accompagnée de sa brume corps et d\'un baume soyeux parfumé.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p304-1/600/600',
        'https://picsum.photos/seed/Dokan-p304-2/600/600',
      ],
      price: 115.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Beauté et soins',
      rating: 4.7,
      reviewCount: 48,
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-305',
      name: 'Masque d\'argile blanche purifiant et apaisant',
      description: 'Désincruste les pores sans assécher l\'épiderme. Convient même aux peaux très sensibles.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p305-1/600/600',
      ],
      price: 24.900,
      availability: ProductAvailability.inStock,
      categoryName: 'Beauté et soins',
      rating: 4.5,
      reviewCount: 26,
    ),

    // --- 4. Électronique et technologie (5 produits) ---
    ProductUiModel(
      id: 'prod-401',
      name: 'Écouteurs sans fil True Wireless avec réduction de bruit active',
      description: 'Son haute fidélité avec transducteurs 11 mm, autonomie 30h avec boîtier et charge rapide USB-C.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p401-1/600/600',
        'https://picsum.photos/seed/Dokan-p401-2/600/600',
        'https://picsum.photos/seed/Dokan-p401-3/600/600',
      ],
      price: 189.000,
      oldPrice: 249.000,
      discountLabel: '-24%',
      availability: ProductAvailability.inStock,
      categoryName: 'Électronique et technologie',
      rating: 4.9,
      reviewCount: 140,
      variants: ['Noir mat', 'Blanc glacier'],
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-402',
      name: 'Enceinte Bluetooth portable waterproof IPX7 son 360°',
      description: 'Basses profondes et clarté acoustique pour toutes vos soirées extérieures avec 14 heures de batterie.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p402-1/600/600',
        'https://picsum.photos/seed/Dokan-p402-2/600/600',
      ],
      price: 129.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Électronique et technologie',
      rating: 4.7,
      reviewCount: 82,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-403',
      name: 'Montre connectée sport & santé avec suivi cardiaque SpO2',
      description: 'Écran AMOLED 1.43", plus de 80 modes sportifs et réception des notifications en temps réel.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p403-1/600/600',
      ],
      price: 199.000,
      oldPrice: 260.000,
      discountLabel: '-23%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Électronique et technologie',
      rating: 4.6,
      reviewCount: 51,
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-404',
      name: 'Batterie externe 20 000 mAh Power Delivery 65W ultra rapide',
      description: 'Capable de recharger simultanément un ordinateur portable et deux téléphones grâce à 3 ports de sortie.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p404-1/600/600',
      ],
      price: 95.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Électronique et technologie',
      rating: 4.8,
      reviewCount: 67,
    ),
    ProductUiModel(
      id: 'prod-405',
      name: 'Support de bureau réglable en aluminium anodisé pour PC portable',
      description: 'Améliore la posture ergonomique et favorise le refroidissement avec patins silicone anti-dérapants.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p405-1/600/600',
      ],
      price: 52.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Électronique et technologie',
      rating: 4.5,
      reviewCount: 34,
    ),

    // --- 5. Maison et décoration (5 produits) ---
    ProductUiModel(
      id: 'prod-501',
      name: 'Lampe de table design scandinave abat-jour tissu et pied céramique',
      description: 'Éclairage d\'ambiance tamisé parfait pour le salon ou le chevet avec interrupteur variateur discret.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p501-1/600/600',
        'https://picsum.photos/seed/Dokan-p501-2/600/600',
      ],
      price: 85.000,
      oldPrice: 110.000,
      discountLabel: '-23%',
      availability: ProductAvailability.inStock,
      categoryName: 'Maison et décoration',
      rating: 4.7,
      reviewCount: 36,
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-502',
      name: 'Tapis berbère géométrique en laine douce tissé à la main',
      description: 'Dimensions 160 x 230 cm. Motif losanges traditionnel apportant chaleur et authenticité à votre intérieur.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p502-1/600/600',
        'https://picsum.photos/seed/Dokan-p502-2/600/600',
      ],
      price: 280.000,
      availability: ProductAvailability.limitedStock,
      categoryName: 'Maison et décoration',
      rating: 4.9,
      reviewCount: 44,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-503',
      name: 'Plaid gaufré en pur coton naturel bio certifié OEKO-TEX',
      description: 'Légèreté et moelleux pour s\'enrouler sur le canapé lors des soirées fraîches. Dimensions 150x200 cm.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p503-1/600/600',
      ],
      price: 49.900,
      availability: ProductAvailability.inStock,
      categoryName: 'Maison et décoration',
      rating: 4.6,
      reviewCount: 28,
      variants: ['Terracotta', 'Vert sauge', 'Écru'],
    ),
    ProductUiModel(
      id: 'prod-504',
      name: 'Diffuseur d\'huiles essentielles ultrasonique en céramique mate',
      description: 'Diffusion silencieuse avec lumière d\'ambiance LED programmable et arrêt automatique de sécurité.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p504-1/600/600',
      ],
      price: 65.000,
      oldPrice: 80.000,
      discountLabel: '-19%',
      availability: ProductAvailability.inStock,
      categoryName: 'Maison et décoration',
      rating: 4.4,
      reviewCount: 20,
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-505',
      name: 'Set de 3 miroirs muraux ronds cerclage laiton doré brossé',
      description: 'Comprend 3 tailles assorties (diamètres 20, 25 et 30 cm) pour créer une composition murale lumineuse.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p505-1/600/600',
      ],
      price: 92.000,
      availability: ProductAvailability.outOfStock,
      categoryName: 'Maison et décoration',
      rating: 4.8,
      reviewCount: 38,
    ),

    // --- 6. Sport et loisirs (5 produits) ---
    ProductUiModel(
      id: 'prod-601',
      name: 'Tapis de yoga antidérapant haute densité en caoutchouc naturel',
      description: 'Épaisseur 6 mm pour une absorption idéale des articulations lors des postures exigeantes avec sangle de portage.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p601-1/600/600',
        'https://picsum.photos/seed/Dokan-p601-2/600/600',
      ],
      price: 69.000,
      oldPrice: 89.000,
      discountLabel: '-22%',
      availability: ProductAvailability.inStock,
      categoryName: 'Sport et loisirs',
      rating: 4.8,
      reviewCount: 52,
      variants: ['Bleu canard', 'Prune', 'Gris'],
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-602',
      name: 'Gourde isotherme inox 1 Litre maintien au froid 24h sans BPA',
      description: 'Double paroi isolée sous vide avec bouchon sport antifuite et anse de transport intégrée.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p602-1/600/600',
      ],
      price: 34.500,
      availability: ProductAvailability.inStock,
      categoryName: 'Sport et loisirs',
      rating: 4.9,
      reviewCount: 78,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-603',
      name: 'Kit de 5 bandes élastiques de résistance musculation en latex pur',
      description: '5 niveaux de tension de 5 à 30 kg avec poignées moussées, sangles chevilles et guide d\'exercices.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p603-1/600/600',
      ],
      price: 39.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Sport et loisirs',
      rating: 4.5,
      reviewCount: 41,
    ),
    ProductUiModel(
      id: 'prod-604',
      name: 'Sac de sport imperméable avec compartiment chaussures aéré',
      description: 'Volume 45L spacieux avec poche étanche pour linge humide et sangle bandoulière rembourrée.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p604-1/600/600',
      ],
      price: 58.000,
      oldPrice: 75.000,
      discountLabel: '-23%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Sport et loisirs',
      rating: 4.7,
      reviewCount: 33,
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-605',
      name: 'Corde à sauter de vitesse réglable sur roulements à billes',
      description: 'Câble acier gainé ultraléger conçu pour l\'entraînement cardio intensif et les double unders.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p605-1/600/600',
      ],
      price: 22.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Sport et loisirs',
      rating: 4.4,
      reviewCount: 19,
    ),

    // --- 7. Enfants et bébé (5 produits) ---
    ProductUiModel(
      id: 'prod-701',
      name: 'Veilleuse bébé rechargeable musicale avec projection d\'étoiles',
      description: 'Lumière douce apaisante sans scintillement avec 6 mélodies relaxantes et minuterie d\'extinction auto.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p701-1/600/600',
        'https://picsum.photos/seed/Dokan-p701-2/600/600',
      ],
      price: 49.000,
      oldPrice: 65.000,
      discountLabel: '-25%',
      availability: ProductAvailability.inStock,
      categoryName: 'Enfants et bébé',
      rating: 4.8,
      reviewCount: 47,
      isNew: true,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-702',
      name: 'Peluche doudou renard ultra douce en coton biologique lavable',
      description: 'Compagnon câlin adapté dès la naissance avec coutures renforcées et rembourrage hypoallergénique.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p702-1/600/600',
      ],
      price: 32.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Enfants et bébé',
      rating: 4.9,
      reviewCount: 63,
      isPopular: true,
    ),
    ProductUiModel(
      id: 'prod-703',
      name: 'Tour d\'empilement et formes en bois massif peintures à l\'eau',
      description: 'Jeu éducatif Montessori d\'éveil moteur et de reconnaissance des couleurs pour enfants dès 1 an.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p703-1/600/600',
      ],
      price: 38.000,
      availability: ProductAvailability.inStock,
      categoryName: 'Enfants et bébé',
      rating: 4.7,
      reviewCount: 30,
    ),
    ProductUiModel(
      id: 'prod-704',
      name: 'Gigoteuse d\'emmaillotage 4 saisons coton doux TOG 2.5',
      description: 'Fermeture zippée bidirectionnelle sécurisée pour changer facilement bébé la nuit sans le réveiller.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p704-1/600/600',
      ],
      price: 54.000,
      oldPrice: 70.000,
      discountLabel: '-23%',
      availability: ProductAvailability.limitedStock,
      categoryName: 'Enfants et bébé',
      rating: 4.6,
      reviewCount: 25,
      variants: ['0-6 mois', '6-18 mois', '18-36 mois'],
      isNew: true,
    ),
    ProductUiModel(
      id: 'prod-705',
      name: 'Set de vaisselle d\'apprentissage bébé en silicone ventousé',
      description: 'Assiette compartimentée ventousée anti-chute, bol, bavoir récupérateur et cuillère ergonomique souple.',
      imageUrls: [
        'https://picsum.photos/seed/Dokan-p705-1/600/600',
      ],
      price: 42.500,
      availability: ProductAvailability.inStock,
      categoryName: 'Enfants et bébé',
      rating: 4.7,
      reviewCount: 35,
    ),
  ];

  @override
  Future<List<CategoryUiModel>> getCategories() async {
    await Future.delayed(latency);
    // Calcul dynamique du nombre d'articles par catégorie
    return _baseCategories.map((cat) {
      final count = _mockProducts.where((p) => p.categoryName == cat.name).length;
      return cat.copyWith(productCount: count);
    }).toList();
  }

  @override
  Future<List<ProductUiModel>> getNewProducts() async {
    await Future.delayed(latency);
    return _mockProducts.where((p) => p.isNew).toList();
  }

  @override
  Future<List<ProductUiModel>> getDiscountedProducts() async {
    await Future.delayed(latency);
    return _mockProducts.where((p) => p.hasDiscount).toList();
  }

  @override
  Future<List<ProductUiModel>> getPopularProducts() async {
    await Future.delayed(latency);
    return _mockProducts.where((p) => p.isPopular).toList();
  }

  @override
  Future<List<ProductUiModel>> getProductsByCategory(
    String categoryName, {
    int page = 1,
    int limit = 10,
  }) async {
    await Future.delayed(latency);
    final filtered = _mockProducts
        .where((p) => p.categoryName.toLowerCase() == categoryName.toLowerCase())
        .toList();

    final startIndex = (page - 1) * limit;
    if (startIndex >= filtered.length) {
      return [];
    }
    return filtered.skip(startIndex).take(limit).toList();
  }

  @override
  Future<List<ProductUiModel>> searchProducts({
    required String query,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    await Future.delayed(latency);

    // ========================================================================
    // MOTS-CLÉS DE DÉMONSTRATION POUR TESTER LES ÉTATS D'INTERFACE
    // - #error : simule une rupture de connexion pour afficher ErrorState.
    // - #empty : simule une recherche infructueuse pour afficher EmptyState.
    // ========================================================================
    if (query.trim() == '#error') {
      throw Exception('Erreur réseau simulée');
    }
    if (query.trim() == '#empty') {
      return [];
    }

    var list = List<ProductUiModel>.from(_mockProducts);

    // Filtrage par texte saisi (nom, description ou catégorie)
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q);
      }).toList();
    }

    // Filtrage par nom de catégorie
    if (categoryName != null && categoryName.isNotEmpty) {
      list = list
          .where((p) => p.categoryName.toLowerCase() == categoryName.toLowerCase())
          .toList();
    }

    // Filtrage par fourchette de prix min/max
    if (minPrice != null) {
      list = list.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      list = list.where((p) => p.price <= maxPrice).toList();
    }

    // Filtrage par disponibilité immédiate en stock
    if (inStockOnly == true) {
      list = list.where((p) => p.isInStock).toList();
    }

    // Tri des résultats
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          list.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          list.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'newest':
          list.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
          break;
        case 'popularity':
          list.sort((a, b) => (b.isPopular ? 1 : 0).compareTo(a.isPopular ? 1 : 0));
          break;
        default:
          // Pertinence par défaut
          break;
      }
    }

    // Pagination par tranches (page et limit)
    final startIndex = (page - 1) * limit;
    if (startIndex >= list.length) {
      return [];
    }
    return list.skip(startIndex).take(limit).toList();
  }

  @override
  Future<ProductUiModel?> getProductById(String id) async {
    await Future.delayed(latency);
    try {
      return _mockProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider d'injection du service de catalogue.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return MockCatalogRepository();
});
