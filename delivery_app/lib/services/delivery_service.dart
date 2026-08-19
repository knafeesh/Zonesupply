import 'api_service.dart';
import 'package:flutter/material.dart';

class DeliveryService extends ChangeNotifier {
  static bool useMockData = false; // false = real backend; toggle ON in login screen for dev testing

  List<MockBatch> _mockBatches = [];
  final Set<String> _claimedBatchIds = {};
  bool _loading = false;
  bool _loadingAvailable = false;
  bool _loadingMyJobs = false;

  List<Map<String, dynamic>> _availableJobs = [];
  List<Map<String, dynamic>> _myJobs = [];
  final Map<String, Map<String, dynamic>> _batchDetailsMap = {};

  bool get loading => _loading;
  bool get loadingAvailable => _loadingAvailable;
  bool get loadingMyJobs => _loadingMyJobs;

  List<Map<String, dynamic>> get availableJobs => _availableJobs;
  List<Map<String, dynamic>> get myJobs => _myJobs;

  DeliveryService() {
    _initMockData();
  }

  void _initMockData() {
    _mockBatches = [
      MockBatch(
        id: 'b-9921a',
        zoneName: 'Zone-South-BLR',
        wholesalerName: 'Venkateshwara Traders',
        wholesalerAddress: '14th Main Rd, Sector 3, HSR Layout, Bengaluru',
        wholesalerPhone: '+91 98845 12093',
        wholesalerLat: 12.9105,
        wholesalerLng: 77.6450,
        orderCount: 2,
        totalValue: 5950.00,
        status: 'created', // created, picked_up, completed
        stops: [
          MockStop(
            orderId: 'o-4011',
            sequence: 1,
            retailerName: 'Srinivasa Provision Store',
            address: '4th Cross, HSR Sector 6, Bengaluru',
            phone: '+91 98840 88201',
            retailerLat: 12.9140,
            retailerLng: 77.6410,
            orderValue: 3500.00,
            deliveryStatus: 'pending',
          ),
          MockStop(
            orderId: 'o-4012',
            sequence: 2,
            retailerName: 'Loyal Kirana Shop',
            address: '17th Cross, HSR Sector 2, Bengaluru',
            phone: '+91 98721 00293',
            retailerLat: 12.9080,
            retailerLng: 77.6490,
            orderValue: 2450.00,
            deliveryStatus: 'pending',
          ),
        ],
      ),
      MockBatch(
        id: 'b-9922b',
        zoneName: 'Zone-East-BLR',
        wholesalerName: 'Metro Super Wholesalers',
        wholesalerAddress: 'Koramangala 8th Block, Bengaluru',
        wholesalerPhone: '+91 91234 56780',
        wholesalerLat: 12.9350,
        wholesalerLng: 77.6250,
        orderCount: 1,
        totalValue: 6800.00,
        status: 'created',
        stops: [
          MockStop(
            orderId: 'o-4013',
            sequence: 1,
            retailerName: 'Ganesh Supermarket',
            address: 'Koramangala 4th Block, Bengaluru',
            phone: '+91 99008 77665',
            retailerLat: 12.9310,
            retailerLng: 77.6220,
            orderValue: 6800.00,
            deliveryStatus: 'pending',
          ),
        ],
      ),
    ];
  }

  Map<String, dynamic> _normalizeBatch(Map<String, dynamic> b) {
    final wholesalerObj = b['wholesaler'] as Map<String, dynamic>? ?? {};
    final zoneObj = b['zone'] as Map<String, dynamic>? ?? {};

    List normalizedOrders = [];
    if (b['orders'] != null) {
      final ordersList = b['orders'] as List;
      normalizedOrders = ordersList.map((o) {
        return {
          'id': o['id']?.toString() ?? '',
          'retailerName': o['retailerName'] ?? 'Retailer',
          'address': o['address'] ?? '-',
          'phone': o['phone'] ?? '+91 99999 99999',
          'latitude': double.tryParse(o['latitude']?.toString() ?? '0') ?? 0.0,
          'longitude': double.tryParse(o['longitude']?.toString() ?? '0') ?? 0.0,
          'totalAmount': double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0.0,
          'deliveryStatus': o['deliveryStatus'] ?? 'pending',
          'deliverySequence': o['deliverySequence'] ?? 1,
          'issueReason': o['issueReason'],
          'signatureData': o['signatureData'],
          'photoData': o['photoData'],
        };
      }).toList();
    }

    return {
      'id': b['id'],
      'zoneId': b['zoneId'] ?? zoneObj['name'] ?? '',
      'deliveryZone': zoneObj['name'] ?? b['zoneId'] ?? '-',
      'wholesalerId': b['wholesalerId'],
      'wholesaler': {
        'businessName': b['wholesaler']?['businessName'] ?? wholesalerObj['businessName'] ?? 'Wholesaler',
        'address': b['wholesaler']?['address'] ?? wholesalerObj['address'] ?? '-',
        'phone': b['wholesaler']?['user']?['phone'] ?? wholesalerObj['user']?['phone'] ?? '+91 99999 99999',
        'latitude': double.tryParse(b['wholesaler']?['latitude']?.toString() ?? wholesalerObj['latitude']?.toString() ?? '0') ?? 0.0,
        'longitude': double.tryParse(b['wholesaler']?['longitude']?.toString() ?? wholesalerObj['longitude']?.toString() ?? '0') ?? 0.0,
      },
      'orderCount': b['orderCount'] ?? normalizedOrders.length,
      'totalValue': double.tryParse(b['totalValue']?.toString() ?? '0') ?? 0.0,
      'status': b['status']?.toString() ?? 'created',
      'orders': normalizedOrders,
    };
  }

  Map<String, dynamic> _batchToMap(MockBatch b) {
    return {
      'id': b.id,
      'zoneId': b.zoneName,
      'deliveryZone': b.zoneName,
      'wholesalerId': b.wholesalerName,
      'wholesaler': {
        'businessName': b.wholesalerName,
        'address': b.wholesalerAddress,
        'phone': b.wholesalerPhone,
        'latitude': b.wholesalerLat,
        'longitude': b.wholesalerLng,
      },
      'orderCount': b.orderCount,
      'totalValue': b.totalValue,
      'status': b.status,
      'orders': b.stops.map((s) => {
        'id': s.orderId,
        'retailerName': s.retailerName,
        'address': s.address,
        'phone': s.phone,
        'totalAmount': s.orderValue,
        'deliveryStatus': s.deliveryStatus,
        'deliverySequence': s.sequence,
        'latitude': s.retailerLat,
        'longitude': s.retailerLng,
        'issueReason': s.issueReason,
        'signatureData': s.signatureData,
        'photoData': s.photoData,
      }).toList(),
    };
  }

  Future<void> fetchAvailableJobs() async {
    _loadingAvailable = true;
    notifyListeners();
    try {
      if (useMockData) {
        _availableJobs = _mockBatches
            .where((b) => !_claimedBatchIds.contains(b.id))
            .map((b) => _batchToMap(b))
            .toList();
      } else {
        final List data = await ApiService.get('/delivery/jobs/available') as List? ?? [];
        _availableJobs = data.map((b) => _normalizeBatch(b)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching available jobs: $e");
    } finally {
      _loadingAvailable = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyJobs() async {
    _loadingMyJobs = true;
    notifyListeners();
    try {
      if (useMockData) {
        _myJobs = _mockBatches
            .where((b) => _claimedBatchIds.contains(b.id))
            .map((b) => _batchToMap(b))
            .toList();
      } else {
        final List data = await ApiService.get('/delivery/jobs/mine') as List? ?? [];
        _myJobs = data.map((b) => _normalizeBatch(b)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching my jobs: $e");
    } finally {
      _loadingMyJobs = false;
      notifyListeners();
    }
  }

  Future<void> fetchBatchDetails(String batchId) async {
    if (useMockData) {
      return; // Handled synchronously by getBatchDetails for mock data
    }
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/consolidation/$batchId');
      _batchDetailsMap[batchId] = _normalizeBatch(res);
    } catch (e) {
      debugPrint("Error fetching batch details for $batchId: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getBatchDetails(String batchId) {
    if (useMockData) {
      final b = _mockBatches.firstWhere((x) => x.id == batchId);
      return _batchToMap(b);
    }
    return _batchDetailsMap[batchId] ?? {};
  }

  Future<void> claimJob(String batchId) async {
    _loading = true;
    notifyListeners();
    try {
      if (useMockData) {
        _claimedBatchIds.add(batchId);
      } else {
        await ApiService.patch('/delivery/jobs/$batchId/claim', {});
      }
      await fetchAvailableJobs();
      await fetchMyJobs();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markPickedUp(String batchId) async {
    _loading = true;
    notifyListeners();
    try {
      if (useMockData) {
        final batch = _mockBatches.firstWhere((b) => b.id == batchId);
        batch.status = 'picked_up';
      } else {
        await ApiService.patch('/delivery/batches/$batchId/pickup', {});
        await fetchBatchDetails(batchId);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPOD({
    required String batchId,
    required String orderId,
    required double lat,
    required double lng,
    required String status, // 'delivered' | 'failed'
    String? issueReason,
    String? signatureData,
    String? photoData,
    String? otp,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      if (useMockData) {
        final batch = _mockBatches.firstWhere((b) => b.id == batchId);
        final stop = batch.stops.firstWhere((s) => s.orderId == orderId);
        stop.deliveryStatus = status;
        stop.issueReason = issueReason;
        stop.signatureData = signatureData;
        stop.photoData = photoData;

        // Check if all drops done
        final allDone = batch.stops.every((s) => s.deliveryStatus != 'pending');
        if (allDone) {
          batch.status = 'completed';
        }
      } else {
        await ApiService.post('/delivery/batches/$batchId/orders/$orderId/delivered', {
          'lat': lat,
          'lng': lng,
          'status': status,
          'otp':? otp,
        });
        await fetchBatchDetails(batchId);
      }
    } catch (_) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation(double lat, double lng, {String? batchId}) async {
    if (useMockData) {
      debugPrint("Simulated GPS coordinate update: $lat, $lng for Batch $batchId");
      return;
    }
    await ApiService.post('/delivery/location', {
      'lat': lat,
      'lng': lng,
      'batchId': batchId,
    });
  }

  /// Called once when the GPS route simulator starts — marks the batch IN_TRANSIT
  /// and all its orders → IN_TRANSIT ("Out for Delivery") on the backend.
  Future<void> markInTransit(String batchId) async {
    if (useMockData) {
      // In mock mode, update local batch status
      try {
        final batch = _mockBatches.firstWhere((b) => b.id == batchId);
        batch.status = 'in_transit';
      } catch (_) {}
      notifyListeners();
      return;
    }
    try {
      await ApiService.patch('/delivery/batches/$batchId/transit', {});
      await fetchBatchDetails(batchId);
    } catch (e) {
      debugPrint('markInTransit failed: $e');
    }
  }
}

class MockBatch {
  final String id;
  final String zoneName;
  final String wholesalerName;
  final String wholesalerAddress;
  final String wholesalerPhone;
  final double wholesalerLat;
  final double wholesalerLng;
  final int orderCount;
  final double totalValue;
  String status;
  final List<MockStop> stops;

  MockBatch({
    required this.id,
    required this.zoneName,
    required this.wholesalerName,
    required this.wholesalerAddress,
    required this.wholesalerPhone,
    required this.wholesalerLat,
    required this.wholesalerLng,
    required this.orderCount,
    required this.totalValue,
    required this.status,
    required this.stops,
  });
}

class MockStop {
  final String orderId;
  final int sequence;
  final String retailerName;
  final String address;
  final String phone;
  final double retailerLat;
  final double retailerLng;
  final double orderValue;
  String deliveryStatus;
  String? issueReason;
  String? signatureData;
  String? photoData;

  MockStop({
    required this.orderId,
    required this.sequence,
    required this.retailerName,
    required this.address,
    required this.phone,
    required this.retailerLat,
    required this.retailerLng,
    required this.orderValue,
    required this.deliveryStatus,
    this.issueReason,
    this.signatureData,
    this.photoData,
  });
}
