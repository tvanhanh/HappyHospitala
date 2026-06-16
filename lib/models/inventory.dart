/// Flutter data model for a drug Inventory record.
///
/// Maps to the [Inventories] MongoDB collection defined in the ERD.
///
/// ERD Relationships:
/// - Inventories --[checks_stock]--> Prescriptions (via [pharmacy])
/// - Inventories --[managed_by]--> Pharmacy role
/// - Inventories --[triggers]--> low-stock Alert via [pharmacy]
///
/// The [pharmacy] service uses [getEarliestExpiryBatch] to ensure
/// FEFO (First-Expiry-First-Out) dispensing for patient safety.
library;

/// Represents a single batch of drug stock with its own expiry date.
///
/// Maps to the embedded `batches: Array[Object]` field in the Inventories
/// collection. Using FEFO (First-Expiry-First-Out) ordering to minimize waste.
class DrugBatch {
  /// Unique batch identifier / lot number from the supplier.
  final String batchNumber;

  /// Number of units remaining in this specific batch.
  final int quantity;

  /// Expiry date of this batch. Used for FEFO dispensing logic.
  final DateTime expiryDate;

  /// Purchase price per unit for this batch (for cost calculation).
  final double? costPerUnit;

  /// Creates a [DrugBatch].
  const DrugBatch({
    required this.batchNumber,
    required this.quantity,
    required this.expiryDate,
    this.costPerUnit,
  });

  /// Deserializes a [DrugBatch] from a JSON map.
  factory DrugBatch.fromJson(Map<String, dynamic> json) {
    return DrugBatch(
      batchNumber: json['batchNumber']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble(),
    );
  }

  /// Serializes this batch to a JSON map.
  Map<String, dynamic> toJson() => {
        'batchNumber': batchNumber,
        'quantity': quantity,
        'expiryDate': expiryDate.toIso8601String(),
        if (costPerUnit != null) 'costPerUnit': costPerUnit,
      };

  /// Returns true if this batch expires within the next [days] days.
  bool isExpiringSoon({int days = 30}) {
    return expiryDate.isBefore(DateTime.now().add(Duration(days: days)));
  }

  /// Returns true if this batch has already expired.
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}

/// The canonical Flutter model for an Inventory (drug stock) document.
///
/// Each [Inventory] record represents one drug/medication in the pharmacy
/// system, with multiple [DrugBatch] entries tracking different lot numbers.
///
/// The [pharmacy] class from the Class Diagram uses:
/// - [totalStock] to check stock before dispensing
/// - [earliestExpiryBatch] for FEFO dispensing order
/// - [isLowStock] to trigger [triggerLowStockAlert]
class Inventory {
  // ── Identity ───────────────────────────────────────────────────────────────

  /// MongoDB ObjectId string. Maps to `_id`.
  final String id;

  // ── Drug Information ───────────────────────────────────────────────────────

  /// Full drug name (e.g., "Paracetamol 500mg"). Maps to `drugName: String`.
  final String drugName;

  /// Unit of measurement (e.g., "viên", "chai", "ống", "ml").
  /// Maps to `unit: String`.
  final String unit;

  /// Total aggregate stock across all batches.
  /// Maps to `totalStock: Int` in the ERD.
  final int totalStock;

  // ── Stock Batches ──────────────────────────────────────────────────────────

  /// Individual stock batches with separate expiry dates and quantities.
  /// Maps to `batches: Array[Object]` (embedded) in the ERD.
  final List<DrugBatch> batches;

  // ── Pricing ────────────────────────────────────────────────────────────────

  /// Retail selling price per unit in VND.
  final double? sellingPrice;

  /// Minimum stock level that triggers a low-stock alert.
  final int? minimumStock;

  /// Drug category / ATC code for classification.
  final String? category;

  /// Creates an [Inventory].
  const Inventory({
    required this.id,
    required this.drugName,
    required this.unit,
    required this.totalStock,
    this.batches = const [],
    this.sellingPrice,
    this.minimumStock,
    this.category,
  });

  /// Deserializes an [Inventory] from a backend API JSON payload.
  factory Inventory.fromJson(Map<String, dynamic> json) {
    final rawBatches = json['batches'];
    final List<DrugBatch> batchList = rawBatches is List
        ? rawBatches
            .map((e) => DrugBatch.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return Inventory(
      id: json['_id']?.toString() ?? '',
      drugName: json['drugName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      totalStock: json['totalStock'] is int ? json['totalStock'] : 0,
      batches: batchList,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      minimumStock: json['minimumStock'] is int ? json['minimumStock'] : null,
      category: json['category']?.toString(),
    );
  }

  /// Serializes this [Inventory] to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'drugName': drugName,
        'unit': unit,
        'totalStock': totalStock,
        'batches': batches.map((b) => b.toJson()).toList(),
        if (sellingPrice != null) 'sellingPrice': sellingPrice,
        if (minimumStock != null) 'minimumStock': minimumStock,
        if (category != null) 'category': category,
      };

  // ══════════════════════════════════════════════════════════════════════════
  // BUSINESS LOGIC HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the batch that expires soonest (FEFO order).
  ///
  /// Implements the `getEarliestExpiryBatch(): Object` method defined in
  /// the [Inventory] class in the Class Diagram. Used by [pharmacy]
  /// to select which batch to dispense from first.
  DrugBatch? get earliestExpiryBatch {
    if (batches.isEmpty) return null;
    final validBatches =
        batches.where((b) => !b.isExpired && b.quantity > 0).toList();
    if (validBatches.isEmpty) return null;
    validBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return validBatches.first;
  }

  /// Returns true if current stock is at or below the [minimumStock] threshold.
  ///
  /// Used by [pharmacy.triggerLowStockAlert] per the Class Diagram.
  bool get isLowStock => minimumStock != null && totalStock <= minimumStock!;

  /// Returns all batches expiring within the next 30 days.
  List<DrugBatch> get expiringBatches =>
      batches.where((b) => b.isExpiringSoon()).toList();

  /// Creates a copy with optionally updated fields.
  Inventory copyWith({
    String? id,
    String? drugName,
    String? unit,
    int? totalStock,
    List<DrugBatch>? batches,
    double? sellingPrice,
    int? minimumStock,
    String? category,
  }) {
    return Inventory(
      id: id ?? this.id,
      drugName: drugName ?? this.drugName,
      unit: unit ?? this.unit,
      totalStock: totalStock ?? this.totalStock,
      batches: batches ?? this.batches,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minimumStock: minimumStock ?? this.minimumStock,
      category: category ?? this.category,
    );
  }
}
