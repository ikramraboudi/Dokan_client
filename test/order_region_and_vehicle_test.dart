import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/core/utils/tunisia_regions.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/order_status.dart';

void main() {
  group('TunisiaRegions - Découpage logistique officiel', () {
    test('1. Région NORD : Nabeul, Tunis, Bizerte, Béja', () {
      expect(TunisiaRegions.getRegionId('Nabeul'), 'nord');
      expect(TunisiaRegions.getRegionId('Tunis'), 'nord');
      expect(TunisiaRegions.getRegionId('Bizerte'), 'nord');
      expect(TunisiaRegions.getRegionId('Béja'), 'nord');
      expect(TunisiaRegions.getRegionId('Hammamet'), 'nord');
    });

    test('2. Région CENTRE : Sousse, Monastir, Mahdia, Sfax, Kairouan', () {
      expect(TunisiaRegions.getRegionId('Sousse'), 'centre');
      expect(TunisiaRegions.getRegionId('Monastir'), 'centre');
      expect(TunisiaRegions.getRegionId('Sfax'), 'centre');
      expect(TunisiaRegions.getRegionId('Kairouan'), 'centre');
    });

    test('3. Région SUD : Gabès, Médenine, Tataouine, Djerba, Tozeur', () {
      expect(TunisiaRegions.getRegionId('Gabès'), 'sud');
      expect(TunisiaRegions.getRegionId('Gabes'), 'sud');
      expect(TunisiaRegions.getRegionId('Médenine'), 'sud');
      expect(TunisiaRegions.getRegionId('Medenine'), 'sud');
      expect(TunisiaRegions.getRegionId('Tataouine'), 'sud');
      expect(TunisiaRegions.getRegionId('Djerba'), 'sud');
      expect(TunisiaRegions.getRegionId('Tozeur'), 'sud');
    });

    test('4. Fallback robuste sur "nord" si ville inconnue ou vide', () {
      expect(TunisiaRegions.getRegionId(''), 'nord');
      expect(TunisiaRegions.getRegionId(null), 'nord');
      expect(TunisiaRegions.getRegionId('Inconnu'), 'nord');
    });

    test('5. Détection directe des identifiants de région (sud, centre, nord)', () {
      expect(TunisiaRegions.getRegionId('sud'), 'sud');
      expect(TunisiaRegions.getRegionId('SUD'), 'sud');
      expect(TunisiaRegions.getRegionId('Région Sud'), 'sud');
      expect(TunisiaRegions.getRegionId('zone sud'), 'sud');

      expect(TunisiaRegions.getRegionId('centre'), 'centre');
      expect(TunisiaRegions.getRegionId('CENTRE'), 'centre');
      expect(TunisiaRegions.getRegionId('Région Centre'), 'centre');

      expect(TunisiaRegions.getRegionId('nord'), 'nord');
      expect(TunisiaRegions.getRegionId('NORD'), 'nord');
      expect(TunisiaRegions.getRegionId('Grand Tunis'), 'nord');
    });

    test('6. Résolution intelligente resolveRegionAndCity (cas réel utilisateur : Sfax + SUD)', () {
      // Cas exact de la capture : zone = "SUD", addressLine contient "Sfax", city = "Tunis"
      final res1 = TunisiaRegions.resolveRegionAndCity(
        city: 'Tunis',
        zone: 'SUD',
        addressLine: 'Rue Habib Bourguiba, Sfax, Tunisie',
      );
      expect(res1.regionId, 'sud');
      expect(res1.city, 'Sfax');

      // Cas où zone = "SUD" sans autre ville mentionnée
      final res2 = TunisiaRegions.resolveRegionAndCity(
        city: 'Tunis',
        zone: 'SUD',
        addressLine: 'Avenue Habib Bourguiba',
      );
      expect(res2.regionId, 'sud');
      expect(res2.city, 'Tunis');

      // Cas standard Sfax sans région explicite
      final res3 = TunisiaRegions.resolveRegionAndCity(
        city: 'Sfax',
        zone: 'Sakiet Ezzit',
        addressLine: 'Route Teniour',
      );
      expect(res3.regionId, 'centre');
      expect(res3.city, 'Sfax');

      // Cas Gabès dans le Sud
      final res4 = TunisiaRegions.resolveRegionAndCity(
        city: 'Gabès',
        zone: 'Chenini',
        addressLine: '12 Rue de la plage',
      );
      expect(res4.regionId, 'sud');
      expect(res4.city, 'Gabès');
    });
  });

  group('DriverInfo & OrderUiModel - Véhicules officiels et matricule', () {
    test('1. Détection Camion officiel (🚚)', () {
      final driver = DriverInfo(
        name: 'Mourad Trabelsi',
        phone: '+216 20 123 456',
        assignedVehiclePlate: '215 TU 8901',
        vehicleType: 'camion',
      );

      expect(driver.isTruck, isTrue);
      expect(driver.vehicleLabel, 'Camion officiel');
      expect(driver.vehicleEmoji, '🚚');
      expect(driver.vehicleIcon, Icons.local_shipping_rounded);
      expect(driver.assignedVehiclePlate, '215 TU 8901');
    });

    test('2. Détection Voiture officielle (🚗)', () {
      final driver = DriverInfo(
        name: 'Karim Ben Salem',
        phone: '+216 98 765 432',
        assignedVehiclePlate: '180 TU 3456',
        vehicleType: 'voiture',
      );

      expect(driver.isTruck, isFalse);
      expect(driver.vehicleLabel, 'Voiture officielle');
      expect(driver.vehicleEmoji, '🚗');
      expect(driver.vehicleIcon, Icons.directions_car_rounded);
    });

    test('3. Sérialisation toFirestore inclut obligatoirement regionId, city, deliveryAddress et driverVehiclePlate', () {
      const address = OrderDeliveryAddress(
        recipientName: 'Ahmed Salah',
        phone: '+216 98 123 456',
        addressLine: 'Avenue Habib Bourguiba',
        city: 'Nabeul',
      );

      final now = Timestamp.now();
      final order = OrderUiModel(
        id: 'ord_test_123',
        displayNumber: 'DK-261106-ABCD',
        userId: 'client_uid_456',
        customerName: 'Ahmed Salah',
        customerPhone: '+216 98 123 456',
        status: OrderStatus.pending,
        statusHistory: const [],
        items: const [],
        itemCount: 2,
        subtotal: 50.0,
        discount: 0.0,
        deliveryFee: 7.0,
        total: 57.0,
        deliveryAddress: address,
        city: 'Nabeul',
        regionId: 'nord',
        driver: const DriverInfo(
          name: 'Sami',
          phone: '+216 55 111 222',
          assignedVehiclePlate: '230 TU 1122',
          vehicleType: 'camion',
        ),
        createdAt: now,
        updatedAt: now,
      );

      final map = order.toFirestore();

      expect(map['city'], 'Nabeul');
      expect(map['regionId'], 'nord');
      expect(map['deliveryAddress'], 'Avenue Habib Bourguiba, Nabeul');
      expect(map['driverVehiclePlate'], '230 TU 1122');
      expect(map['driverVehicleType'], 'camion');
      expect(order.vehicleEmoji, '🚚');
      expect(order.vehicleLabel, 'Camion officiel');
      expect(order.hasDriverOrVehicle, isTrue);
    });

    test('4. OrderUiModel.fromFirestore réconcilie une commande existante erronée (regionId="nord" mais zone="SUD")', () {
      final fakeData = {
        'displayNumber': 'DK-261107-1234',
        'userId': 'user_123',
        'customerName': 'maram',
        'customerPhone': '78945612',
        'city': 'Tunis',
        'regionId': 'nord',
        'status': 'pending',
        'deliveryAddress': {
          'address': 'Rue Habib Bourguiba, Sfax, Tunisie',
          'city': 'Tunis',
          'regionId': 'nord',
        },
        'deliveryAddressText': 'Rue Habib Bourguiba, Sfax, Tunisie, SUD, Tunis',
        'deliveryAddressDetails': {
          'recipientName': 'maram',
          'phone': '78945612',
          'addressLine': 'Rue Habib Bourguiba, Sfax, Tunisie',
          'zone': 'SUD',
          'city': 'Tunis',
        },
        'items': <Map<String, dynamic>>[],
        'subtotal': 100.0,
        'discount': 0.0,
        'deliveryFee': 0.0,
        'total': 100.0,
      };

      final order = OrderUiModel.fromMap('order_id_sfax_sud', fakeData);
      expect(order.regionId, 'sud');
      expect(order.city, 'Sfax');
      expect(order.deliveryAddress.summary, contains('SUD'));
    });
  });
}
