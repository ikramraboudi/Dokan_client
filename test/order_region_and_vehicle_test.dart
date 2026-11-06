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
  });
}
